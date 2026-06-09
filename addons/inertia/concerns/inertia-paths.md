---
concern: inertia-paths
title: Inertia page directory
order: 40
when: grep -q '"@inertiajs/' package.json 2>/dev/null || grep -q 'inertiajs/inertia-laravel' composer.json 2>/dev/null
questions:
  - id: inertia_pages_dir
    ask: "Where do your Inertia page components live? (the directory the createInertiaApp resolve glob points at)"
    default: "resources/js/Pages"
output: vars
---

## Apply

Merge `inertia_pages_dir` into the shared `.bench/vars.yaml` (preserve any other vars already there). It resolves into this addon's `<!--bench:var:inertia_pages_dir;default:resources/js/Pages-->` placeholders at build time. If it equals the default, omit it — the inline default covers it.
