---
concern: ui-paths
title: UI component paths
order: 40
when: ls package.json >/dev/null 2>&1
questions:
  - id: ui_dir
    ask: "Import path/alias where your shadcn/ui components live? (components.json → aliases.ui; in a monorepo often a shared package)"
    detect: python3 -c "import json;print(json.load(open('components.json')).get('aliases',{}).get('ui','@/components/ui'))" 2>/dev/null || echo "@/components/ui"
    default: "@/components/ui"
  - id: utils_dir
    ask: "Import path/alias for your cn() / utils helper? (components.json → aliases.utils)"
    detect: python3 -c "import json;print(json.load(open('components.json')).get('aliases',{}).get('utils','@/lib/utils'))" 2>/dev/null || echo "@/lib/utils"
    default: "@/lib/utils"
output: vars
---

## Apply

Merge `ui_dir` and `utils_dir` into the shared `.bench/vars.yaml` (one `name: value` per line; **preserve any other vars already there**). They resolve into this addon's `<!--bench:var:ui_dir;default:@/components/ui-->` / `<!--bench:var:utils_dir;default:@/lib/utils-->` placeholders at build time. If a value equals its default, omit it — the inline default already covers it. These are **shared** variable names; another addon needing the UI dir reuses `ui_dir`, never a per-addon key.
