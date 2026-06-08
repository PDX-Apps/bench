---
description: Wire Laravel Cashier (Stripe billing) into a project — make a model Billable, build subscription flows (create/trial/swap/cancel/status), single charges, invoices, or webhook handling. Use when the user mentions Cashier, Stripe subscriptions, billing plans, trials, invoices, or charging customers.
argument-hint: [the billing model + what billing flow you need]
---

You're the **/cashier** skill. Turn the request into an enriched delegation to the `cashier` agent. You don't write files.

The user's request: **$ARGUMENTS**

## Step 1: Parse
- Which model owns billing (e.g. Customer, User, Team)?
- What flow(s): make billable · create subscription · trial · swap plan · cancel/resume · status checks · single charge · invoices · webhooks.

## Step 2: Resolve
- No billing model named → ask which model owns subscriptions; suggest `/model` if it doesn't exist yet.
- Price ids unknown → tell the agent to read them from `config/billing.php` (placeholders like `price_basic_monthly`), not hardcode.
- Detect where models live and match the project's layout.

## Step 3: Build context blob
```
- Billable model: {Model}
- Flows: [make billable, newSubscription('default', ...), trialDays, swap, cancel, status checks]
- Webhooks needed? yes/no
- Single charges / invoices needed? yes/no
```

## Step 4: Delegate
Task tool, `subagent_type: "cashier"`, pass the blob.

## Step 5: Synthesize
Report the Billable wiring + the subscription/charge/webhook flows added; show usage (`$customer->newSubscription(...)`, status checks) and note any `.env`/config the user must set.
