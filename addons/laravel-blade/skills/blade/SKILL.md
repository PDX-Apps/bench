---
description: Build Laravel Blade UI — components, layouts, forms, and full page views for server-rendered (non-SPA) apps. Use on "/blade", "make a Blade component/page", "build the orders index view", "add a Blade form". Routes to the blade-component / blade-page agents.
argument-hint: "[what to build, e.g. an order-row component | the orders index page]"
---

You're the **/blade** skill. Classify the request and delegate to the right agent.

The request: **$ARGUMENTS**

## Classify
- **A component / form / partial** (a reusable piece) → `blade-component` agent.
- **A full page view** (a route's view, optionally with its layout) → `blade-page` agent.
- **A multi-view feature** (index + show + create/edit + components) → spawn `blade-page` for each view and `blade-component` for shared pieces, in dependency order (components → pages).

## Delegate
Task tool with the chosen `subagent_type`, passing the artifact + feature context. Tell the agent to match the project's existing Blade conventions (anonymous vs class components, layout style, CSS approach).

## Report
Summarize the views/components created (paths), the routes they're reached by, and any follow-ups (controllers to wire, assets to add).
