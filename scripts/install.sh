#!/usr/bin/env bash
# install.sh — build/materialize the Bench plugin into a target install directory.
#
# This script runs at the BENCH SOURCE location (where it lives, alongside the
# raw patterns/ and bin/bench) and writes runtime artifacts (skills/, agents/,
# patterns-built/, plugin.json, bin/bench, install records) into a TARGET
# directory. The TARGET is typically project/.claude/plugins/bench/, but
# defaults to PLUGIN_ROOT for backward compatibility (build "in place").
#
# What it does:
#   1. Removes addon contributions from a previous install at TARGET
#   2. Mirrors only RUNTIME-ESSENTIAL files from source → TARGET (skills/, agents/,
#      .claude-plugin/, bin/bench). Internals (scripts/, raw patterns/, docs/,
#      README, docs/) stay at source.
#   3. Substitutes <PLUGIN_ROOT> with TARGET path in TARGET's agent/skill files
#   4. For each --addon, copies its skills/+agents/ into TARGET (with substitution)
#   5. Materializes patterns-built/ into TARGET/patterns-built (resolves core base
#      + version overrides + addon contributions)
#   6. Records source location in TARGET/.install-source so rebuild can find it
#
# Re-running this script is safe — .install-record + .install-addons drive the
# reversal of prior state before applying the new one.
#
# Usage:
#   ./scripts/install.sh                                          # build at PLUGIN_ROOT (legacy/source mode)
#   ./scripts/install.sh --target=/path/to/project/.claude/plugins/bench  # write runtime artifacts here
#   ./scripts/install.sh --project=/path/to/laravel-project       # project root (for monorepo scan etc.)
#   ./scripts/install.sh --laravel=13 --php=8.5                   # explicit versions
#   ./scripts/install.sh --addon=/path/to/your-addon         # load an addon (repeatable)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_SRC="$(dirname "$SCRIPT_DIR")"   # where the bench source lives — patterns/, scripts/, bin/, etc.

# Files that must live at the source — never copy these into a project install
SOURCE_ONLY=(scripts/ patterns/ docs/ README.md)
# Files that MUST be in the project install for runtime
RUNTIME_ESSENTIAL=(.claude-plugin/ skills/ agents/ bin/)
[[ -d "$PLUGIN_SRC/hooks" ]] && RUNTIME_ESSENTIAL+=(hooks/)

# ---------- Parse our own flags ----------
EXPLICIT_ADDONS=()
EXPLICIT_VERSIONS=()
PASSTHROUGH=()
PROJECT_ROOT=""
TARGET=""
NO_AUTO_ADDON=false
for arg in "$@"; do
  case "$arg" in
    --addon=*)
      EXPLICIT_ADDONS+=("${arg#*=}")
      ;;
    --no-addon)
      NO_AUTO_ADDON=true
      ;;
    --laravel=*|--php=*|--vue=*|--frontend=*)
      EXPLICIT_VERSIONS+=("$arg")
      PASSTHROUGH+=("$arg")
      ;;
    --project=*)
      PROJECT_ROOT="${arg#*=}"
      PASSTHROUGH+=("$arg")
      ;;
    --target=*)
      TARGET="${arg#*=}"
      ;;
    *)
      PASSTHROUGH+=("$arg")
      ;;
  esac
done
PROJECT_ROOT="${PROJECT_ROOT:-$PWD}"
# REQUIRE --target. Refusing to install "in place" at the source location
# prevents the source repo from being polluted with absolute /Users/... paths
# (which then leak into commits). Plugin development should always target a
# scratch directory like /tmp/bench-test or a real project's .claude/plugins/.
if [[ -z "$TARGET" ]]; then
  cat >&2 <<EOF
ERROR: --target=PATH is required.

This script writes runtime artifacts (with absolute paths substituted) into
TARGET. Installing "in place" at the bench source would pollute the repo
with your machine's absolute paths.

Typical use:
  - User project install (via 'bench init'):  --target=PROJECT/.claude/plugins/bench
  - Plugin dev / testing:                     --target=/tmp/bench-test
EOF
  exit 1
fi

# Per-target state files (records persist with each install separately)
RECORD="$TARGET/.install-record"
ADDON_RECORD="$TARGET/.install-addons"
ADDON_BACKUP_DIR="$TARGET/.install-addons-backup"
ADDON_CONFIG="$TARGET/.install-addons-config"
VERSIONS_CONFIG="$TARGET/.install-versions-config"
SOURCE_RECORD="$TARGET/.install-source"   # records where bench source lives, so rebuild can find it

# Treat TARGET as PLUGIN_ROOT for the rest of the script — substitution/install logic
# operates on TARGET's files. PLUGIN_SRC stays as the source-of-truth for patterns/.
PLUGIN_ROOT="$TARGET"
mkdir -p "$TARGET"

# Persisted version-flag resolution:
#   - If --laravel/--php/--frontend/--vue passed explicitly, those REPLACE persisted config
#   - Otherwise, replay persisted versions (so rebuilds don't lose monorepo-detected versions)
if (( ${#EXPLICIT_VERSIONS[@]} > 0 )); then
  printf '%s\n' "${EXPLICIT_VERSIONS[@]}" > "$VERSIONS_CONFIG"
elif [[ -f "$VERSIONS_CONFIG" ]]; then
  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    PASSTHROUGH+=("$line")
  done < "$VERSIONS_CONFIG"
fi

# Persisted addon resolution:
#   - If --addon flags were passed explicitly, they REPLACE the persisted config
#     (write the new set, then use it).
#   - Otherwise, read the persisted config from a previous install.
ADDONS=()
if (( ${#EXPLICIT_ADDONS[@]} > 0 )); then
  ADDONS=("${EXPLICIT_ADDONS[@]}")
  printf '%s\n' "${ADDONS[@]}" > "$ADDON_CONFIG"
elif [[ -f "$ADDON_CONFIG" ]]; then
  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    ADDONS+=("$line")
  done < "$ADDON_CONFIG"
fi

# Auto-discover project-local addon at ${PROJECT_ROOT}/.bench/
# (always added unless --no-addon; never persisted — it travels with the project repo)
# Dedupe: skip if user already listed it via --addon
if ! $NO_AUTO_ADDON && [[ -d "$PROJECT_ROOT/.bench" && -f "$PROJECT_ROOT/.bench/.bench-addon.yaml" ]]; then
  already_listed=false
  for a in "${ADDONS[@]+${ADDONS[@]}}"; do
    if [[ "$a" == "$PROJECT_ROOT/.bench" ]]; then
      already_listed=true
      break
    fi
  done
  if ! $already_listed; then
    ADDONS+=("$PROJECT_ROOT/.bench")
  fi
fi

# Files to substitute paths in (core only — addon files are handled per-addon below)
SUBSTITUTE_TARGETS=(
  "$PLUGIN_ROOT/agents"
  "$PLUGIN_ROOT/skills"
)
SUBSTITUTE_DOCS=()
# Only substitute docs/architecture.md if it actually lives at target (legacy "install at source" mode)
[[ -f "$PLUGIN_ROOT/docs/architecture.md" ]] && SUBSTITUTE_DOCS+=("$PLUGIN_ROOT/docs/architecture.md")

# ---------- Mirror runtime essentials from PLUGIN_SRC to TARGET (if separate) ----------
# This is the key DX-10 change: only ship what's needed at runtime, never internals.
# Skipped when running "in place" at source (TARGET == PLUGIN_SRC).
if [[ "$PLUGIN_SRC" != "$PLUGIN_ROOT" ]]; then
  echo "Mirroring runtime essentials from source → install:"
  echo "  source:   $PLUGIN_SRC"
  echo "  install:  $PLUGIN_ROOT"
  for item in "${RUNTIME_ESSENTIAL[@]}"; do
    if [[ -e "$PLUGIN_SRC/$item" ]]; then
      mkdir -p "$PLUGIN_ROOT/$(dirname "$item")" 2>/dev/null || true
      rsync -a --delete "$PLUGIN_SRC/$item" "$PLUGIN_ROOT/$item"
    fi
  done
  echo "  (source internals NOT copied: ${SOURCE_ONLY[*]})"
  # Record source location so `bench rebuild` from the install can find it
  echo "$PLUGIN_SRC" > "$SOURCE_RECORD"
fi

# ---------- Reverse previous addon install: remove copied files, restore backups ----------
if [[ -f "$ADDON_RECORD" ]]; then
  echo "Reversing previous addon install..."
  removed=0
  while IFS= read -r path; do
    [[ -z "$path" ]] && continue
    if [[ -f "$path" ]]; then
      rm -f "$path"
      removed=$((removed + 1))
    fi
  done < "$ADDON_RECORD"
  echo "  Removed $removed addon-copied file(s)."
  rm -f "$ADDON_RECORD"
fi
# Restore any core files that addons overwrote
if [[ -d "$ADDON_BACKUP_DIR" ]]; then
  restored=0
  while IFS= read -r -d '' backup; do
    rel="${backup#$ADDON_BACKUP_DIR/}"
    target="$PLUGIN_ROOT/$rel"
    mkdir -p "$(dirname "$target")"
    mv "$backup" "$target"
    restored=$((restored + 1))
  done < <(find "$ADDON_BACKUP_DIR" -type f -print0)
  echo "  Restored $restored core file(s) that addons had overwritten."
  rm -rf "$ADDON_BACKUP_DIR"
fi
# Clean empty skill directories left behind when addon-only skills were removed
find "$PLUGIN_ROOT/skills" -mindepth 1 -type d -empty -delete 2>/dev/null || true

# ---------- Reverse previous substitution (robust) ----------
# Reverse ANY embedded absolute path that ends in `/patterns-built/` back to
# <PLUGIN_ROOT>. This catches:
#   - the path recorded in .install-record (the standard happy path)
#   - paths embedded from a DIFFERENT install (e.g., source workspace got
#     substituted, then rsync'd into a project copy — common when developing
#     the plugin and testing against projects)
# The pattern `[^"` ]+/patterns-built/` is unambiguous: patterns-built is plugin-internal
# and never appears in real code, so any absolute path ending in it is a substitution
# artifact that should be reversed.
#
# After reversal the forward substitution step (below) replaces the canonical
# <PLUGIN_ROOT> placeholder with the actual install path.
reverse_substitutions_in_file() {
  local f="$1"
  # Match: any string starting with `/` (absolute path), containing non-space/non-quote
  # characters, ending with `/patterns-built` (the canonical plugin-internal marker).
  # Replace with `<PLUGIN_ROOT>/patterns-built`.
  sed -i '' -E 's|/[^[:space:]"`]+/patterns-built|<PLUGIN_ROOT>/patterns-built|g' "$f"
}

for dir in "${SUBSTITUTE_TARGETS[@]}"; do
  if [[ -d "$dir" ]]; then
    while IFS= read -r -d '' f; do
      reverse_substitutions_in_file "$f"
    done < <(find "$dir" -name "*.md" -print0)
  fi
done
for f in "${SUBSTITUTE_DOCS[@]+${SUBSTITUTE_DOCS[@]}}"; do
  [[ -f "$f" ]] && reverse_substitutions_in_file "$f"
done

# Report if we picked up after a different install (informational only)
if [[ -f "$RECORD" ]]; then
  PREVIOUS_ROOT=$(cat "$RECORD")
  if [[ "$PREVIOUS_ROOT" != "$PLUGIN_ROOT" ]]; then
    echo "Plugin moved: $PREVIOUS_ROOT → $PLUGIN_ROOT"
  fi
fi

# ---------- Copy addon skills/agents into the install ----------
# Each addon's skills/<name>/ and agents/*.md are copied flat into the install's
# skills/ and agents/ directories. Addons win on same-name (later --addon wins).
# Every copied destination path is recorded in .install-addons for next reversal.
if (( ${#ADDONS[@]} > 0 )); then
  echo ""
  echo "Copying skills/agents from ${#ADDONS[@]} addon(s):"
  : > "$ADDON_RECORD"  # truncate

  for addon in "${ADDONS[@]}"; do
    if [[ ! -d "$addon" ]]; then
      echo "  WARNING: addon path not found: $addon" >&2
      continue
    fi

    addon_name=""
    if [[ -f "$addon/.bench-addon.yaml" ]]; then
      addon_name=$(grep -E '^name:' "$addon/.bench-addon.yaml" | head -1 | sed -E 's/^name:\s*//; s/[[:space:]]+$//')
    fi
    [[ -z "$addon_name" ]] && addon_name="$(basename "$addon")"

    copied=0

    # Copy skills/<skill-name>/ subdirectories
    if [[ -d "$addon/skills" ]]; then
      while IFS= read -r -d '' skill_dir; do
        skill_name="$(basename "$skill_dir")"
        dest="$PLUGIN_ROOT/skills/$skill_name"
        # Track every file we copy (for reversal); back up core file if overwriting
        while IFS= read -r -d '' f; do
          rel="${f#$skill_dir/}"
          target="$dest/$rel"
          if [[ -f "$target" ]]; then
            # Back up the core file we're about to overwrite
            backup_path="$ADDON_BACKUP_DIR/skills/$skill_name/$rel"
            mkdir -p "$(dirname "$backup_path")"
            cp "$target" "$backup_path"
          fi
          mkdir -p "$(dirname "$target")"
          cp "$f" "$target"
          echo "$target" >> "$ADDON_RECORD"
          copied=$((copied + 1))
        done < <(find "$skill_dir" -type f -print0)
      done < <(find "$addon/skills" -mindepth 1 -maxdepth 1 -type d -print0)
    fi

    # Copy agents/*.md files (flat)
    if [[ -d "$addon/agents" ]]; then
      while IFS= read -r -d '' f; do
        agent_name="$(basename "$f")"
        dest="$PLUGIN_ROOT/agents/$agent_name"
        if [[ -f "$dest" ]]; then
          # Back up the core agent we're about to overwrite
          backup_path="$ADDON_BACKUP_DIR/agents/$agent_name"
          mkdir -p "$(dirname "$backup_path")"
          cp "$dest" "$backup_path"
        fi
        cp "$f" "$dest"
        echo "$dest" >> "$ADDON_RECORD"
        copied=$((copied + 1))
      done < <(find "$addon/agents" -maxdepth 1 -type f -name "*.md" -print0)
    fi

    echo "  $addon_name: copied $copied file(s) from $addon"
  done
fi

# ---------- Substitute placeholder for current install location ----------
echo ""
echo "Installing plugin at: $PLUGIN_ROOT"

substitution_count=0
for dir in "${SUBSTITUTE_TARGETS[@]}"; do
  if [[ -d "$dir" ]]; then
    while IFS= read -r -d '' f; do
      if grep -q "<PLUGIN_ROOT>" "$f"; then
        sed -i '' "s|<PLUGIN_ROOT>|$PLUGIN_ROOT|g" "$f"
        substitution_count=$((substitution_count + 1))
      fi
    done < <(find "$dir" -name "*.md" -print0)
  fi
done
for f in "${SUBSTITUTE_DOCS[@]+${SUBSTITUTE_DOCS[@]}}"; do
  if [[ -f "$f" ]] && grep -q "<PLUGIN_ROOT>" "$f"; then
    sed -i '' "s|<PLUGIN_ROOT>|$PLUGIN_ROOT|g" "$f"
    substitution_count=$((substitution_count + 1))
  fi
done

echo "  Substituted paths in $substitution_count file(s)."

# Record install location for next reverse pass
echo "$PLUGIN_ROOT" > "$RECORD"

# ---------- Build patterns ----------
# build-patterns.sh always reads raw patterns from PLUGIN_SRC/patterns/ (the source),
# and writes resolved output to PLUGIN_ROOT/patterns-built/ (the target install).
# This split is what lets us keep raw patterns/ at source and only ship the resolved
# materialized form to user projects.
ADDON_ARGS=()
if (( ${#ADDONS[@]} > 0 )); then
  for addon in "${ADDONS[@]}"; do
    ADDON_ARGS+=("--addon=$addon")
  done
fi

echo ""
"$SCRIPT_DIR/build-patterns.sh" \
  --source="$PLUGIN_SRC" \
  --output="$PLUGIN_ROOT/patterns-built" \
  "${PASSTHROUGH[@]+${PASSTHROUGH[@]}}" \
  "${ADDON_ARGS[@]+${ADDON_ARGS[@]}}"

# ---------- Prune skills/agents for the unused frontend ----------
# A Vue project doesn't need /react-* slash commands cluttering CC; a React
# project doesn't need /vue-*. The /ui multi-artifact coordinator is Vue-flavored
# today, so it's pruned for React projects too (known gap — react-ui agent exists
# but no corresponding skill yet).
#
# Detection: whichever subdir under patterns-built/frontend/ has content is the
# active frontend. If neither has content, frontend=none (backend-only project).
HAS_VUE_PATTERNS=false
HAS_REACT_PATTERNS=false
if [[ -d "$PLUGIN_ROOT/patterns-built/frontend/vue" ]] && \
   compgen -G "$PLUGIN_ROOT/patterns-built/frontend/vue/*" > /dev/null; then
  HAS_VUE_PATTERNS=true
fi
if [[ -d "$PLUGIN_ROOT/patterns-built/frontend/react" ]] && \
   compgen -G "$PLUGIN_ROOT/patterns-built/frontend/react/*" > /dev/null; then
  HAS_REACT_PATTERNS=true
fi

prune_count=0
prune_skill() {
  local name="$1"
  if [[ -d "$PLUGIN_ROOT/skills/$name" ]]; then
    rm -rf "$PLUGIN_ROOT/skills/$name"
    prune_count=$((prune_count + 1))
  fi
}
prune_agent() {
  local name="$1"
  if [[ -f "$PLUGIN_ROOT/agents/$name.md" ]]; then
    rm -f "$PLUGIN_ROOT/agents/$name.md"
    prune_count=$((prune_count + 1))
  fi
}

prune_vue_set() {
  for name in vue-component vue-composable vue-i18n vue-layout vue-model vue-page \
              vue-route vue-service vue-store vue-test vue-validator; do
    prune_skill "$name"
    prune_agent "$name"
  done
  # vue-only agents (no skill of same name)
  for name in vue-bug-fix vue-exec-spec vue-new-module vue-refactor vue-update-spec; do
    prune_agent "$name"
  done
  # /ui multi-artifact coordinator is Vue-flavored today
  prune_skill "ui"
  prune_agent "ui"
}

prune_react_set() {
  for name in react-component react-hook react-i18n react-layout react-model \
              react-page react-route react-service react-store react-test \
              react-validator; do
    prune_skill "$name"
    prune_agent "$name"
  done
  # react-only agents (no skill of same name)
  for name in react-bug-fix react-exec-spec react-new-module react-refactor \
              react-ui react-update-spec; do
    prune_agent "$name"
  done
}

if ! $HAS_VUE_PATTERNS; then
  prune_vue_set
fi
if ! $HAS_REACT_PATTERNS; then
  prune_react_set
fi

if (( prune_count > 0 )); then
  active_frontends=""
  $HAS_VUE_PATTERNS && active_frontends+="vue "
  $HAS_REACT_PATTERNS && active_frontends+="react "
  active_frontends="${active_frontends:-none}"
  echo ""
  echo "Pruned $prune_count skill/agent file(s) for unused frontend(s) (active: ${active_frontends% })"
fi

# Tail message intentionally minimal — init-project.sh prints the user-facing
# next-steps with project-relative paths.
