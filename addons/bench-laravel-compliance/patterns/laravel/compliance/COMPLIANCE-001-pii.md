# COMPLIANCE-001-pii

## Pattern

Identify **personally identifiable information (PII)** and sensitive data on each model, then protect it at every layer: encrypted at rest, never serialized by accident, never written to logs.

## Step 1 — Classify the columns

For every model, tag each attribute:

| Class | Examples | Handling |
|-------|----------|----------|
| **Secret** | passwords, API tokens, 2FA secrets, recovery codes | hash or encrypt; never logged; never returned in any response |
| **PII** | name, email, phone, address, DOB, government IDs, IP | encrypt at rest if regulated; `$hidden` unless explicitly needed; redact in logs |
| **Sensitive** | financial figures, health notes, location history | encrypt if regulated; access-controlled; audit reads (see COMPLIANCE-002) |
| **Public** | public id, status, created_at | no special handling |

Record the classification near the model (a `// PII:` comment block or a dedicated doc) so reviewers and the `/compliance-check` agent can see intent.

## Step 2 — Encrypt sensitive columns at rest

Use the framework's encrypted cast so the value is transparently encrypted in the database and decrypted on access. Casts are defined in the `casts()` method:

```php
protected function casts(): array
{
    return [
        'tax_id'        => 'encrypted',
        'notes'         => 'encrypted',
        'preferences'   => 'encrypted:array',
    ];
}
```

- Encrypted columns must be `text`/`longText` (ciphertext is larger than plaintext) — see the migration pattern.
- Encrypted columns **cannot be queried with `where`** on the plaintext. If you must look a value up, store a separate **blind index** (a deterministic HMAC of the normalized value) in its own column and query that.
- Rotating `APP_KEY` invalidates all encrypted values — plan a re-encryption migration before rotating.

> Always-encrypted secrets (passwords, recovery codes) use a one-way hash, not the encrypted cast — you never need the plaintext back.

## Step 3 — Keep PII out of responses (`$hidden`)

Default to hidden; opt specific fields back in where a response genuinely needs them.

```php
protected $hidden = [
    'password',
    'remember_token',
    'tax_id',
    'two_factor_secret',
];
```

- API Resources are the real serialization boundary — only map the fields a given response needs (see the API-resource pattern). `$hidden` is the safety net, not the policy.
- Never return a secret column in any resource, ever — not even masked. If the UI needs "last 4 digits," compute and store that separately.

## Step 4 — Redact PII in logs and exceptions

```php
// config/logging.php — scrub before anything is written
// Laravel ships sensitive keys in $dontFlash; mirror that for logging.

Log::info('Order placed', [
    'order_id'    => $order->public_id,   // safe identifier
    // NOT: 'email' => $user->email,
]);
```

- Never log full request payloads on auth, payment, or profile endpoints — they carry credentials and PII. Add those routes' fields to the request `$dontFlash` list.
- Redact PII in exception context and breadcrumbs before they reach an error tracker (Sentry/Bugsnag `before_send` hook).
- Log a **hash or a stable public id** when you need to correlate events to a person, never the raw identifier.
- Never log secrets at any level, including `debug`.

## Step 5 — Mass-assignment + casual exposure

- Guard secret/PII columns from mass assignment (`$guarded` or an explicit `$fillable` that omits them).
- `toArray()`/`toJson()` and `dd($model)` in a controller can leak everything — rely on Resources for output and never dump models into responses or logs.

## Key Points

- Classify first; you cannot protect what you have not labeled.
- Encrypt regulated PII + secrets at rest via casts; secrets are hashed, not reversibly encrypted.
- `$hidden` is the safety net; API Resources are the deliberate output boundary.
- Logs, exceptions, and error trackers are the most common leak — redact there explicitly.
- Pair this with COMPLIANCE-002 (audit who reads/writes sensitive data) and COMPLIANCE-003 (how long you keep it).
