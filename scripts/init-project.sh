#!/usr/bin/env bash
# init-project.sh — set up this plugin inside a Laravel project.
#
# Run this from the PROJECT directory you want to add the plugin to.
# It copies (or symlinks) the plugin into .claude/plugins/, runs install.sh
# inside that copy for the project's actual Laravel/PHP/Vue versions, and
# optionally registers it in .claude/settings.local.json so Claude Code
# recognizes it project-scoped.
#
# Usage (run from inside the project):
#   /path/to/Bench/scripts/init-project.sh                              # copy mode, auto-detect versions
#   /path/to/Bench/scripts/init-project.sh --symlink                    # symlink to source
#   /path/to/Bench/scripts/init-project.sh --project=/path              # explicit project dir
#   /path/to/Bench/scripts/init-project.sh --laravel=13 --php=8.5 ...   # explicit versions (monorepos)
#
# Monorepos / non-standard layouts:
#   Auto-detect looks for composer.json + package.json at the project root. If
#   your code lives in apps/cloud/ etc., pass versions explicitly:
#     bench build --laravel=13 --php=8.5 --frontend=vue --vue=3
#   Then describe the layout in your project's CLAUDE.md so the agents know
#   where things live.
#
# Frontend selection:
#   --frontend=vue       (default if package.json has vue)
#   --frontend=react     (uses patterns/frontend/react/ — skeleton at present)
#   --frontend=none      (backend-only project, skip frontend patterns)
#
# Bench-manager addon (bundled by default):
#   By default, init loads the bench-manager addon from addons/bench-manager/ which
#   ships the /bench-* commands to tailor Bench to this project: /bench-init (scan
#   for deviations + set up .bench/ overrides), /bench-configure (run concern setup),
#   /bench-override (change a default), /bench-slice (skill→agent→pattern for your own
#   domains), /bench-revert (remove an override), and /bench-list, /bench-show,
#   /bench-status (inspect).
#   --no-manager  skip the bundled addon (strictly hand-configured install)
#   --manager     force-include (default — flag exists for explicitness)
#   (--no-onboard / --onboard are accepted as back-compat aliases)
#
# Re-running is safe — refreshes the project copy and rebuilds.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_SRC="$(dirname "$SCRIPT_DIR")"
PLUGIN_NAME="$(basename "$PLUGIN_SRC")"

PROJECT_ROOT="$PWD"
MODE="copy"   # copy | symlink
PASSTHROUGH=()  # version flags forwarded to install.sh

REGISTER_MODE="ask"   # ask | yes | no — controls whether init writes to .claude/settings.json
LOAD_MANAGER=true     # bundle the bench-manager addon by default; --no-manager opts out

while [[ $# -gt 0 ]]; do
  case "$1" in
    --symlink) MODE="symlink"; shift ;;
    --copy)    MODE="copy"; shift ;;
    --project=*) PROJECT_ROOT="${1#*=}"; shift ;;
    --laravel=*|--php=*|--vue=*|--frontend=*|--addon=*|--profile=*|--quasar=*|--quvel=*)
      PASSTHROUGH+=("$1"); shift ;;
    --register)    REGISTER_MODE="yes"; shift ;;
    --no-register) REGISTER_MODE="no"; shift ;;
    --no-manager|--no-onboard)  LOAD_MANAGER=false; shift ;;
    --manager|--onboard)        LOAD_MANAGER=true; shift ;;
    -h|--help)
      grep -E '^#( |$)' "${BASH_SOURCE[0]}" | sed 's/^# //; s/^#//'
      exit 0 ;;
    *) echo "Unknown argument: $1" >&2; exit 1 ;;
  esac
done

# Auto-load the bundled bench-manager addon unless explicitly opted out.
# This ships the /bench-init, /bench-configure, /bench-override, /bench-slice,
# /bench-revert, /bench-list, /bench-show, and /bench-status skills + their authoring
# agents — the flow for tailoring Bench to a project. Opt out with --no-manager for a
# hand-configured install.
if $LOAD_MANAGER && [[ -d "$PLUGIN_SRC/addons/bench-manager" ]]; then
  PASSTHROUGH+=("--addon=$PLUGIN_SRC/addons/bench-manager")
fi

# ---------- Sanity checks ----------
if [[ ! -d "$PROJECT_ROOT" ]]; then
  echo "ERROR: project dir not found: $PROJECT_ROOT" >&2
  exit 1
fi
if [[ ! -f "$PLUGIN_SRC/.claude-plugin/plugin.json" ]]; then
  echo "ERROR: plugin source not valid (missing .claude-plugin/plugin.json): $PLUGIN_SRC" >&2
  exit 1
fi

# Detect a monorepo layout: root has neither composer.json nor a package.json with
# laravel/vue/react deps. Tools like turbo + pnpm-workspace.yaml are strong signals
# that real apps live in subdirs.
NEEDS_MONOREPO_SCAN=false
if [[ ${#PASSTHROUGH[@]} -eq 0 && ! -f "$PROJECT_ROOT/composer.json" ]]; then
  if [[ ! -f "$PROJECT_ROOT/package.json" ]]; then
    NEEDS_MONOREPO_SCAN=true
  elif ! grep -qE '"(vue|react|laravel)"' "$PROJECT_ROOT/package.json" 2>/dev/null; then
    # package.json exists but it's orchestration (turbo, pnpm, etc.) — apps probably nested
    if [[ -f "$PROJECT_ROOT/pnpm-workspace.yaml" || -f "$PROJECT_ROOT/turbo.json" || -f "$PROJECT_ROOT/lerna.json" ]] \
       || grep -qE '"workspaces":' "$PROJECT_ROOT/package.json" 2>/dev/null; then
      NEEDS_MONOREPO_SCAN=true
    fi
  fi
fi

if $NEEDS_MONOREPO_SCAN; then
  echo "No composer.json or package.json found at the project root."
  echo "Scanning subdirectories for a monorepo layout..."
  echo ""

  # Find composer.json + package.json files one or two levels deep, in common
  # monorepo locations. Capture the FIRST match of each ecosystem; show all matches to the user.
  LARAVEL_DIRS=()
  FRONTEND_DIRS=()
  while IFS= read -r -d '' f; do
    LARAVEL_DIRS+=("$(dirname "$f")")
  done < <(find "$PROJECT_ROOT/apps" "$PROJECT_ROOT/packages" "$PROJECT_ROOT/services" -maxdepth 2 -name composer.json -not -path '*/vendor/*' -not -path '*/node_modules/*' -print0 2>/dev/null)
  while IFS= read -r -d '' f; do
    FRONTEND_DIRS+=("$(dirname "$f")")
  done < <(find "$PROJECT_ROOT/apps" "$PROJECT_ROOT/packages" "$PROJECT_ROOT/services" -maxdepth 2 -name package.json -not -path '*/node_modules/*' -print0 2>/dev/null)

  if (( ${#LARAVEL_DIRS[@]} == 0 && ${#FRONTEND_DIRS[@]} == 0 )); then
    cat >&2 <<EOF
ERROR: no composer.json or package.json found at $PROJECT_ROOT or in apps/, packages/, services/.
Cannot detect Laravel/PHP/Vue/React versions.

If your code lives somewhere unusual, pass versions explicitly:
  bench build --laravel=13 --php=8.5 --frontend=vue --vue=3
Or for backend-only:
  bench build --laravel=13 --php=8.5 --frontend=none

Then document the layout in your project's CLAUDE.md so the agents know where things live.
EOF
    exit 1
  fi

  # Show what we found — only list actual Laravel apps and actual frontend apps.
  # Suppress package.jsons without vue/react deps (typically shared TS libs / lint configs / etc.).
  if (( ${#LARAVEL_DIRS[@]} > 0 )); then
    echo "  Laravel apps:"
    for d in "${LARAVEL_DIRS[@]}"; do
      ver=$(grep -E '"laravel/framework"' "$d/composer.json" 2>/dev/null | head -1 | sed -E 's|.*"laravel/framework"[[:space:]]*:[[:space:]]*"[\^~>=<]*([0-9]+).*|\1|' || echo "?")
      php=$(grep -E '^[[:space:]]*"php"' "$d/composer.json" 2>/dev/null | head -1 | sed -E 's|.*"php"[[:space:]]*:[[:space:]]*"[\^~>=<]*([0-9]+\.[0-9]+).*|\1|' || echo "?")
      rel="${d#$PROJECT_ROOT/}"
      echo "    $rel  →  Laravel $ver, PHP $php"
    done
  fi
  ACTUAL_FRONTEND_DIRS=()
  SHARED_TS_PACKAGES=()
  for d in "${FRONTEND_DIRS[@]+${FRONTEND_DIRS[@]}}"; do
    if grep -qE '^\s*"(vue|react)":' "$d/package.json" 2>/dev/null; then
      ACTUAL_FRONTEND_DIRS+=("$d")
    else
      SHARED_TS_PACKAGES+=("$d")
    fi
  done
  if (( ${#ACTUAL_FRONTEND_DIRS[@]} > 0 )); then
    echo "  Frontend apps:"
    for d in "${ACTUAL_FRONTEND_DIRS[@]}"; do
      vue=$(grep -E '^[[:space:]]*"vue":' "$d/package.json" 2>/dev/null | head -1 | sed -E 's|.*"vue":[[:space:]]*"[\^~]*([0-9]+).*|\1|' || echo "")
      react=$(grep -E '^[[:space:]]*"react":' "$d/package.json" 2>/dev/null | head -1 | sed -E 's|.*"react":[[:space:]]*"[\^~]*([0-9]+).*|\1|' || echo "")
      kind="(detected: nothing)"
      [[ -n "$vue" ]] && kind="Vue $vue"
      [[ -n "$react" ]] && kind="React $react"
      rel="${d#$PROJECT_ROOT/}"
      echo "    $rel  →  $kind"
    done
  fi
  if (( ${#SHARED_TS_PACKAGES[@]} > 0 )); then
    echo "  (Also found ${#SHARED_TS_PACKAGES[@]} TypeScript package(s) without Vue/React deps — shared libs, ignored)"
  fi
  # Update FRONTEND_DIRS to the filtered list for downstream "pick first" logic
  FRONTEND_DIRS=("${ACTUAL_FRONTEND_DIRS[@]+${ACTUAL_FRONTEND_DIRS[@]}}")
  echo ""

  # Pick first-of-each for auto-defaults, but let the user override
  if (( ${#LARAVEL_DIRS[@]} > 0 )); then
    FIRST_LARAVEL="${LARAVEL_DIRS[0]}"
    DETECTED_LARAVEL=$(grep -E '"laravel/framework"' "$FIRST_LARAVEL/composer.json" 2>/dev/null | head -1 | sed -E 's|.*"laravel/framework"[[:space:]]*:[[:space:]]*"[\^~>=<]*([0-9]+).*|\1|' || true)
    DETECTED_PHP=$(grep -E '^[[:space:]]*"php"' "$FIRST_LARAVEL/composer.json" 2>/dev/null | head -1 | sed -E 's|.*"php"[[:space:]]*:[[:space:]]*"[\^~>=<]*([0-9]+\.[0-9]+).*|\1|' || true)
  fi
  if (( ${#FRONTEND_DIRS[@]} > 0 )); then
    FIRST_FRONTEND="${FRONTEND_DIRS[0]}"
    if grep -qE '^\s*"vue":' "$FIRST_FRONTEND/package.json" 2>/dev/null; then
      DETECTED_FRONTEND="vue"
      DETECTED_VUE=$(grep -E '^[[:space:]]*"vue":' "$FIRST_FRONTEND/package.json" 2>/dev/null | head -1 | sed -E 's|.*"vue":[[:space:]]*"[\^~]*([0-9]+).*|\1|' || true)
    elif grep -qE '^\s*"react":' "$FIRST_FRONTEND/package.json" 2>/dev/null; then
      DETECTED_FRONTEND="react"
    fi
  fi

  # Show what would be passed to build
  echo "Will install with:"
  [[ -n "${DETECTED_LARAVEL:-}" ]] && echo "  --laravel=$DETECTED_LARAVEL"
  [[ -n "${DETECTED_PHP:-}" ]] && echo "  --php=$DETECTED_PHP"
  [[ -n "${DETECTED_FRONTEND:-}" ]] && echo "  --frontend=$DETECTED_FRONTEND"
  [[ -n "${DETECTED_VUE:-}" ]] && echo "  --vue=$DETECTED_VUE"
  if [[ -z "${DETECTED_LARAVEL:-}" && -z "${DETECTED_FRONTEND:-}" ]]; then
    echo "  (nothing detected — bailing)"
    exit 1
  fi
  echo ""
  # Only nag about CLAUDE.md if it doesn't already exist
  if [[ ! -f "$PROJECT_ROOT/CLAUDE.md" ]]; then
    echo "Note: agents will need to know your monorepo layout. The next step will offer to"
    echo "scaffold a starter CLAUDE.md you can edit (or you can write one yourself)."
    echo ""
  fi

  # Interactive confirm — only if we have a TTY (skip in CI / piped contexts)
  if [[ -t 0 ]]; then
    read -r -p "Proceed with these versions? [Y/n] " ANS
    case "${ANS:-y}" in
      [yY]|[yY][eE][sS]) ;;
      *) echo "Aborted. Re-run with explicit --laravel=N --php=N --frontend=X --vue=N to override."; exit 1 ;;
    esac
  else
    echo "(non-interactive shell — proceeding automatically)"
  fi

  # Forward to install.sh as explicit flags
  [[ -n "${DETECTED_LARAVEL:-}" ]] && PASSTHROUGH+=("--laravel=$DETECTED_LARAVEL")
  [[ -n "${DETECTED_PHP:-}" ]] && PASSTHROUGH+=("--php=$DETECTED_PHP")
  [[ -n "${DETECTED_FRONTEND:-}" ]] && PASSTHROUGH+=("--frontend=$DETECTED_FRONTEND")
  [[ -n "${DETECTED_VUE:-}" ]] && PASSTHROUGH+=("--vue=$DETECTED_VUE")

  # Offer to scaffold a starter CLAUDE.md so agents can discover the monorepo layout
  # (DX-6: especially valuable now that DX-1 makes agents actually read it).
  if [[ ! -f "$PROJECT_ROOT/CLAUDE.md" ]]; then
    SCAFFOLD_CLAUDEMD=true
    if [[ -t 0 ]]; then
      read -r -p "No CLAUDE.md found. Scaffold a starter CLAUDE.md describing the monorepo? [Y/n] " ANS2
      case "${ANS2:-y}" in
        [yY]|[yY][eE][sS]) SCAFFOLD_CLAUDEMD=true ;;
        *) SCAFFOLD_CLAUDEMD=false ;;
      esac
    fi
    if $SCAFFOLD_CLAUDEMD; then
      cat > "$PROJECT_ROOT/CLAUDE.md" <<CMD_EOF
# $(basename "$PROJECT_ROOT") — Claude Code Project Memory

> Tells Claude Code (and the Bench plugin's agents) how this repo is laid out, what conventions are in place, and where to put new code.

## Repository layout

\`\`\`
$(basename "$PROJECT_ROOT")/                      # ← repo root; plugin installed here
$(for d in "${LARAVEL_DIRS[@]+${LARAVEL_DIRS[@]}}"; do echo "├── ${d#$PROJECT_ROOT/}/    # Laravel"; done)
$(for d in "${ACTUAL_FRONTEND_DIRS[@]+${ACTUAL_FRONTEND_DIRS[@]}}"; do echo "├── ${d#$PROJECT_ROOT/}/    # Frontend"; done)
$(for d in "${SHARED_TS_PACKAGES[@]+${SHARED_TS_PACKAGES[@]}}"; do echo "├── ${d#$PROJECT_ROOT/}/    # Shared TS package"; done)
\`\`\`

## What the Bench plugin should know

**Backend (\`/api\`, \`/controller\`, \`/model\`, etc.):**
$(for d in "${LARAVEL_DIRS[@]+${LARAVEL_DIRS[@]}}"; do echo "- Target = \`${d#$PROJECT_ROOT/}/\`. Run \`php artisan ...\` and \`composer ...\` from there, not from the repo root."; done)
$(if (( ${#LARAVEL_DIRS[@]} == 0 )); then echo "- No Laravel detected at scan time."; fi)
- Modules (nwidart/laravel-modules) live at \`{laravel-root}/Modules/{Name}/\` if used.
- TODO: confirm test framework (Pest vs PHPUnit). Tell the agents which is in use.

**Frontend (\`/vue-*\`, \`/react-*\`, \`/ui\`):**
$(for d in "${ACTUAL_FRONTEND_DIRS[@]+${ACTUAL_FRONTEND_DIRS[@]}}"; do echo "- Frontend app at \`${d#$PROJECT_ROOT/}/\`"; done)
$(if (( ${#SHARED_TS_PACKAGES[@]} > 0 )); then echo "- Shared TS packages at:"; for d in "${SHARED_TS_PACKAGES[@]}"; do echo "  - \`${d#$PROJECT_ROOT/}/\`"; done; echo "  Often the *real* place to put shared Vue components, composables, types is one of these packages — NOT inside an app's src/."; fi)
- TODO: state the rule for where shared vs app-specific code lives.
- TODO: state the UI library (if any). Default: assume none.

**Where to run commands:**
- \`pnpm ...\` from repo root (if using pnpm workspaces / Turbo / similar orchestrator)
$(for d in "${LARAVEL_DIRS[@]+${LARAVEL_DIRS[@]}}"; do echo "- \`composer ...\` and \`php artisan ...\` from \`${d#$PROJECT_ROOT/}/\`"; done)

## Conventions

- TODO: language version specifics, naming, file layout
- TODO: i18n setup, async-task helper, state lib

## Project-local extensions

Custom skills/agents/patterns specific to this project live in \`./.bench/\` and are auto-discovered by the plugin's installer. See \`.claude/plugins/Bench/docs/addons.md\` for the format.

---

> This file was scaffolded by \`bench build\`. Fill in the TODOs and expand sections as the project takes shape.
CMD_EOF
      echo ""
      echo "✓ Scaffolded $PROJECT_ROOT/CLAUDE.md — fill in the TODOs."
    fi
  fi
fi

TARGET="$PROJECT_ROOT/.claude/plugins/$PLUGIN_NAME"

echo "Installing plugin"
echo "  source:  $PLUGIN_SRC"
echo "  project: $PROJECT_ROOT"
echo "  target:  $TARGET"
echo "  mode:    $MODE"
echo ""

mkdir -p "$PROJECT_ROOT/.claude/plugins"

# ---------- Remove existing install (if any) ----------
if [[ -e "$TARGET" || -L "$TARGET" ]]; then
  echo "Removing existing install at $TARGET"
  rm -rf "$TARGET"
fi
mkdir -p "$TARGET"

# ---------- Symlink mode is for plugin development only ----------
if [[ "$MODE" == "symlink" ]]; then
  rm -rf "$TARGET"
  ln -s "$PLUGIN_SRC" "$TARGET"
  echo "✓ Symlinked $TARGET → $PLUGIN_SRC (plugin-dev mode — internals are visible)"
fi

# ---------- Run source's install.sh with --target=TARGET ----------
# install.sh mirrors only RUNTIME-ESSENTIAL files (skills/, agents/, .claude-plugin/, bin/)
# into TARGET, materializes patterns-built/, substitutes paths, and records source location
# for future rebuilds. Source internals (scripts/, raw patterns/, docs/) stay at PLUGIN_SRC.
echo ""
if [[ ${#PASSTHROUGH[@]} -gt 0 ]]; then
  echo "Running install (versions: ${PASSTHROUGH[*]})..."
  "$PLUGIN_SRC/scripts/install.sh" --auto --project="$PROJECT_ROOT" --target="$TARGET" "${PASSTHROUGH[@]}"
else
  echo "Running install (auto-detecting versions)..."
  "$PLUGIN_SRC/scripts/install.sh" --auto --project="$PROJECT_ROOT" --target="$TARGET"
fi

# ---------- Register the plugin with Claude Code ----------
# Claude Code does NOT auto-discover plugins under .claude/plugins/. The plugin
# has to be registered via a marketplace + enabledPlugins entry in
# .claude/settings.json. Two ways:
#   1. We write it to .claude/settings.json for you (deep-merges, preserves other settings)
#   2. You add it yourself from inside Claude Code:
#         /plugin marketplace add ./.claude/plugins/bench
#         /plugin install bench@pdx-apps
#
# REGISTER_MODE: ask | yes | no  (CLI flags: --register / --no-register)
SETTINGS_FILE="$PROJECT_ROOT/.claude/settings.json"

# Resolve the prompt if interactive
SHOULD_REGISTER=false
case "$REGISTER_MODE" in
  yes) SHOULD_REGISTER=true ;;
  no)  SHOULD_REGISTER=false ;;
  ask)
    echo ""
    echo "Register the bench plugin with Claude Code?"
    echo "  Writes to .claude/settings.json (deep-merge — preserves existing settings):"
    echo "    extraKnownMarketplaces.pdx-apps  → local marketplace at .claude/plugins/bench"
    echo "    enabledPlugins.bench@pdx-apps    → true"
    echo ""
    echo "  Alternative (manual): start Claude Code in this directory, then run:"
    echo "      /plugin marketplace add ./.claude/plugins/bench"
    echo "      /plugin install bench@pdx-apps"
    echo ""
    if [[ -t 0 ]]; then
      read -r -p "Auto-register now? [Y/n] " REG_ANS
      case "${REG_ANS:-y}" in
        [yY]|[yY][eE][sS]) SHOULD_REGISTER=true ;;
        *) SHOULD_REGISTER=false ;;
      esac
    else
      # Non-interactive (piped/CI): default to yes (low-friction)
      echo "(non-interactive shell — defaulting to auto-register; use --no-register to opt out)"
      SHOULD_REGISTER=true
    fi
    ;;
esac

if ! $SHOULD_REGISTER; then
  echo ""
  echo "ⓘ Skipped auto-register. To enable bench in Claude Code, run these inside CC:"
  echo "    /plugin marketplace add ./.claude/plugins/bench"
  echo "    /plugin install bench@pdx-apps"
  echo "  Or re-run init with --register."
  echo ""
fi

# Compose the bench registration as a JSON object. python3 is available everywhere on macOS.
register_bench() {
  python3 - "$SETTINGS_FILE" <<'PYEOF'
import json, os, sys

settings_path = sys.argv[1]
desired = {
    "extraKnownMarketplaces": {
        "pdx-apps": {
            "source": {
                "source": "directory",
                "path": "./.claude/plugins/bench"
            }
        }
    },
    "enabledPlugins": {
        "bench@pdx-apps": True,
    }
}

# Load existing settings if present; otherwise start fresh.
if os.path.exists(settings_path):
    with open(settings_path) as f:
        try:
            current = json.load(f)
        except json.JSONDecodeError:
            print(f"WARN: {settings_path} is not valid JSON — refusing to overwrite. Merge manually:", file=sys.stderr)
            print(json.dumps(desired, indent=2), file=sys.stderr)
            sys.exit(2)
else:
    current = {}

# Deep-merge: top-level keys we touch get merged; everything else preserved.
for top_key, top_val in desired.items():
    if top_key not in current or not isinstance(current[top_key], dict):
        current[top_key] = top_val
    else:
        for k, v in top_val.items():
            current[top_key][k] = v

with open(settings_path, "w") as f:
    json.dump(current, f, indent=2)
    f.write("\n")
print("✓ wrote")
PYEOF
}

if $SHOULD_REGISTER; then
  if command -v python3 >/dev/null 2>&1; then
    if register_bench >/dev/null 2>&1; then
      echo "✓ Registered bench plugin in $SETTINGS_FILE"
    else
      register_bench
      echo "⚠️  Failed to update settings.json automatically — see above and merge manually." >&2
    fi
  else
    cat >&2 <<EOF
⚠️  python3 not found. Add this to $SETTINGS_FILE manually:

{
  "extraKnownMarketplaces": {
    "pdx-apps": {
      "source": {
        "source": "directory",
        "path": "./.claude/plugins/bench"
      }
    }
  },
  "enabledPlugins": {
    "bench@pdx-apps": true
  }
}
EOF
  fi
fi

# ---------- Done ----------
# Compute a project-relative path for the install (more readable than absolute)
TARGET_REL=".claude/plugins/$PLUGIN_NAME"

echo ""
echo "Done. Your project is wired up:"
echo ""
echo "  Plugin installed:  $TARGET_REL/"
echo "  Source location:   $PLUGIN_SRC"
echo ""
echo "Next steps:"
echo "  • Start a new Claude Code session in this directory"
echo "    Claude Code auto-discovers the plugin — try /help inside CC to see available skills"
echo ""
echo "  • CLI tasks are rare. When you need them, invoke the plugin's bench directly:"
echo "      ./$TARGET_REL/bin/bench status"
echo "      ./$TARGET_REL/bin/bench rebuild"
echo "      ./$TARGET_REL/bin/bench addon list"
echo ""
echo "    Want a shorter command? Either (a) shell alias:"
echo "        alias bench='./$TARGET_REL/bin/bench'"
echo "    Or (b) global symlink (one time, no sudo, drops to ~/.local/bin):"
echo "        $PLUGIN_SRC/scripts/install-cli.sh"
echo ""
echo "Git considerations (your call):"
echo "  • Commit CLAUDE.md — agents read it on every invocation; team should share this"
if [[ -d "$PROJECT_ROOT/.bench" ]]; then
echo "  • Commit .bench/ — your project-local skills/agents/patterns belong with the project"
fi
echo "  • Commit $TARGET_REL/ — pins the plugin version with your code"
echo "  • Or .gitignore the install for a lighter repo:"
echo "      $TARGET_REL/"
echo "      .claude/settings.local.json"
