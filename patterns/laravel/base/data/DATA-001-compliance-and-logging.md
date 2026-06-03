# DATA-001-compliance-and-logging

## Pattern

In-code compliance for handling and logging Personally Identifiable Information (PII).

## Core Principles

- **Never log PII directly** - Hash, redact, or anonymize before logging
- **Log to compliance standards** - Maintain audit trails for regulatory requirements
- **Preserve data utility** - Use hashing for correlation without exposing PII
- **Identify PII consistently** - Know what constitutes PII in your application

## What is PII?

**Personal Identifiable Information (PII):**
- Name, email, phone, address
- IP addresses, device IDs, session tokens
- Payment information (card numbers, bank accounts)
- Government IDs (SSN, passport, driver's license)
- Biometric data
- Any data that can identify a specific person

**Non-PII:**
- Aggregated statistics
- Business entity data (household budgets, transaction amounts)
- Anonymized/hashed identifiers
- System metadata (timestamps, status codes, resource IDs)

## Logging PII Safely

### ❌ Never Do This

```php
// Direct PII in logs - VIOLATION
Log::info('User login', [
    'email' => $user->email,
    'name' => $user->name,
    'ip' => $request->ip(),
]);

// Sensitive data in exception messages
throw new Exception("Payment failed for card {$card->number}");
```

### ✅ Always Do This

```php
// Hash PII for correlation
Log::info('User login', [
    'user_hash' => hash('sha256', $user->email),
    'user_id' => $user->id,  // Internal ID is fine
    'ip_hash' => hash('sha256', $request->ip()),
]);

// Redact sensitive data
Log::error('Payment failed', [
    'user_id' => $user->id,
    'card_last_four' => substr($card->number, -4),
    'payment_method' => $card->type,
]);

// Safe exception messages
throw new Exception("Payment processing failed for user {$user->id}");
```

## Hashing Helper

Create a consistent hashing helper:

```php
<?php

namespace App\Support;

class PiiHasher
{
    /**
     * Hash PII for logging while maintaining correlation ability.
     */
    public static function hash(string $value): string
    {
        return hash('sha256', config('app.key') . $value);
    }

    /**
     * Redact email - show domain but hash local part.
     */
    public static function redactEmail(string $email): string
    {
        [$local, $domain] = explode('@', $email);

        return substr($local, 0, 2) . '***@' . $domain;
    }

    /**
     * Redact phone - show last 4 digits only.
     */
    public static function redactPhone(?string $phone): ?string
    {
        if (! $phone) {
            return null;
        }

        return '***-***-' . substr($phone, -4);
    }
}
```

## Compliance Logging Standards

### Audit Log Structure

```php
AuditLog::create([
    'action' => 'user.account.deleted',          // Action taken
    'actor_id' => $actor->id,                    // Who performed it
    'actor_type' => get_class($actor),           // User, Admin, System
    'subject_id' => $user->id,                   // What was affected
    'subject_type' => get_class($user),
    'metadata' => [
        'reason' => 'user_requested',            // Why it happened
        'ip_hash' => PiiHasher::hash($ip),       // Hashed IP
        'user_agent' => $userAgent,              // Safe metadata
    ],
    'performed_at' => now(),
]);
```

### Required Audit Events

Log these actions for compliance:

- User account creation
- User account deletion/anonymization
- Password changes/resets
- Email/phone changes
- Access to sensitive data (payments, financial records)
- Permission/role changes
- Data exports
- Administrative actions

### Retention

- Audit logs must be retained per compliance requirements (typically 7 years)
- Audit logs themselves should NOT contain raw PII
- Use hashed identifiers or internal IDs for correlation

## Application Logging vs Audit Logging

| Type | Purpose | Contains PII? | Retention | Example |
|------|---------|---------------|-----------|---------|
| **Application Logs** | Debugging, monitoring | Never | Short (30-90 days) | `Log::error('Query failed')` |
| **Audit Logs** | Compliance, security | Hashed/Redacted only | Long (7+ years) | `AuditLog::create(['action' => 'user.login'])` |

## Exception Handling

```php
// Custom exception handler
public function render($request, Throwable $exception)
{
    // Log exception without PII
    Log::error('Exception occurred', [
        'exception' => get_class($exception),
        'message' => $exception->getMessage(), // Ensure messages don't contain PII
        'user_id' => auth()->id(),
        'route' => $request->route()?->getName(),
        'ip_hash' => PiiHasher::hash($request->ip()),
    ]);

    return parent::render($request, $exception);
}
```

## Database Query Logging

```php
// If logging queries for debugging (development only)
DB::listen(function ($query) {
    // Never log query bindings - may contain PII
    Log::debug('Query executed', [
        'sql' => $query->sql,
        'time' => $query->time,
        // DO NOT: 'bindings' => $query->bindings,
    ]);
});
```

## Key Points

- ✅ Hash PII with `hash('sha256', config('app.key') . $value)` before logging
- ✅ Use internal IDs (`user_id`) instead of emails/names
- ✅ Redact sensitive data (show last 4 digits, mask the rest)
- ✅ Maintain audit logs with hashed identifiers for compliance
- ✅ Keep application logs PII-free for debugging
- ❌ Never log raw emails, names, phone numbers, IPs, or payment data
- ❌ Never include PII in exception messages
- ❌ Never log query bindings in production (may contain PII)

## Related

- `DATA-002-deletion-and-retention` - How we handle data deletion and retention
- `AUDIT-*` - Audit module patterns for compliance logging
