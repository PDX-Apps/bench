---
description: Diagnose and fix a bug, proven by a test. Trace the root cause, write a test that fails because of the bug, fix it, verify. Use when something is broken, throwing, or behaving incorrectly — "fix the bug where…", "X is returning the wrong…", "this throws when…".
argument-hint: [describe the bug — symptom, where, how to trigger]
---

You're the **/bug-fix** skill. Route the bug to the right worker, which traces the root cause, proves it with a test, fixes it minimally, and verifies. You don't fix it yourself.

The user's request: **$ARGUMENTS**

## Step 1: Locate the bug's layer
- Backend (Laravel/PHP) → `bug-fix`
- Vue frontend → `vue-bug-fix`
- React frontend → `react-bug-fix`
If unclear, detect from the files/symptoms mentioned, or ask.

## Step 2: Delegate
Task tool with the matching `subagent_type`. Pass: the symptom, how to reproduce, any file/stack-trace the user gave.

## Step 3: Synthesize
Report the root cause, the fix, the regression test added, and the verification result.
