# COMPLIANCE-003-retention

## Pattern

Keep personal data only as long as you have a lawful reason to, then **delete or anonymize** it. Decide per data class whether you need reversible (soft) deletion, hard deletion, or anonymization — and automate the purge on a schedule.

## Soft-delete vs hard-delete

| Use | When |
|-----|------|
| **Soft delete** (`SoftDeletes`, `deleted_at`) | reversible "undo," short grace window, record still referenced by in-flight processes |
| **Hard delete** | grace window elapsed, or the record is itself the PII you are required to remove |
| **Anonymize** | you must keep the *row* for integrity/audit/analytics but must remove the *person* |

Soft delete is **not** retention compliance on its own — the PII is still in the table. A soft-deleted record must still be hard-deleted or anonymized when its retention window ends.

## Define retention windows

Centralize the policy so the purge job and reviewers share one source of truth:

```php
// config/retention.php
return [
    'soft_deleted_grace_days' => 30,   // purge soft-deleted rows after this
    'models' => [
        \App\Models\Order::class        => ['after_days' => 2555, 'strategy' => 'anonymize'], // 7y financial
        \App\Models\Notification::class => ['after_days' => 90,  'strategy' => 'delete'],
        \App\Models\AuditLog::class     => ['after_days' => 2555, 'strategy' => 'keep'],
    ],
];
```

## Scheduled purge

Run a console command on a schedule that, for each model, hard-deletes or anonymizes rows past their window:

```php
// routes/console.php
Schedule::command('retention:purge')->daily();
```

```php
final class PurgeExpiredData extends Command
{
    protected $signature = 'retention:purge {--dry-run}';

    public function handle(): int
    {
        foreach (config('retention.models') as $model => $rule) {
            $cutoff = now()->subDays($rule['after_days']);
            $query  = $model::query()->where('created_at', '<', $cutoff);

            match ($rule['strategy']) {
                'delete'    => $this->option('dry-run') ? null : $query->forceDelete(),
                'anonymize' => $query->each(fn ($m) => $this->anonymize($m)),
                'keep'      => null,
            };
        }
        return self::SUCCESS;
    }
}
```

- Support `--dry-run` and **chunk** large tables (`->chunkById()`) so the purge doesn't exhaust memory or lock the table.
- Run inside the action's audit context — record a purge entry so the deletion itself is provable.

## Right to be forgotten / anonymization

When a person requests erasure, you usually cannot just delete the row (foreign keys, financial/audit obligations). Anonymize instead — overwrite PII with non-identifying placeholders while preserving referential integrity:

```php
public function anonymize(User $user): void
{
    $user->forceFill([
        'name'   => 'Deleted User',
        'email'  => "deleted+{$user->id}@example.invalid", // keep unique, non-routable
        'phone'  => null,
        'tax_id' => null,
    ])->save();

    $user->tokens()->delete();      // revoke access
    $this->audit->record('user.anonymized', $user);  // changes redacted
}
```

- Anonymization must be **irreversible** — overwrite, don't move to a "deleted" column you could read back.
- Cascade: also purge/anonymize related PII (addresses, uploads, search-index entries, cache, external processors).
- Keep the **audit log** entry but null its actor reference so the trail survives without re-identifying the person.

## Key Points

- Soft delete is an undo buffer, not retention — it still holds PII and must be purged on its own window.
- Drive deletion from a config-defined retention window plus a scheduled, dry-run-capable, chunked purge command.
- "Right to be forgotten" usually means **anonymize** (irreversibly overwrite PII) to preserve integrity + audit obligations, not row deletion.
- Record every purge/anonymization in the audit trail.
