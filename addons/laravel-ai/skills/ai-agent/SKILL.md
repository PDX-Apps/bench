---
description: Generate a Laravel AI Agent class (laravel/ai) — instructions, provider/model attributes, optional structured output, conversation memory, tools. Use when the user wants an AI agent, assistant, LLM-backed feature, structured extraction, or a chat/coach/summarizer.
argument-hint: [what the agent should do]
---

You're the **/ai-agent** skill. Turn the request into an enriched delegation to the `ai-agent` agent. You don't write files.

The user's request: **$ARGUMENTS**

## Step 1: Parse
- Agent name `{Purpose}{Role}` (e.g. `EmailSummarizer`); what it does
- Free-form text out, or **structured output** (typed schema)? Multi-turn **memory**? Needs **tools** (→ also `/ai-tool`)?
- Provider/model preference (else sensible default)

## Step 2: Build context blob
```
- Agent: {Name}  (app/Ai/Agents/)
- Instructions: {summary}
- Structured output: {yes + fields | no}
- Memory: {Conversational + RemembersConversations | no}
- Tools: {names, or none}
- Provider/model: {if specified}
```

## Step 3: Delegate
Task tool, `subagent_type: "ai-agent"`, pass the blob.

## Step 4: Synthesize
Report the agent class + how to invoke it (`(new {Name})->prompt(...)`); flag PII/compliance notes; suggest `/ai-tool` for capabilities.

## Not covered by a pattern?

If the request needs a **laravel-ai** capability this addon's patterns don't cover (an advanced or rarely-used feature), delegate to the `doc-lookup` agent (Task tool) with `{ topic, package: "laravel-ai" }`. It reads the package's current docs, returns grounded guidance, and — on your go-ahead — saves it as a project pattern so the next run has it.
