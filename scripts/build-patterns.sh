#!/usr/bin/env bash
# build-patterns.sh — resolve base + overrides into patterns-built/
#
# Per-file precedence (most specific wins):
#   Laravel side:
#     1. overrides/laravel-{L}+php-{P}/{file}
#     2. overrides/laravel-{L}/{file}
#     3. overrides/php-{P}/{file}
#     4. base/{file}
#   Frontend side (patterns/frontend/{vue,react}/):
#     1. overrides/vue-{V}/{file}     (when --frontend=vue)
#     2. base/{file}
#
# UI library and homegrown-frameworkpatterns are
# delivered as separate addon plugins, not as override axes here.
#
# Usage:
#   ./build-patterns.sh --auto                        # detect from project (defaults to PWD)
#   ./build-patterns.sh --auto --project=/path/to/proj
#   ./build-patterns.sh --laravel=12 --php=8.4
#   ./build-patterns.sh --laravel-only --laravel=13 --php=8.5
#   ./build-patterns.sh --frontend-only --frontend=vue --vue=3
#   ./build-patterns.sh --frontend=react              # build React side instead
#   ./build-patterns.sh --frontend=none               # backend-only (no frontend build)
#   ./build-patterns.sh --addon=/path/to/your-addon
#   ./build-patterns.sh --addon=A --addon=B           # multiple addons, later wins
#
# Addons (see docs/addons.md):
#   After core's resolve pass, each --addon=PATH walks its patterns/ tree and
#   merges files into patterns-built/ (addon wins on collision). Project-local
#   extensions at ${PROJECT_ROOT}/.bench/ are auto-discovered.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_SRC_DEFAULT="$(dirname "$SCRIPT_DIR")"   # where this script lives (the bench source)

AUTO=false
PROJECT_ROOT="$PWD"
LARAVEL=""
PHP=""
VUE=""
FRONTEND=""        # vue | react | none (auto-detect default: vue if package.json has vue, none otherwise)
SIDE_FILTER=""
ADDONS=()          # array of addon directory paths, in declaration order (later wins)
NO_AUTO_ADDON=false  # set by --no-addon to skip ./.bench/ auto-discovery
PATTERN_SOURCE=""    # where to read patterns from (default: bench source)
OUTPUT_DIR=""        # where to write patterns-built/ (default: PATTERN_SOURCE/patterns-built)

while [[ $# -gt 0 ]]; do
  case "$1" in
    --auto) AUTO=true; shift ;;
    --project=*) PROJECT_ROOT="${1#*=}"; shift ;;
    --laravel=*) LARAVEL="${1#*=}"; shift ;;
    --php=*) PHP="${1#*=}"; shift ;;
    --vue=*) VUE="${1#*=}"; shift ;;
    --frontend=*) FRONTEND="${1#*=}"; shift ;;
    --addon=*) ADDONS+=("${1#*=}"); shift ;;
    --no-addon) NO_AUTO_ADDON=true; shift ;;
    --source=*) PATTERN_SOURCE="${1#*=}"; shift ;;
    --output=*) OUTPUT_DIR="${1#*=}"; shift ;;
    # Accept-and-ignore: --quasar / --quvel used to be override axes but are
    # now delivered as separate addon plugins. Tolerate the flags so existing
    # automation doesn't break — print a deprecation note instead.
    --quasar=*|--quvel=*)
      echo "  note: $1 is deprecated — UI library / framework patterns now ship as addon plugins, ignoring" >&2
      shift ;;
    --laravel-only) SIDE_FILTER="laravel"; shift ;;
    --vue-only|--frontend-only) SIDE_FILTER="frontend"; shift ;;
    -h|--help)
      grep -E '^#( |$)' "${BASH_SOURCE[0]}" | sed 's/^# //; s/^#//'
      exit 0 ;;
    "") shift ;;   # tolerate empty positional from "${arr[@]+...}" expansions
    *) echo "Unknown argument: $1" >&2; exit 1 ;;
  esac
done

# Default source = where this script lives (legacy in-place build), output = source/patterns-built
PATTERN_SOURCE="${PATTERN_SOURCE:-$PLUGIN_SRC_DEFAULT}"
OUTPUT_DIR="${OUTPUT_DIR:-$PATTERN_SOURCE/patterns-built}"

# Auto-discover project-local extensions at ${PROJECT_ROOT}/.bench/
# (skip if --no-addon, or if it was already passed via --addon)
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

# ---------- Auto-detect ----------
parse_constraint() {
  # Strip ^ ~ >= and other constraint operators, capture the major (or major.minor)
  local val="$1"
  local pattern="$2"
  echo "$val" | sed -E "s/.*\"$pattern\":\s*\"[\^~>=<]*([0-9]+(\.[0-9]+)?)[^\"]*\".*/\1/" | head -1
}

PACKAGE_JSON_SEEN=false
if $AUTO; then
  composer_json="$PROJECT_ROOT/composer.json"
  if [[ -f "$composer_json" ]]; then
    if [[ -z "$LARAVEL" ]]; then
      LARAVEL=$(grep -E '"laravel/framework"' "$composer_json" | head -1 \
        | sed -E 's/.*"\^?~?>?=?<?([0-9]+)\..*/\1/' || true)
    fi
    if [[ -z "$PHP" ]]; then
      # Major.minor for PHP (e.g. 8.4)
      PHP=$(grep -E '^\s*"php"' "$composer_json" | head -1 \
        | sed -E 's/.*"\^?~?>?=?<?([0-9]+\.[0-9]+).*/\1/' || true)
    fi
  fi

  for pkg in "$PROJECT_ROOT/package.json" "$PROJECT_ROOT/frontend/package.json"; do
    [[ -f "$pkg" ]] || continue
    PACKAGE_JSON_SEEN=true
    [[ -z "$VUE" ]] && VUE=$(grep -E '^\s*"vue":' "$pkg" | head -1 | sed -E 's/.*"\^?~?([0-9]+)\..*/\1/' || true)
    if [[ -z "$FRONTEND" ]]; then
      if grep -qE '^\s*"vue":' "$pkg"; then
        FRONTEND="vue"
      elif grep -qE '^\s*"react":' "$pkg"; then
        FRONTEND="react"
      fi
    fi
  done

  # If we scanned but found no Vue/React, OR if there's no package.json at all,
  # default to none — building the wrong frontend's patterns is worse than building zero.
  if [[ -z "$FRONTEND" ]]; then
    FRONTEND="none"
  fi
fi

# ---------- Defaults (match base _meta.yaml — latest stable) ----------
LARAVEL="${LARAVEL:-13}"
PHP="${PHP:-8.5}"
VUE="${VUE:-3}"
# When not in --auto mode and no --frontend passed, default to vue (back-compat
# with manual flag-driven invocations).
FRONTEND="${FRONTEND:-vue}"

cat <<EOF
build-patterns: resolving overrides
  source:   $PATTERN_SOURCE
  output:   $OUTPUT_DIR
  project:  $PROJECT_ROOT
  Laravel:  $LARAVEL  PHP: $PHP
  Frontend: $FRONTEND  (Vue: $VUE)

EOF

# ---------- Resolve + copy ----------
resolve_and_copy() {
  local side="$1"
  shift
  local -a candidates=("$@")

  # $side can be "laravel" or "frontend/vue" or "frontend/react" — the path
  # interpolation handles either single or nested layouts.
  # Read raw patterns from PATTERN_SOURCE/patterns/, write resolved to OUTPUT_DIR/.
  local base_dir="$PATTERN_SOURCE/patterns/$side/base"
  local override_root="$PATTERN_SOURCE/patterns/$side/overrides"
  local out_dir="$OUTPUT_DIR/$side"

  if [[ ! -d "$base_dir" ]]; then
    echo "  $side: no base directory, skipping" >&2
    return
  fi

  rm -rf "$out_dir"
  mkdir -p "$out_dir"

  local total=0 from_base=0 from_override=0
  local override_log=()

  while IFS= read -r -d '' base_file; do
    local rel="${base_file#$base_dir/}"
    # Skip the meta file itself (it's about the layer, not a pattern)
    if [[ "$rel" == "_meta.yaml" ]]; then
      continue
    fi

    local resolved="$base_file"
    for candidate in "${candidates[@]}"; do
      local override_path="$override_root/$candidate/$rel"
      if [[ -f "$override_path" ]]; then
        resolved="$override_path"
        break
      fi
    done

    local out_path="$out_dir/$rel"
    mkdir -p "$(dirname "$out_path")"
    cp "$resolved" "$out_path"

    total=$((total + 1))
    if [[ "$resolved" == "$base_dir/"* ]]; then
      from_base=$((from_base + 1))
    else
      from_override=$((from_override + 1))
      override_log+=("    $rel  ←  ${resolved#$override_root/}")
    fi
  done < <(find "$base_dir" -type f -print0)

  echo "  $side: $total files (base: $from_base, override: $from_override)"
  if (( from_override > 0 )); then
    printf '%s\n' "${override_log[@]}"
  fi
}

# ---------- Laravel side (2 axes) ----------
if [[ -z "$SIDE_FILTER" || "$SIDE_FILTER" == "laravel" ]]; then
  resolve_and_copy laravel \
    "laravel-${LARAVEL}+php-${PHP}" \
    "laravel-${LARAVEL}" \
    "php-${PHP}"
fi

# ---------- Frontend side (vue or react — single axis on the major version) ----------
if [[ -z "$SIDE_FILTER" || "$SIDE_FILTER" == "frontend" ]]; then
  case "$FRONTEND" in
    vue)
      resolve_and_copy "frontend/vue" "vue-${VUE}"
      ;;
    react)
      # React patterns live in patterns/frontend/react/. If the base is empty
      # (skeleton state), resolve_and_copy will write the empty set silently.
      resolve_and_copy "frontend/react" "react-18"
      ;;
    none)
      echo "  frontend: skipped (--frontend=none)"
      ;;
    *)
      echo "ERROR: --frontend must be vue, react, or none (got: $FRONTEND)" >&2
      exit 1
      ;;
  esac
fi

# ---------- Addon merge pass ----------
# For each addon, walk its patterns/ tree and copy every file into the matching
# patterns-built/ path. Addon wins on collision with core's resolved file.
# Later addons in the list override earlier ones.
merge_addon_patterns() {
  local addon_dir="$1"
  local addon_patterns="$addon_dir/patterns"

  if [[ ! -d "$addon_patterns" ]]; then
    return  # addon doesn't contribute patterns (skills/agents only)
  fi

  local addon_name
  if [[ -f "$addon_dir/.bench-addon.yaml" ]]; then
    addon_name=$(grep -E '^name:' "$addon_dir/.bench-addon.yaml" | head -1 | sed -E 's/^name:[[:space:]]*//; s/[[:space:]]+$//')
  else
    addon_name="$(basename "$addon_dir")"
  fi

  local merged=0
  local new_files=0
  local overridden=0
  local merge_log=()

  while IFS= read -r -d '' addon_file; do
    local rel="${addon_file#$addon_patterns/}"
    # Skip _meta.yaml — it's about the addon's layer, not a contributed pattern
    if [[ "$(basename "$rel")" == "_meta.yaml" ]]; then
      continue
    fi

    local out_path="$OUTPUT_DIR/$rel"
    local was_present=false
    [[ -f "$out_path" ]] && was_present=true

    mkdir -p "$(dirname "$out_path")"
    cp "$addon_file" "$out_path"

    merged=$((merged + 1))
    if $was_present; then
      overridden=$((overridden + 1))
      merge_log+=("    $rel  ←  $addon_name (overrides core)")
    else
      new_files=$((new_files + 1))
      merge_log+=("    $rel  ←  $addon_name (new)")
    fi
  done < <(find "$addon_patterns" -type f \( -name "*.md" -o -name "*.yaml" \) -print0)

  echo "  addon $addon_name: $merged files ($new_files new, $overridden override core)"
  if (( merged > 0 )); then
    printf '%s\n' "${merge_log[@]}"
  fi
}

if (( ${#ADDONS[@]} > 0 )); then
  echo ""
  echo "Merging ${#ADDONS[@]} addon(s):"
  for addon in "${ADDONS[@]}"; do
    if [[ ! -d "$addon" ]]; then
      echo "  WARNING: addon path not found: $addon" >&2
      continue
    fi
    merge_addon_patterns "$addon"
  done
fi

echo ""
echo "Done. Output: $OUTPUT_DIR/"
