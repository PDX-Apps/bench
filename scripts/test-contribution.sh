#!/usr/bin/env bash
# test-contribution.sh — regression tests for the contribution system
# (scripts/lib/contribution.sh + its wiring in build-patterns.sh and install.sh).
#
# Covers: replace / append / anchor (after|before|replace-block) at the lib level;
# version-override + addon contributions through build-patterns.sh (via an isolated
# --source fixture); addon append to agents + skills through install.sh, including
# idempotency and reversal. Exits non-zero if any assertion fails.
#
# Usage: scripts/test-contribution.sh

set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$(dirname "$SCRIPT_DIR")"
source "$SCRIPT_DIR/lib/contribution.sh"

PASS=0 FAIL=0
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

ok()   { PASS=$((PASS+1)); printf '  \033[32mPASS\033[0m %s\n' "$1"; }
bad()  { FAIL=$((FAIL+1)); printf '  \033[31mFAIL\033[0m %s\n' "$1"; }
assert_contains()    { if grep -qF "$2" "$1"; then ok "$3"; else bad "$3 (missing: $2)"; fi; }
assert_absent()      { if grep -qF "$2" "$1"; then bad "$3 (unexpected: $2)"; else ok "$3"; fi; }
assert_count()       { local n; n="$(grep -cF "$2" "$1")"; if [[ "$n" == "$3" ]]; then ok "$4 (count=$3)"; else bad "$4 (count=$n, want $3)"; fi; }
assert_fails()       { if "$@" >/dev/null 2>&1; then bad "expected failure: $*"; else ok "fails loudly: ${*:1:2}"; fi; }

echo "== Section 1: contrib_apply lib =="

# replace (no mode key)
printf 'OLD\n' > "$WORK/t"; printf 'NEW\n' > "$WORK/c"
contrib_apply "$WORK/t" "$WORK/c"; assert_contains "$WORK/t" "NEW" "replace: content swapped"; assert_absent "$WORK/t" "OLD" "replace: old gone"

# append
printf 'base line\n' > "$WORK/t"; printf -- '---\nmode: append\n---\nADDED\n' > "$WORK/c"
contrib_apply "$WORK/t" "$WORK/c"; assert_contains "$WORK/t" "base line" "append: base kept"; assert_contains "$WORK/t" "ADDED" "append: body added"

# append idempotency-of-body (frontmatter stripped, not in output)
assert_absent "$WORK/t" "mode: append" "append: contribution frontmatter stripped"

# anchor after
printf 'A\n<!-- bench:anchor:x -->\nORIG\n<!-- bench:/anchor:x -->\nB\n' > "$WORK/t"
printf -- '---\nmode: anchor\nanchor: x\nposition: after\n---\nINS\n' > "$WORK/c"
contrib_apply "$WORK/t" "$WORK/c"
assert_contains "$WORK/t" "INS" "anchor-after: inserted"; assert_contains "$WORK/t" "ORIG" "anchor-after: original kept"

# anchor before
printf '<!-- bench:anchor:y -->\nORIG\n<!-- bench:/anchor:y -->\n' > "$WORK/t"
printf -- '---\nmode: anchor\nanchor: y\nposition: before\n---\nPRE\n' > "$WORK/c"
contrib_apply "$WORK/t" "$WORK/c"
if [[ "$(head -1 "$WORK/t")" == "PRE" ]]; then ok "anchor-before: inserted ahead of marker"; else bad "anchor-before"; fi

# anchor replace-block
printf '<!-- bench:anchor:z -->\nOLDBLOCK\n<!-- bench:/anchor:z -->\n' > "$WORK/t"
printf -- '---\nmode: anchor\nanchor: z\nposition: replace-block\n---\nNEWBLOCK\n' > "$WORK/c"
contrib_apply "$WORK/t" "$WORK/c"
assert_contains "$WORK/t" "NEWBLOCK" "anchor-replace-block: new"; assert_absent "$WORK/t" "OLDBLOCK" "anchor-replace-block: old gone"

# missing anchor → fail loudly
printf 'no markers\n' > "$WORK/t"; printf -- '---\nmode: anchor\nanchor: nope\n---\nx\n' > "$WORK/c"
assert_fails contrib_apply "$WORK/t" "$WORK/c"
# unknown mode → fail loudly
printf 'x\n' > "$WORK/t"; printf -- '---\nmode: bogus\n---\nx\n' > "$WORK/c"; assert_fails contrib_apply "$WORK/t" "$WORK/c"
# merge/patch with bad input → fail loudly (no table / no blocks)
printf 'x\n' > "$WORK/t"; printf -- '---\nmode: merge\n---\nx\n' > "$WORK/c"; assert_fails contrib_apply "$WORK/t" "$WORK/c"
printf 'x\n' > "$WORK/t"; printf -- '---\nmode: patch\n---\nx\n' > "$WORK/c"; assert_fails contrib_apply "$WORK/t" "$WORK/c"

# merge: splice rows into the target table with the same header
printf '# Doc\n\n## Pattern Lookup\n\n| Need | Read |\n|------|------|\n| Base | base.md |\n\nMore text.\n' > "$WORK/t"
printf -- '---\nmode: merge\n---\n\n| Need | Read |\n|------|------|\n| Extra | extra.md |\n' > "$WORK/c"
contrib_apply "$WORK/t" "$WORK/c"
assert_contains "$WORK/t" "Extra | extra.md" "merge: new row spliced in"
assert_contains "$WORK/t" "Base | base.md" "merge: existing row kept"
assert_contains "$WORK/t" "More text." "merge: trailing content kept"
# row lands inside the table (before the blank line / 'More text.')
awk '/\| Extra \| extra.md/{r=NR} /More text\./{m=NR} END{exit !(r<m)}' "$WORK/t" && ok "merge: row inside the table" || bad "merge: row placement"
# merge with no matching header → fail loudly
printf '| A | B |\n|---|---|\n| 1 | 2 |\n' > "$WORK/t"
printf -- '---\nmode: merge\n---\n\n| X | Y |\n|---|---|\n| 9 | 9 |\n' > "$WORK/c"
assert_fails contrib_apply "$WORK/t" "$WORK/c"

# patch: gated literal find/replace
printf 'tools: Read, Grep\nmodel: sonnet\n' > "$WORK/t"
printf -- '---\nmode: patch\n---\n<<<<<<< FIND\ntools: Read, Grep\n=======\ntools: Read, Grep, Bash\n>>>>>>> REPLACE\n' > "$WORK/c"
contrib_apply "$WORK/t" "$WORK/c"
assert_contains "$WORK/t" "tools: Read, Grep, Bash" "patch: find/replace applied"
assert_contains "$WORK/t" "model: sonnet" "patch: rest of file untouched"
# patch FIND not unique → fail loudly (matches twice)
printf 'dup\ndup\n' > "$WORK/t"
printf -- '---\nmode: patch\n---\n<<<<<<< FIND\ndup\n=======\nx\n>>>>>>> REPLACE\n' > "$WORK/c"
assert_fails contrib_apply "$WORK/t" "$WORK/c"
# patch FIND not found → fail loudly
printf 'aaa\n' > "$WORK/t"
printf -- '---\nmode: patch\n---\n<<<<<<< FIND\nzzz\n=======\nx\n>>>>>>> REPLACE\n' > "$WORK/c"
assert_fails contrib_apply "$WORK/t" "$WORK/c"

# contrib_body: no frontmatter → whole file; frontmatter present → body only
printf 'plain body\n' > "$WORK/c"; [[ "$(contrib_body "$WORK/c")" == "plain body" ]] && ok "contrib_body: no-frontmatter passthrough" || bad "contrib_body passthrough"
[[ "$(contrib_frontmatter_get "$WORK/c" mode)" == "" ]] && ok "contrib_frontmatter_get: absent → empty" || bad "frontmatter_get empty"

echo ""
echo "== Section 2: build-patterns.sh (isolated --source fixture) =="
FIX="$WORK/fix"
mkdir -p "$FIX/patterns/laravel/base/demo" "$FIX/patterns/laravel/overrides/laravel-12/demo"
cat > "$FIX/patterns/laravel/base/_meta.yaml" <<'Y'
target: { laravel: "13.x", php: "8.5" }
Y
# base files
printf '# REPL\nbase-replace-body\n' > "$FIX/patterns/laravel/base/demo/REPL.md"
printf '# APP\nbase-append-body\n' > "$FIX/patterns/laravel/base/demo/APP.md"
printf '# ANC\n<!-- bench:anchor:lookup -->\nBASEROW\n<!-- bench:/anchor:lookup -->\n' > "$FIX/patterns/laravel/base/demo/ANC.md"
# L12 overrides: replace (legacy, no mode) / append / anchor
printf '# REPL\nL12-REPLACED\n' > "$FIX/patterns/laravel/overrides/laravel-12/demo/REPL.md"
printf -- '---\nmode: append\n---\nL12-APPENDED-NOTE\n' > "$FIX/patterns/laravel/overrides/laravel-12/demo/APP.md"
printf -- '---\nmode: anchor\nanchor: lookup\nposition: after\n---\nL12ROW\n' > "$FIX/patterns/laravel/overrides/laravel-12/demo/ANC.md"

bash "$SCRIPT_DIR/build-patterns.sh" --laravel=12 --php=8.5 --frontend=none --source="$FIX" --output="$FIX/out" >/dev/null 2>&1
O="$FIX/out/laravel/demo"
assert_contains "$O/REPL.md" "L12-REPLACED" "override replace (no mode) applied"
assert_absent   "$O/REPL.md" "base-replace-body" "override replace dropped base"
assert_contains "$O/APP.md"  "base-append-body" "override append kept base"
assert_contains "$O/APP.md"  "L12-APPENDED-NOTE" "override append added note"
assert_contains "$O/ANC.md"  "L12ROW" "override anchor inserted row"
assert_contains "$O/ANC.md"  "BASEROW" "override anchor kept base row"

# build at L13 (no L12 overrides apply) → base verbatim
bash "$SCRIPT_DIR/build-patterns.sh" --laravel=13 --php=8.5 --frontend=none --source="$FIX" --output="$FIX/out13" >/dev/null 2>&1
assert_contains "$FIX/out13/laravel/demo/REPL.md" "base-replace-body" "L13: base used (override skipped)"
assert_absent   "$FIX/out13/laravel/demo/APP.md"  "L12-APPENDED-NOTE" "L13: no L12 append"

# addon append + anchor through build-patterns
ADD="$WORK/addon"; mkdir -p "$ADD/patterns/laravel/demo"
printf 'name: t\n' > "$ADD/.bench-addon.yaml"
printf -- '---\nmode: append\n---\nADDON-SECTION\n' > "$ADD/patterns/laravel/demo/APP.md"
printf -- '---\nmode: anchor\nanchor: lookup\nposition: after\n---\nADDONROW\n' > "$ADD/patterns/laravel/demo/ANC.md"
bash "$SCRIPT_DIR/build-patterns.sh" --laravel=13 --php=8.5 --frontend=none --source="$FIX" --output="$FIX/outA" --addon="$ADD" >/dev/null 2>&1
assert_contains "$FIX/outA/laravel/demo/APP.md" "ADDON-SECTION" "addon append applied"
assert_contains "$FIX/outA/laravel/demo/ANC.md" "ADDONROW" "addon anchor applied"
# idempotency
bash "$SCRIPT_DIR/build-patterns.sh" --laravel=13 --php=8.5 --frontend=none --source="$FIX" --output="$FIX/outA" --addon="$ADD" >/dev/null 2>&1
assert_count "$FIX/outA/laravel/demo/APP.md" "ADDON-SECTION" "1" "addon append idempotent on rebuild"

echo ""
echo "== Section 3: install.sh (addon append to agent + skill) =="
T="$WORK/install"
AG="$WORK/addon-ix"; mkdir -p "$AG/agents" "$AG/skills/model"
printf 'name: ix\n' > "$AG/.bench-addon.yaml"
printf -- '---\nmode: append\n---\n## Boost\nappended-agent-line\n' > "$AG/agents/model.md"
printf -- '---\nmode: append\n---\n## Extra\nappended-skill-line\n' > "$AG/skills/model/SKILL.md"
bash "$SCRIPT_DIR/install.sh" --target="$T" --frontend=none --addon="$AG" >/dev/null 2>&1
assert_contains "$T/agents/model.md" "appended-agent-line" "install: addon append to AGENT"
assert_contains "$T/agents/model.md" "Pattern Lookup" "install: agent base content intact"
assert_contains "$T/skills/model/SKILL.md" "appended-skill-line" "install: addon append to SKILL"
# idempotency across rebuild
bash "$SCRIPT_DIR/install.sh" --target="$T" --frontend=none --addon="$AG" >/dev/null 2>&1
assert_count "$T/agents/model.md" "appended-agent-line" "1" "install: agent append idempotent"
# reversal: clear persisted addon → rebuild → original restored
rm -f "$T/.install-addons-config"
bash "$SCRIPT_DIR/install.sh" --target="$T" --frontend=none --no-addon >/dev/null 2>&1
assert_absent "$T/agents/model.md" "appended-agent-line" "install: reversal restores clean agent"
assert_contains "$T/agents/model.md" "Pattern Lookup" "install: clean agent still valid"

echo ""
echo "================================"
printf 'Contribution tests: \033[32m%d passed\033[0m, ' "$PASS"
if (( FAIL > 0 )); then printf '\033[31m%d FAILED\033[0m\n' "$FAIL"; exit 1; else printf '0 failed\n'; fi
