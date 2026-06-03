# AUDIT-001-deletion-logging

## Pattern

Audit logging for deletion compliance.

## Why

- Prove GDPR compliance
- Track when users requested deletion
- Evidence for legal/regulatory audits
- Non-personal data (just IDs and timestamps)

## Implementation

```php
// After user deletion
AuditLog::create([
    'action' => 'user_deleted',
    'user_id' => $user->id,           // Just ID, not personal data
    'anonymized' => true,
    'requested_at' => now(),
]);

// After hard delete (30 days later)
AuditLog::create([
    'action' => 'user_hard_deleted',
    'user_id' => $user->id,
    'deleted_at' => now(),
]);
```

## What to Log

**DO log:**
- User ID (numeric, non-personal)
- Action type
- Timestamp
- Whether anonymized

**DON'T log:**
- Name, email, phone
- IP addresses
- Personal data

## Key Points

- Audit logs are non-personal data (can be retained)
- Proves compliance with deletion requests
- Use for regulatory audits
- Store indefinitely (no GDPR requirement to delete)
