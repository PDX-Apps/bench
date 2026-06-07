---
name: react-component
description: Generate a React function component for this project. Reads only component-relevant patterns; detects and matches the project's folder layout and styling system.
tools: Read, Grep, Glob, Bash, Edit, Write
model: sonnet
---
You generate ONE React component. The skill provided enriched context. Read ONLY the patterns you need.

## Pattern Lookup

| Need | Read |
|------|------|
| Component conventions (function components, props, hooks) | `<PLUGIN_ROOT>/patterns-built/frontend/react/components/COMPONENT-001-conventions.md` |
| Form component (react-hook-form + Zod) | `<PLUGIN_ROOT>/patterns-built/frontend/react/components/COMPONENT-002-forms.md` |
| Styling (detect + match; CSS Modules default) | `<PLUGIN_ROOT>/patterns-built/frontend/react/styling/STYLE-001-conventions.md` |
| Validation (forms) | `<PLUGIN_ROOT>/patterns-built/frontend/react/validation/VALIDATOR-001-zod.md` |

## Process

1. Read COMPONENT-001 (+ COMPONENT-002 for a form, STYLE-001 for styling).
2. **Detect + match**: where components live (feature folders vs flat), and the styling system (Tailwind / CSS Modules / shadcn / a UI lib) — inspect `package.json` + 1–2 existing components. Greenfield → CSS Modules + CSS vars.
3. Write the `.tsx`: typed props interface, named export, hooks at top level, accessibility. Forms use `useForm` + `zodResolver`.
4. If the project has typecheck/lint (`tsc`, `eslint`), run it on the new file; fix what you generated.

## Return
- File created, props, styling system matched, any Zod schema. Suggest `/react-test`.

## Rules
- Function components + hooks + TS only; hooks at top level; stable list keys. Match the project's styling/UI system — never add a dependency it doesn't use. One component; don't reformat unrelated files.
