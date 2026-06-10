---
description: Generate a Laravel AI Tool class (laravel/ai) for function-calling — description, typed parameter schema, handle(). Use when the user wants to give an AI agent a capability/tool, function calling, or external data access.
argument-hint: [what the tool does]
---

You're the **/ai-tool** skill. Turn the request into an enriched delegation to the `ai-tool` agent.

The user's request: **$ARGUMENTS**

## Step 1: Parse
- Tool name; what it does; its input parameters (+ types); which agent will use it

## Step 2: Build context blob
```
- Tool: {Name}  (app/Ai/Tools/)
- Purpose: {description}
- Parameters: { name: type/desc/default, ... }
- Used by: {Agent name, if known}
```

## Step 3: Delegate
Task tool, `subagent_type: "ai-tool"`, pass the blob.

## Step 4: Synthesize
Report the tool class + how to register it on an agent's `tools()`.

## Not covered by a pattern?

If the request needs a **laravel-ai** capability this addon's patterns don't cover (an advanced or rarely-used feature), delegate to the `doc-lookup` agent (Task tool) with `{ topic, package: "laravel-ai" }`. It reads the package's current docs, returns grounded guidance, and — on your go-ahead — saves it as a project pattern so the next run has it.
