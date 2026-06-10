# laravel-compliance

PII, audit-logging, and data-retention guidance for Laravel apps that handle sensitive or regulated data (GDPR / HIPAA / PCI-style obligations).

## What it ships

Three patterns under `patterns/laravel/compliance/`:

- **COMPLIANCE-001 — PII** — classify columns (secret / PII / sensitive / public), encrypt at rest via casts, `$hidden`, redact PII in logs + exceptions, guard mass-assignment.
- **COMPLIANCE-002 — audit log** — an append-only audit trail (who / what / when / where), redacted change diffs, immutability enforced at the model + DB grant.
- **COMPLIANCE-003 — retention** — soft vs hard delete, config-driven retention windows, a scheduled chunked purge command, and anonymization for "right to be forgotten."

Plus a command + agent:

- **`/compliance-check`** skill + **`compliance-check`** agent — review a model, feature, or module against the three patterns and report gaps (ok / gap / n-a with file:line evidence). It reviews; it doesn't change code unless you ask.

The `laravel-ai` addon already references the standard PII rules; this addon is the canonical home for them, so the two stay consistent.

## Install

```bash
bench addon add laravel-compliance
bench rebuild
```

Then `/compliance-check Order` or `/compliance-check the user profile feature`.
