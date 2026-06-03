# RESEARCH — Patterns (project-local pattern overrides)

How to research a specific artifact domain (e.g., "controllers", "Pinia stores", "Vue pages") and produce a project-local pattern override under `./.bench/patterns/`. Used by the `pattern` researcher agent.

A **pattern** in Bench is a markdown doc that tells an agent *how to write a specific kind of file* in this project. Bench core ships ~90 patterns covering generic Laravel + Vue + React conventions. A project-local pattern override sharpens one of those (or adds a new one) for *this* project's specific conventions.

Apply [METHODOLOGY-layered-scan.md](./METHODOLOGY-layered-scan.md). This pattern adds the artifact-specific lens.

---

## When you need a project-local pattern

Not every project needs custom patterns. Add one only when:

1. **The project diverges from Bench's default in a way that recurs.** e.g., every controller extends a project-specific base; every store uses a custom helper.
2. **There's a new artifact type Bench doesn't cover.** e.g., the project has "policies" with a non-standard structure, or a custom domain object like `Saga` or `Workflow`.
3. **The user explicitly asked for one.**

Don't write a pattern override just because you *could*. Each pattern is one more file the agent must read on every relevant invocation.

---

## Researching a single domain

You'll be given a domain to research — "controllers", "Pinia stores", "Vue components", "form requests", etc.

### Step 1 — Locate the artifact

```bash
# Examples:
find . -path '*/Http/Controllers/*.php' -not -path '*/vendor/*'
find . -path '*/src/stores/*.ts' -not -path '*/node_modules/*'
find . -name '*Controller.php' -not -path '*/vendor/*'
```

### Step 2 — Sample 3–5 representative files

Read them in full. Look for:

- **File structure**: imports order, class/function order, what's at the top.
- **Naming**: file name vs class/symbol name, suffixes (`Controller`, `Service`, `.spec.ts`).
- **Base classes / abstractions**: do they all extend something custom? Use a trait? Implement an interface?
- **Conventional helpers / facades / utilities** that recur.
- **Dependency injection style**: constructor-injected, `app()->make()`, container resolution, props vs composables.
- **Error handling**: try/catch placement, custom exception types, response shape.
- **Test pairing**: where's the test? Same folder? Mirrored under `tests/`?

### Step 3 — Validate the convention with grep

For each candidate convention, confirm it across the codebase:

```bash
grep -rl "extends BaseController" --include='*.php' .
grep -rl "defineStore(" --include='*.ts' src/
```

If 9/10 hit, it's a convention. If 5/10, it's a transition — ask the user which side to write toward (usually: the more recent one — check git log).

### Step 4 — Compare against Bench core's pattern

If Bench core ships a pattern for this artifact (e.g., `patterns/laravel/base/controller.md`), read it first. Your override should:

- **Diff from base, not replace it.** Mention the base by name; describe only what differs.
- **Inherit base implicitly.** Don't restate things the base already says correctly.
- **Override explicitly.** Where the project diverges, say "instead of X, use Y".

If Bench has no base pattern for this artifact, you're creating a new one — describe it from scratch.

### Step 5 — Note divergences worth surfacing

If you find inconsistencies (e.g., 7 controllers do X, 2 do Y), call them out in your report. The user decides which is canonical. Don't bake in the wrong one silently.

---

## Pattern file shape

Project-local patterns live at:

```
.bench/patterns/{group}/{name}.md
```

Where `{group}` matches Bench's pattern grouping (e.g., `laravel`, `frontend/vue`, `frontend/react`). The build pipeline merges these over the base.

### Skeleton

```markdown
# {Artifact name}

{One sentence: what this artifact is and when an agent should generate one.}

## Location

{Where this kind of file lives in THIS project. Be exact.}

- Path: `apps/cloud/Modules/{Module}/Http/Controllers/{Name}Controller.php`
- Test: `apps/cloud/Modules/{Module}/Tests/Feature/{Name}ControllerTest.php`

## Structure

{Describe the file's structure in code form. Use a real, minimal example, not pseudo-code.}

```php
<?php

namespace Modules\{Module}\Http\Controllers;

use Modules\{Module}\Http\Requests\{Name}Request;
use Modules\{Module}\Services\{Name}Service;

class {Name}Controller extends BaseController
{
    public function __construct(private {Name}Service $service) {}

    public function store({Name}Request $request)
    {
        return $this->service->create($request->validated());
    }
}
```

## Conventions

- Extends `Modules\{Module}\Http\Controllers\BaseController` (NOT Laravel's `Controller`).
- Constructor-injected services; never `app()->make()` inline.
- Validation happens in dedicated `*Request` classes — never inline in the controller.
- One public method per HTTP verb; thin controllers delegate to services.

## Common variations

- Resource controllers (`apiResource` route) follow the same skeleton with `index`, `show`, `store`, `update`, `destroy`.
- Single-action controllers use `__invoke()` and live under `Http/Controllers/Actions/`.

## Don't

- Don't extend `Illuminate\Routing\Controller` directly — always go through the module's base.
- Don't put business logic in the controller.
- Don't return raw model instances — use Resources.

## See also

- Base pattern: `laravel/base/controller.md` (Bench core)
- Related: `laravel/base/form-request.md`, `laravel/base/service.md`
```

---

## Writing rules

- **Show, don't describe.** A 10-line code example beats 40 lines of prose.
- **Be path-specific.** "Controllers live at `apps/cloud/Modules/{Module}/Http/Controllers/`" — not "controllers live in the controllers folder".
- **Use placeholder syntax `{Name}`** for variable parts. This is what agents substitute.
- **Inherit, don't restate.** If Bench's base controller pattern already says "thin controllers, delegate to services," don't repeat it. Add `## Inherits: laravel/base/controller.md` and call out only the diff.
- **Anti-patterns matter.** A short "Don't" section prevents the agent from making the same mistakes the team already fixed.
- **One pattern per file.** If you find yourself describing controllers AND form requests in the same file, split them.

---

## Output the agent produces

The `pattern` researcher returns:

1. **Scan report** (per METHODOLOGY).
2. **Proposed pattern file(s)** — full markdown drafts.
3. **Divergence callouts** — places where the codebase is inconsistent and the user should pick a canonical form.
4. **Suggested follow-up** — e.g., "the form-request convention is also non-standard — recommend running `add-pattern form-request` next."

After user review, the agent writes to `.bench/patterns/{group}/{name}.md` and triggers `bench rebuild` so the new override is materialized into `patterns-built/`.
