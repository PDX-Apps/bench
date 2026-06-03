#!/usr/bin/env bash
# validate-overrides.sh — check that every override file is still based on the
# current base file. Each override declares `base-hash:` in frontmatter, captured
# at fork time. If the base has since changed, the override may be stale.
#
# Exits 0 if all overrides are fresh, 1 if any are stale.
#
# Usage:
#   ./validate-overrides.sh           # check both sides
#   ./validate-overrides.sh laravel   # check one side

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(dirname "$SCRIPT_DIR")"

SIDES=()
if [[ $# -eq 0 ]]; then
  SIDES=(laravel vue)
else
  SIDES=("$@")
fi

stale_count=0

# Get the base-hash declared inside an override file's frontmatter
read_declared_hash() {
  local file="$1"
  awk '/^---/{c++; next} c==1 && /^base-hash:/{print $2; exit}' "$file"
}

# Compute the actual hash of a base file (sha256 short form, first 6 chars to match the convention)
compute_base_hash() {
  local file="$1"
  shasum -a 256 "$file" | awk '{print substr($1, 1, 6)}'
}

for side in "${SIDES[@]}"; do
  base_dir="$PLUGIN_ROOT/patterns/$side/base"
  overrides_root="$PLUGIN_ROOT/patterns/$side/overrides"

  [[ ! -d "$overrides_root" ]] && continue

  # Walk every override file (any depth)
  while IFS= read -r -d '' override_file; do
    # Skip non-markdown files (READMEs, .DS_Store, etc.)
    [[ "$override_file" == *.md ]] || continue

    rel_from_overrides="${override_file#$overrides_root/}"
    # rel_from_overrides looks like: laravel-13/models/MODEL-001-structure.md
    # Strip the leading override-target segment to get the base-relative path
    rel_to_base="${rel_from_overrides#*/}"
    base_file="$base_dir/$rel_to_base"

    if [[ ! -f "$base_file" ]]; then
      echo "  ⚠ override has no matching base: $rel_from_overrides"
      stale_count=$((stale_count + 1))
      continue
    fi

    declared=$(read_declared_hash "$override_file")
    if [[ -z "$declared" ]]; then
      echo "  ⚠ no base-hash declared: $rel_from_overrides"
      stale_count=$((stale_count + 1))
      continue
    fi

    actual=$(compute_base_hash "$base_file")
    if [[ "$declared" != "$actual" ]]; then
      echo "  ✗ STALE: $rel_from_overrides"
      echo "      declared base-hash: $declared"
      echo "      actual base-hash:   $actual"
      echo "      base file changed since this override was forked"
      stale_count=$((stale_count + 1))
    else
      echo "  ✓ $rel_from_overrides"
    fi
  done < <(find "$overrides_root" -type f -print0 2>/dev/null)
done

if (( stale_count > 0 )); then
  echo ""
  echo "$stale_count stale override(s) — review and update base-hash after verifying the override still applies."
  exit 1
fi

echo ""
echo "All overrides current."
exit 0
