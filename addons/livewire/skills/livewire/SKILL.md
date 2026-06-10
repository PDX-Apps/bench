---
description: Generate a Livewire 3 component (class-based or Volt) for server-rendered reactive UI in Laravel. Use when the user mentions Livewire, a wire:model form, a reactive Blade component, a Form object, file uploads in Livewire, or a Volt single-file component.
argument-hint: [component name + what it does (properties, actions, form fields)]
---

You're the **/livewire** skill. Turn the request into an enriched delegation to the `livewire-component` agent. You don't write files.

The user's request: **$ARGUMENTS**

## Step 1: Parse
- Component name (e.g. `ShowOrder`, `Orders/CreateOrder`) and what it renders.
- State (public properties), actions (methods), and any form fields + validation.
- Style: class-based (default) or **Volt** single-file if the user says so.
- Whether a **Form object** is warranted (more than a couple of fields) and whether there are **file uploads**.

## Step 2: Resolve
- Model referenced but missing → suggest `/model` first.
- Form fields/validation unclear → ask for the fields + rules.
- If the user wants Volt, confirm the project has `livewire/volt` (the agent will detect/scaffold).
- Detect where the project keeps Livewire classes + views so the agent matches the layout.

## Step 3: Build context blob
```
- Component: {Name}  (renders: ...)
- Style: class-based | volt (functional | class)
- Properties: [search:string, perPage:int]
- Actions: [save(), archive($id)]
- Form fields + rules: [reference: required|min:3, total: required|numeric|min:0]
- Form object? yes/no   File uploads? yes/no (mimes + max)
```

## Step 4: Delegate
Task tool, `subagent_type: "livewire-component"`, pass the blob.

## Step 5: Synthesize
Report the component class + view (and Form object if any); show how to render it (`<livewire:show-order :order="$order" />` or `@livewire(...)`).

## Not covered by a pattern?

If the request needs a **livewire** capability this addon's patterns don't cover (an advanced or rarely-used feature), delegate to the `doc-lookup` agent (Task tool) with `{ topic, package: "livewire" }`. It reads the package's current docs, returns grounded guidance, and — on your go-ahead — saves it as a project pattern so the next run has it.
