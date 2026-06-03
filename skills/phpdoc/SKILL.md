---
description: Add or update PHPDoc blocks on Laravel classes/methods. Use when the user mentions documenting code, adding doc blocks, type annotations, or @throws/@param/@return tags.
argument-hint: [what the user needs]
---

You're the **/phpdoc** skill. Translate the user's PHPDoc request into an enriched delegation to the `phpdoc` agent.

The user's request: **$ARGUMENTS**

## Step 1: Parse

Extract:
- **Module** (or "all" if cross-cutting)
- **Scope**: one file | one class | module sweep
- **Target file path** if specified
- **What to add**: missing doc blocks | array shape annotations | @throws | all of the above

## Step 2: Inspect

```bash
ls Modules/{Module}/ 2>/dev/null || echo "MODULE_MISSING"
# Files lacking PHPDoc on public methods
grep -rL "^\s*\*" Modules/{Module}/app/ --include="*.php" 2>/dev/null | head -20
```

## Step 3: Resolve Ambiguity

- Scope → confirm: "One file, one class, or sweep all of `Modules/{Module}/app/`?"
- Conventions → discover from sibling files (project may use specific @param style)

## Step 4: Build Context Blob

```
Context for phpdoc agent:
- Module: {Module}
- Scope: one-file | class | module-sweep
- Target files: [paths]
- What to add: missing-doc-blocks | array-shape-annotations | throws-tags | all
- Conventions observed: [array shape style, @throws inclusion, etc.]
- Existing siblings (style reference): [path]
```

## Step 5: Delegate

Task tool, `subagent_type: "bench:phpdoc"`, pass the blob.

## Step 6: Synthesize

> "Added PHPDoc blocks to 12 public methods in `Modules/Bill/app/Actions/`. Includes `@param`, `@return`, `@throws` for documented exceptions. Array shape annotations on methods returning structured arrays."

## When to Ask vs Assume

- Document WHAT, not WHY → enforce
- Don't restate type hints → enforce
- Don't reference current task or PR in comments → enforce
- @throws → include for documented exceptions in the method body
