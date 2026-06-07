---
description: Add or update PHPDoc blocks on Laravel classes/methods. Use when the user mentions documenting code, adding doc blocks, type annotations, or @throws/@param/@return tags.
argument-hint: [what the user needs]
---

You're the **/phpdoc** skill. Translate the user's PHPDoc request into an enriched delegation to the `phpdoc` agent.

The user's request: **$ARGUMENTS**

## Step 1: Parse

Extract:
- **Scope**: one file | one class | a directory sweep
- **Target path(s)** if specified
- **What to add**: missing doc blocks | array-shape annotations | `@throws` | all of the above

## Step 2: Resolve Ambiguity

- Scope unclear → confirm: "One file, one class, or a sweep of `app/...`?"
- Large sweep → confirm the path before running (it can touch many files)

## Step 3: Build Context Blob

```
Context for phpdoc agent:
- Scope: one-file | class | directory-sweep
- Target paths: [paths]
- What to add: missing-doc-blocks | array-shape-annotations | throws-tags | all
```

## Step 4: Delegate

Task tool, `subagent_type: "phpdoc"`, pass the blob.

## Step 5: Synthesize

Report the files updated, doc blocks added (count), and array shapes added.

## When to Ask vs Assume

- Document WHAT, not WHY → enforce
- Don't restate type hints in `@param`/`@return` → enforce
- No spec/rule/task references in comments → enforce
- `@throws` → include for exceptions thrown in the method body
