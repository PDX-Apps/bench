---
name: vue-layout
description: In a Blade-rendered project, layouts are Blade layouts — not Vue shells.
---

This project renders UI with **Blade** (the `bench-blade` addon is active). Layouts are
Blade layouts (`@extends` / `<x-layout>`), not Vue app shells.

- To build a layout, use `/blade` (`BLADE-002-layouts`).
- Vue components still mount into Blade layouts as islands — use `/vue-component`.

Do not scaffold a Vue layout component or `<RouterView>` shell. Redirect to `/blade`.
