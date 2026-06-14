# Test strategy — which test(s) each artifact gets

Test **behavior at the layer that owns it, not every file**. Most tests are feature tests (they give the
most confidence the system works end-to-end); unit tests are reserved for code that owns business logic
testable in isolation. Thin or declarative artifacts (controllers, resources, events, plain DTOs) are
covered **indirectly** by the feature test of the flow they take part in — giving each its own test adds
maintenance cost without adding confidence.

The decision for any artifact:

- **Owns business logic that can be wrong independently of the HTTP flow?** → **unit test** it (mock
  injected collaborators; pass the current `User` in).
- **An HTTP entry point or wiring/glue?** → **feature test** it (drive it over HTTP).
- **A pure data carrier or declarative config?** → **no standalone test**; assert it inside the feature
  test of the code that uses it.

## Per-artifact matrix

| Artifact | Unit | Feature | What to assert (and where) | Skip when |
|----------|------|---------|----------------------------|-----------|
| Action / Interactor | **yes** (primary) | indirectly (via controller) | logic outcomes, DB state, side effects, edge cases — mocked collaborators | it trivially delegates to one already-tested call |
| Service | **yes** | only if it owns HTTP | return values + side effects, mocked deps | only ever invoked through already-tested Actions |
| Controller | no | **yes** (primary) | status, JSON shape, dispatched events, authorization (403/401) | — |
| FormRequest | custom Rule classes only | **yes** (1 pass + 1 fail) | 422 + the error keys; the happy path passes | exhaustive per-rule tests of stock rules (tests the framework) |
| API Resource | only if computed/conditional fields | via the endpoint | the JSON structure/shape in the controller feature test | plain field mapping → no standalone test |
| Event | no | no (dedicated) | that it was dispatched, faked in the caller's test | always — an event class is a data carrier |
| Listener | **yes** | optional | `handle()` side effects, with mail/notification faked | it only calls an already-tested service |
| Job | **yes** (`handle()`) | dispatch asserted in the caller (queue faked) | DB state / side effects of `handle()` | trivial job |
| Model | scopes / casts / domain methods | via feature | relationships, scopes, accessors, domain methods (e.g. `isExpired()`) | Eloquent internals (save/find); zero-logic accessors |
| Policy | useful | **yes** (preferred) | unauthorized → forbidden, authorized → allowed | one-liner policy (the feature test proves the wiring) |
| DTO / Data object | only if it has logic | no | transformation/casting logic, if any | a pure property bag → no test |
| Middleware | avoid (fragile) | **yes** | the guarded route returns forbidden/redirect when it should | a feature test of the guarded route already covers it |
| Console command | no | **yes** (`artisan(...)`) | exit code, output, resulting DB state | the underlying service is already unit-tested |
| Migration | no | implicit (`RefreshDatabase`) | nothing dedicated — the suite runs migrations | always, except an irreversible data transform on existing rows |

## The common feature: Action + Controller + Event + Resource

This is the canonical full-stack slice. Its **complete** suite is **two** files, not four:

- A **feature test** for the controller — asserts status + JSON structure (covers the **Resource**) and
  that the domain **Event** was dispatched (event faked) and authorization. The Resource and Event get
  **no** test of their own.
- A **unit test** for the **Action** — its business logic and edge cases, with mocked collaborators.

The controller itself gets no unit test (unit-testing glue duplicates the feature test and tests the
framework).

## Notes & honest disagreements

- **FormRequest** is genuinely contested: some unit-test the `rules()` array (fast, one test); others
  argue that misses `prepareForValidation()`/`withValidator()` bugs and prefer feature tests. Resolution:
  unit-test custom **Rule** objects (they own logic); feature-test validation **behavior** (at least one
  failing + the happy path); don't exhaustively HTTP-test stock rules.
- **Classicist vs mockist:** feature tests run the full stack and fake only at the boundary
  (events, queues, mail); unit tests mock injected collaborators to stay fast and pinpoint failures.
- **Thin-controller + Action architecture** pushes more logic into Actions, making the Action unit test
  the priority and the controller feature test mostly a wiring check.
- **Whatever the layer, assert observable behavior** (an endpoint returns X, a row is written, an event
  fired) — never "the code was written".
