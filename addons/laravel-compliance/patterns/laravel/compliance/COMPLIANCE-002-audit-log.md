# COMPLIANCE-002-audit-log

## Pattern

Record an **append-only audit trail** of sensitive actions: *who* did *what*, to *which* record, *when*, and *from where*. The trail must be immutable — entries are written, never updated or deleted — so it can serve as evidence.

## What to audit

- Authentication events: login, logout, failed login, password change, 2FA enrol/disable.
- Reads of sensitive data (where regulation requires read-logging, e.g. health/financial records).
- Create/update/delete of records classified Secret/PII/Sensitive.
- Permission/role changes, exports, and "right to be forgotten" deletions.

## Schema

```php
Schema::create('audit_logs', function (Blueprint $table) {
    $table->id();
    $table->ulid('public_id')->unique();
    $table->string('action');                  // 'order.updated', 'auth.login_failed'
    $table->nullableMorphs('auditable');       // the affected record (type + id)
    $table->foreignId('actor_id')->nullable(); // who acted; null = system/guest
    $table->string('actor_type')->nullable();  // model class of the actor
    $table->json('changes')->nullable();       // { field: [old, new] } — redacted
    $table->ipAddress('ip_address')->nullable();
    $table->text('user_agent')->nullable();
    $table->timestamp('created_at')->index();  // no updated_at — entries never change
});
```

- **No `updated_at`, no soft-delete** — the table is append-only.
- Store the actor as a polymorphic reference, not a copied name (the name may change; resolve at read time).
- `changes` records old/new per field — **redact PII/secret values** here (store `"[redacted]"` or a hash), or you have just duplicated sensitive data into a long-lived table.

## Writing entries

Centralize writes behind one service so the shape is consistent and redaction is enforced in one place:

```php
final class AuditLogger
{
    public function record(string $action, ?Model $auditable = null, array $changes = []): void
    {
        AuditLog::create([
            'action'     => $action,
            'auditable_type' => $auditable?->getMorphClass(),
            'auditable_id'   => $auditable?->getKey(),
            'actor_id'   => $this->actorId(),
            'actor_type' => $this->actorType(),
            'changes'    => $this->redact($changes),
            'ip_address' => request()?->ip(),
            'user_agent' => request()?->userAgent(),
        ]);
    }
}
```

- Resolve the current actor through the framework's auth boundary inside the service — do not pass identity in from callers.
- For model-driven auditing, hook an **Eloquent observer** (`created`/`updated`/`deleted`) that calls the logger with `$model->getChanges()` minus the PII/secret keys.
- Emit audit writes inside the **same DB transaction** as the action when the trail is legally required, so a rollback drops both. For non-critical analytics, queue them instead.

## Protecting the trail

- Block updates/deletes at the model: throw from `updating`/`deleting` events, or grant the app DB user INSERT/SELECT only on `audit_logs`.
- Retain audit logs per your legal retention window — they often outlive the records they describe.
- Never expose raw audit logs through a normal API resource; gate behind an admin policy and a dedicated read model.

## Key Points

- Append-only: insert + select, never update/delete. Enforce at the model and the DB grant.
- Capture who/what/when/where; redact PII inside `changes`.
- One central logger or an observer — never scatter `AuditLog::create()` across controllers.
- Write in the action's transaction when the trail is required as evidence.
