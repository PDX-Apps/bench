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

# Contribution composer — lets addon skill/agent files use mode: append|anchor
# (no `mode:` key → replace, the legacy behavior). See docs/layering.md.
# shellcheck source=lib/contribution.sh
source "$SCRIPT_DIR/lib/contribution.sh"

# Files that must live at the source — never copy these into a project install
SOURCE_ONLY=(scripts/ patterns/ docs/ README.md)
# Files that MUST be in the project install for runtime. Note: skills/ and agents/
# are handled separately below — source organizes them in subgroups (laravel/, vue/,
# react/, meta/) for maintainability, but the install gets them FLATTENED to depth-1
# (skills/<name>/SKILL.md, agents/<name>.md) which is what Claude Code expects.
RUNTIME_ESSENTIAL_FLAT=(.claude-plugin/ bin/)
[[ -d "$PLUGIN_SRC/hooks" ]] && RUNTIME_ESSENTIAL_FLAT+=(hooks/)
# Concern declarations (auth, test-framework, …) drive guided project setup
# (bench-init / /bench-configure). Mirror core's; addon concerns are copied below.
[[ -d "$PLUGIN_SRC/concerns" ]] && RUNTIME_ESSENTIAL_FLAT+=(concerns/)
# Groups inside skills/ and agents/ at source. Order doesn't matter; mirror walks all.
SKILL_AGENT_GROUPS=(laravel vue react meta)

# ---------- Parse our own flags ----------
EXPLICIT_ADDONS=()
EXPLICIT_VERSIONS=()
EXPLICIT_PROFILE=""
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
    --profile=*)
      EXPLICIT_PROFILE="${arg#*=}"
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
  - User project install (via 'bench build'):  --target=PROJECT/.claude/plugins/bench
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
PROFILE_CONFIG="$TARGET/.install-profile-config"
SOURCE_RECORD="$TARGET/.install-source"   # records where bench source lives, so rebuild can find it

# Skill profiles — which CORE skills get installed. Agents ALWAYS install (the
# routers spawn them), so a profile only hides skills from the user; it never
# breaks generation. The frontend prune still applies on top.
#   compact  — routers + help only (the delegation tier)
#   standard — every core skill (default)
PROFILE_COMPACT_SKILLS="bench laravel frontend help"

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

# Persisted profile resolution (same replace-or-replay rule as versions/addons):
#   - explicit --profile=X REPLACES the persisted value
#   - otherwise replay the persisted profile; default to "standard"
if [[ -n "$EXPLICIT_PROFILE" ]]; then
  PROFILE="$EXPLICIT_PROFILE"
  echo "$PROFILE" > "$PROFILE_CONFIG"
elif [[ -f "$PROFILE_CONFIG" ]]; then
  PROFILE="$(head -n1 "$PROFILE_CONFIG" | tr -d '[:space:]')"
fi
PROFILE="${PROFILE:-standard}"
case "$PROFILE" in
  compact|standard|full) ;;
  *) echo "WARNING: unknown --profile='$PROFILE' (use compact|standard|full); falling back to standard." >&2; PROFILE="standard" ;;
esac

# Auto-discover project-local addon at ${PROJECT_ROOT}/.bench/
# (always added unless --no-addon; never persisted — it travels with the project repo)
# The project-local .bench/ is THE home for project overrides/slices, so a manifest
# is OPTIONAL: discover it whenever it carries patterns/, skills/, or agents/ — so
# overrides written by the authoring agents (or by hand) are picked up without anyone
# having to remember a .bench-addon.yaml.
# Dedupe: skip if user already listed it via --addon
if ! $NO_AUTO_ADDON && [[ -d "$PROJECT_ROOT/.bench" ]] \
   && { [[ -f "$PROJECT_ROOT/.bench/.bench-addon.yaml" ]] \
        || [[ -d "$PROJECT_ROOT/.bench/patterns" ]] \
        || [[ -d "$PROJECT_ROOT/.bench/skills" ]] \
        || [[ -d "$PROJECT_ROOT/.bench/agents" ]]; }; then
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

# ---------- Expand addon dependencies (depends_on.addons) ----------
# An addon can REQUIRE other addons instead of duplicating their content (e.g. a
# quality-pipeline addon depends on bench-ci + bench-playwright). We resolve each
# addon's declared addon-deps (bundled name -> $PLUGIN_SRC/addons/NAME, or a path),
# transitively, deps-first, de-duped. Missing deps warn loudly.
addon_dep_names() {   # echo the depends_on.addons entries from a manifest
  local manifest="$1/.bench-addon.yaml"
  [[ -f "$manifest" ]] || return 0
  awk '
    /^depends_on:/ { d=1; next }
    d && /^[^[:space:]#]/ { d=0 }
    d && /addons:[[:space:]]*\[/ { l=$0; sub(/.*\[/,"",l); sub(/\].*/,"",l)
      n=split(l,a,","); for(i=1;i<=n;i++){ gsub(/[^A-Za-z0-9._\/-]/,"",a[i]); if(a[i]!="") print a[i] }; next }
    d && /addons:[[:space:]]*$/ { bl=1; next }
    d && bl && /^[[:space:]]*-/ { l=$0; sub(/^[[:space:]]*-[[:space:]]*/,"",l); gsub(/[^A-Za-z0-9._\/-]/,"",l); if(l!="") print l; next }
    d && bl && /^[[:space:]]*[^-[:space:]#]/ { bl=0 }
  ' "$manifest"
}
resolve_addon_dep() {   # name-or-path -> absolute addon dir, or empty. Always returns 0 (set -e safe).
  local a="$1" m nm
  # 1. a literal path
  if [[ -d "$a" && -f "$a/.bench-addon.yaml" ]]; then (cd "$a" && pwd); return 0; fi
  # 2. a bundled addon by directory name
  if [[ -d "$PLUGIN_SRC/addons/$a" && -f "$PLUGIN_SRC/addons/$a/.bench-addon.yaml" ]]; then echo "$PLUGIN_SRC/addons/$a"; return 0; fi
  # 3. a bundled addon by manifest name: (dir name may differ, e.g. laravel-ci → name bench-ci)
  for m in "$PLUGIN_SRC"/addons/*/.bench-addon.yaml; do
    [[ -f "$m" ]] || continue
    nm=$(grep -E '^name:' "$m" | head -1 | sed -E 's/^name:[[:space:]]*//; s/[[:space:]]+$//')
    if [[ "$nm" == "$a" ]]; then dirname "$m"; return 0; fi
  done
  return 0
}
_addons_has() { local x="$1" a; for a in "${ADDONS[@]+${ADDONS[@]}}"; do [[ "$a" == "$x" ]] && return 0; done; return 1; }

# ---------- Rendering mode -> page-ownership addon ----------
# A project declares its rendering model in .bench/rendering.yaml (written by the
# `rendering` concern). We map the mode to the addon that owns page rendering and fold it
# into ADDONS here — BEFORE dependency expansion, so the mapped addon's own deps resolve.
# Consistent with concerns-produce-config / build-reacts: the concern never runs `addon add`.
RENDERING_YAML="$PROJECT_ROOT/.bench/rendering.yaml"
if [[ -f "$RENDERING_YAML" ]]; then
  rmode=$(grep -E '^mode:' "$RENDERING_YAML" | head -1 | sed -E 's/^mode:[[:space:]]*//; s/[[:space:]#].*$//')
  case "$rmode" in
    blade)    rmode_addon="laravel-blade" ;;
    inertia)  rmode_addon="inertia" ;;
    livewire) rmode_addon="livewire" ;;   # livewire depends_on laravel-blade (pulled transitively)
    spa|"")   rmode_addon="" ;;
    *) echo "WARNING: .bench/rendering.yaml mode '$rmode' unknown; expected spa|blade|inertia|livewire" >&2; rmode_addon="" ;;
  esac
  if [[ -n "$rmode_addon" ]]; then
    rmode_path="$(resolve_addon_dep "$rmode_addon")"
    if [[ -z "$rmode_path" ]]; then
      echo "WARNING: rendering mode '$rmode' needs addon '$rmode_addon' — not found in $PLUGIN_SRC/addons" >&2
    elif ! _addons_has "$rmode_path"; then
      ADDONS+=("$rmode_path")
      echo "  + rendering mode '$rmode' -> addon $rmode_addon"
    fi
  fi
fi

_expand=1
while (( _expand )); do
  _expand=0
  for a in "${ADDONS[@]+${ADDONS[@]}}"; do
    while IFS= read -r dep; do
      [[ -z "$dep" ]] && continue
      deppath="$(resolve_addon_dep "$dep")"
      if [[ -z "$deppath" ]]; then
        echo "WARNING: addon '$(basename "$a")' requires addon '$dep' — not found; install it or generation may be incomplete" >&2
        continue
      fi
      if ! _addons_has "$deppath"; then
        ADDONS=("$deppath" "${ADDONS[@]}")   # deps load before dependents
        echo "  + addon dependency: $dep (required by $(basename "$a"))"
        _expand=1
      fi
    done < <(addon_dep_names "$a")
  done
done

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
#
# Two mirror passes:
#   1. Flat essentials (.claude-plugin/, bin/, hooks/) — straight rsync.
#   2. Skills + agents — source is grouped (skills/laravel/, skills/vue/, ...);
#      install is FLAT (skills/<name>/, agents/<name>.md). We walk each group at
#      source and rsync each entry to the flat install path.
if [[ "$PLUGIN_SRC" != "$PLUGIN_ROOT" ]]; then
  echo "Mirroring runtime essentials from source → install:"
  echo "  source:   $PLUGIN_SRC"
  echo "  install:  $PLUGIN_ROOT"

  # Pass 1 — flat essentials
  for item in "${RUNTIME_ESSENTIAL_FLAT[@]}"; do
    if [[ -e "$PLUGIN_SRC/$item" ]]; then
      mkdir -p "$PLUGIN_ROOT/$(dirname "$item")" 2>/dev/null || true
      rsync -a --delete "$PLUGIN_SRC/$item" "$PLUGIN_ROOT/$item"
    fi
  done

  # Generate the directory-marketplace manifest INTO the built copy so Claude Code
  # can load it as a project-local marketplace (bench build registers this dir as a
  # marketplace; CC reads this file to find the plugin). It is deliberately NOT
  # shipped in the source repo: a source marketplace.json lets someone
  # `/plugin marketplace add <repo>` and install the UNBUILT, version-agnostic repo
  # (no resolved patterns-built/, no overrides, no addons) — wrong, because bench is
  # built per-project. This file only exists in a real, built install.
  mkdir -p "$PLUGIN_ROOT/.claude-plugin"
  PLUGIN_VERSION=$(grep -E '"version"' "$PLUGIN_SRC/.claude-plugin/plugin.json" 2>/dev/null | head -1 | sed -E 's/.*"version"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/')
  cat > "$PLUGIN_ROOT/.claude-plugin/marketplace.json" <<EOF
{
  "name": "pdx-apps",
  "owner": { "name": "PDX Apps", "url": "https://pdxapps.com" },
  "plugins": [
    {
      "name": "bench",
      "version": "${PLUGIN_VERSION:-0.0.0}",
      "description": "Bench, built for THIS project (resolved patterns + overrides + addons). Installed via 'bench build' — do not install the source repo directly.",
      "source": "./"
    }
  ]
}
EOF

  # Pass 2 — skills + agents (flatten groups from source). Wipe destination first
  # so renames/removals at source propagate; addon copies happen later and re-add.
  rm -rf "$PLUGIN_ROOT/skills" "$PLUGIN_ROOT/agents"
  mkdir -p "$PLUGIN_ROOT/skills" "$PLUGIN_ROOT/agents"
  for group in "${SKILL_AGENT_GROUPS[@]}"; do
    if [[ -d "$PLUGIN_SRC/skills/$group" ]]; then
      while IFS= read -r -d '' skill_dir; do
        name=$(basename "$skill_dir")
        # compact profile: install only the router/help tier; agents still ship below
        if [[ "$PROFILE" == "compact" ]] && [[ " $PROFILE_COMPACT_SKILLS " != *" $name "* ]]; then
          continue
        fi
        rsync -a "$skill_dir/" "$PLUGIN_ROOT/skills/$name/"
      done < <(find "$PLUGIN_SRC/skills/$group" -mindepth 1 -maxdepth 1 -type d -print0)
    fi
    if [[ -d "$PLUGIN_SRC/agents/$group" ]]; then
      while IFS= read -r -d '' agent_file; do
        name=$(basename "$agent_file")
        cp "$agent_file" "$PLUGIN_ROOT/agents/$name"
      done < <(find "$PLUGIN_SRC/agents/$group" -mindepth 1 -maxdepth 1 -type f -name '*.md' -print0)
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
      addon_name=$(grep -E '^name:' "$addon/.bench-addon.yaml" | head -1 | sed -E 's/^name:[[:space:]]*//; s/[[:space:]]+$//')
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
          a_mode="$(contrib_frontmatter_get "$f" mode)"; [[ -z "$a_mode" ]] && a_mode="replace"
          if [[ -f "$target" ]]; then
            # Back up the core file before we modify/overwrite it (so reversal restores it)
            backup_path="$ADDON_BACKUP_DIR/skills/$skill_name/$rel"
            mkdir -p "$(dirname "$backup_path")"
            cp "$target" "$backup_path"
            contrib_apply "$target" "$f"
          else
            # No core file to layer onto — write the contribution body as a new file
            mkdir -p "$(dirname "$target")"
            if [[ "$a_mode" == "replace" ]]; then cp "$f" "$target"; else contrib_body "$f" > "$target"; fi
          fi
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
        a_mode="$(contrib_frontmatter_get "$f" mode)"; [[ -z "$a_mode" ]] && a_mode="replace"
        if [[ -f "$dest" ]]; then
          # Back up the core agent before modify/overwrite (so reversal restores it)
          backup_path="$ADDON_BACKUP_DIR/agents/$agent_name"
          mkdir -p "$(dirname "$backup_path")"
          cp "$dest" "$backup_path"
          contrib_apply "$dest" "$f"
        else
          if [[ "$a_mode" == "replace" ]]; then cp "$f" "$dest"; else contrib_body "$f" > "$dest"; fi
        fi
        echo "$dest" >> "$ADDON_RECORD"
        copied=$((copied + 1))
      done < <(find "$addon/agents" -maxdepth 1 -type f -name "*.md" -print0)
    fi

    # Copy concerns/*.md (flat) — declarations that drive guided setup
    if [[ -d "$addon/concerns" ]]; then
      mkdir -p "$PLUGIN_ROOT/concerns"
      while IFS= read -r -d '' f; do
        dest="$PLUGIN_ROOT/concerns/$(basename "$f")"
        cp "$f" "$dest"
        echo "$dest" >> "$ADDON_RECORD"
        copied=$((copied + 1))
      done < <(find "$addon/concerns" -maxdepth 1 -type f -name "*.md" -print0)
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

# Bake the chosen frontend into the skill/agent files (the <BENCH_FRONTEND>
# placeholder), so the /frontend router knows the framework constant-time instead
# of re-detecting it from package.json on every invocation. Set at bench build.
BENCH_FRONTEND="none"
$HAS_VUE_PATTERNS   && BENCH_FRONTEND="vue"
$HAS_REACT_PATTERNS && BENCH_FRONTEND="react"
for dir in "${SUBSTITUTE_TARGETS[@]}"; do
  if [[ -d "$dir" ]]; then
    while IFS= read -r -d '' f; do
      grep -q "<BENCH_FRONTEND>" "$f" && sed -i '' "s|<BENCH_FRONTEND>|$BENCH_FRONTEND|g" "$f"
    done < <(find "$dir" -name "*.md" -print0)
  fi
done

prune_count=0
# Pruning derives names from the SOURCE group dir, not a hardcoded list — so adding
# a new vue-*/react-* skill in source doesn't require also touching this file.
prune_group() {
  local group="$1"
  if [[ -d "$PLUGIN_SRC/skills/$group" ]]; then
    while IFS= read -r -d '' skill_dir; do
      name=$(basename "$skill_dir")
      if [[ -d "$PLUGIN_ROOT/skills/$name" ]]; then
        rm -rf "$PLUGIN_ROOT/skills/$name"
        prune_count=$((prune_count + 1))
      fi
    done < <(find "$PLUGIN_SRC/skills/$group" -mindepth 1 -maxdepth 1 -type d -print0)
  fi
  if [[ -d "$PLUGIN_SRC/agents/$group" ]]; then
    while IFS= read -r -d '' agent_file; do
      name=$(basename "$agent_file")
      if [[ -f "$PLUGIN_ROOT/agents/$name" ]]; then
        rm -f "$PLUGIN_ROOT/agents/$name"
        prune_count=$((prune_count + 1))
      fi
    done < <(find "$PLUGIN_SRC/agents/$group" -mindepth 1 -maxdepth 1 -type f -name '*.md' -print0)
  fi
}

$HAS_VUE_PATTERNS   || prune_group vue
$HAS_REACT_PATTERNS || prune_group react

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
