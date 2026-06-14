#!/usr/bin/env python3
"""Bench backend guardrail (PreToolUse hook).

Nudges (or blocks) the MAIN agent when it hand-writes a Laravel backend artifact,
pointing it at the matching /bench:* skill. Bench's worker SUBAGENTS are never
nudged: their tool payload carries `agent_type` (the main loop's does not).
Never breaks the session: any error → allow silently.
"""
import sys, json, os, fnmatch

# Artifact suffix -> /bench skill. Order: most specific first. Matches both flat
# app/** and nwidart Modules/**/app/** (we match on the suffix, ignoring the prefix).
RULES = [
    ("*/Http/Controllers/*.php", "/bench:controller"),
    ("*/Http/Requests/*.php",    "/bench:request"),
    ("*/Http/Resources/*.php",   "/bench:resource"),
    ("*/Actions/*.php",          "/bench:action"),
    ("*/Data/*.php",             "/bench:request"),   # DTOs ride with their FormRequest's toDto()
    ("*/Models/*.php",           "/bench:model"),
    ("*/Policies/*.php",         "/bench:policy"),
    ("*/Jobs/*.php",             "/bench:job"),
    ("*/Events/*.php",           "/bench:event"),
    ("*/database/migrations/*.php", "/bench:migration"),
]

def allow():
    sys.exit(0)

def read_config(cwd):
    """Minimal parse of .bench/guardrails.yaml (no pyyaml dependency)."""
    mode, extra = "warn", []
    path = os.path.join(cwd, ".bench", "guardrails.yaml")
    if not os.path.isfile(path):
        return mode, extra
    in_paths = False
    try:
        for line in open(path):
            st = line.strip()
            if not st or st.startswith("#"):
                continue
            if st.startswith("mode:"):
                mode = st.split(":", 1)[1].strip().strip("\"'") or mode
                in_paths = False
            elif st.startswith("paths:"):
                in_paths = True
            elif in_paths and st.startswith("- "):
                extra.append(st[2:].strip().strip("\"'"))
            else:
                in_paths = False
    except Exception:
        pass
    return mode, extra

def main():
    try:
        payload = json.load(sys.stdin)
    except Exception:
        allow()

    if payload.get("tool_name") not in ("Write", "Edit", "MultiEdit"):
        allow()
    if payload.get("agent_type"):          # a subagent (bench worker, or any) — never nag
        allow()
    if os.environ.get("BENCH_ALLOW_HANDWRITE"):  # explicit human override
        allow()

    ti = payload.get("tool_input") or {}
    # Write/Edit/MultiEdit all carry a top-level file_path; fall back to the first
    # edit's path defensively in case a payload shape ever differs.
    path = ti.get("file_path") or ti.get("path") \
        or (ti.get("edits") or [{}])[0].get("file_path") or ""
    if not path:
        allow()
    cwd = payload.get("cwd") or os.getcwd()

    mode, extra = read_config(cwd)
    if mode == "off":
        allow()

    norm = path.replace("\\", "/")
    skill = None
    for pat, sk in RULES:
        if fnmatch.fnmatch(norm, "*" + pat) or fnmatch.fnmatch(norm, pat):
            skill = sk
            break
    if skill is None:
        for pat in extra:
            if fnmatch.fnmatch(norm, pat) or fnmatch.fnmatch(norm, "*" + pat):
                skill = "the matching /bench skill"
                break
    if skill is None:
        allow()

    base = os.path.basename(path)
    msg = (
        f"[bench guardrail] '{base}' is a backend artifact. Generate it via {skill} "
        f"— it delegates to the worker agent that builds it in isolated context with the "
        f"project's pattern loaded, instead of you hand-writing it. For a multi-layer feature "
        f"use /bench:implement. Side effects belong in an Action (execute(User $user, ...)); "
        f"FormRequest input flows through toDto(). If Bench lacks a pattern, STOP and ask — "
        f"don't freelance a flatter shape or record a private workaround."
    )

    if mode == "block":
        print(json.dumps({"hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "deny",
            "permissionDecisionReason": msg,
        }}))
        sys.exit(0)

    # warn (default): non-blocking — add context for the model, do NOT override permissions.
    print(json.dumps({"hookSpecificOutput": {
        "hookEventName": "PreToolUse",
        "additionalContext": msg,
    }}))
    sys.exit(0)

if __name__ == "__main__":
    main()
