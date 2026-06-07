#!/usr/bin/env bash
# contribution.sh — apply a contribution file to a target file by its declared mode.
#
# The contribution model (see docs/contribution-system.md). A *contribution* is a
# markdown file that layers onto a base/target file. Its leading YAML frontmatter
# MAY declare `mode:`:
#
#   replace  (default) — the whole file replaces the target (legacy behavior)
#   append             — the contribution body is appended as a trailing section
#   anchor             — the body is spliced at a named marker in the target
#   merge / patch      — reserved (not yet implemented; treated as an error)
#
# A file with NO `mode:` key is treated as `replace` — so every existing override
# and addon file keeps working unchanged.
#
# Anchors in a target look like:   <!-- bench:anchor:NAME -->   ...   <!-- bench:/anchor:NAME -->
# A contribution declares `anchor: NAME` and `position: after|before|replace-block`.
#
# Public function:
#   contrib_apply <target_file> <contribution_file>
#       Mutates <target_file> in place per the contribution's mode.
#       Exits non-zero (and prints to stderr) on an unresolved anchor or unknown mode.

# --- read a frontmatter scalar key from a file ("" if absent / no frontmatter) ---
contrib_frontmatter_get() {
  local file="$1" key="$2"
  # Only look inside a leading --- ... --- block.
  awk -v k="$key" '
    NR==1 && $0!="---" { exit }                 # no frontmatter
    NR==1 { infm=1; next }
    infm && $0=="---" { exit }
    infm {
      line=$0
      sub(/[[:space:]]*#.*$/, "", line)         # strip trailing comment
      if (line ~ "^"k"[[:space:]]*:") {
        sub("^"k"[[:space:]]*:[[:space:]]*", "", line)
        gsub(/^[\"'\'']|[\"'\'']$/, "", line)    # strip surrounding quotes
        gsub(/[[:space:]]+$/, "", line)
        print line; exit
      }
    }
  ' "$file"
}

# --- echo the body (everything after a leading frontmatter block); whole file if none ---
contrib_body() {
  local file="$1"
  awk '
    NR==1 && $0!="---" { print; bodyonly=1; next }   # no frontmatter → whole file
    bodyonly { print; next }
    NR==1 { infm=1; next }
    infm && $0=="---" { infm=0; started=1; next }     # end of frontmatter
    infm { next }
    started { print }
  ' "$file"
}

# --- apply one contribution to a target file, in place ---
contrib_apply() {
  local target="$1" contribution="$2"
  local mode; mode="$(contrib_frontmatter_get "$contribution" mode)"
  [[ -z "$mode" ]] && mode="replace"

  case "$mode" in
    replace)
      cp "$contribution" "$target"
      ;;
    append)
      # blank line separator, then the contribution body
      { printf '\n'; contrib_body "$contribution"; } >> "$target"
      ;;
    anchor)
      local name pos
      name="$(contrib_frontmatter_get "$contribution" anchor)"
      pos="$(contrib_frontmatter_get "$contribution" position)"; [[ -z "$pos" ]] && pos="after"
      if [[ -z "$name" ]]; then
        echo "ERROR: anchor contribution missing 'anchor:' key: $contribution" >&2; return 1
      fi
      if ! grep -q "bench:anchor:$name" "$target"; then
        echo "ERROR: anchor '$name' not found in target $target (from $contribution)" >&2; return 1
      fi
      local body; body="$(contrib_body "$contribution")"
      local tmp; tmp="$(mktemp)"
      awk -v name="$name" -v pos="$pos" -v body="$body" '
        BEGIN { amark="bench:anchor:" name; zmark="bench:/anchor:" name }
        {
          if (pos=="before" && index($0, amark))      { print body; print; next }
          if (pos=="after"  && index($0, amark))      { print; print body; next }
          if (pos=="replace-block") {
            if (index($0, amark)) { print; print body; skip=1; next }
            if (index($0, zmark)) { skip=0; print; next }
            if (skip) next
          }
          print
        }
      ' "$target" > "$tmp" && mv "$tmp" "$target"
      ;;
    merge|patch)
      echo "ERROR: contribution mode '$mode' not yet implemented ($contribution)" >&2; return 1
      ;;
    *)
      echo "ERROR: unknown contribution mode '$mode' ($contribution)" >&2; return 1
      ;;
  esac
}
