---
description: Generate a repository (interface + Eloquent implementation + container binding) for a model. Use when the user mentions the repository pattern, a {Model}Repository, depending on a data-access abstraction, or wants Eloquent queries hidden behind an interface.
argument-hint: [model + the methods you want]
---

You're the **/repository** skill. Turn the request into an enriched delegation to the `repository` agent. You don't write files.

The user's request: **$ARGUMENTS**

## Step 1: Parse
- Interface `{Model}RepositoryInterface`, implementation `Eloquent{Model}Repository`, the model it's for, and the methods to expose (e.g. `find(int $id)`, `paginate()`, `create(array $data)`).

## Step 2: Resolve
- Model missing → suggest `/model` first.
- Methods unclear → ask which data-access methods (with example signatures and return types).
- Detect where contracts, repositories, and providers live — tell the agent to match the project's layout.

## Step 3: Build context blob
```
- Model: {Model}
- Interface: {Model}RepositoryInterface
- Implementation: Eloquent{Model}Repository
- Methods: [find(int $id), paginate(int $perPage = 15), create(array $data)]
- Bind interface → implementation in a service provider
```

## Step 4: Delegate
Task tool, `subagent_type: "repository"`, pass the blob.

## Step 5: Synthesize
Report the interface + implementation + binding; show how a controller/service depends on the interface.
