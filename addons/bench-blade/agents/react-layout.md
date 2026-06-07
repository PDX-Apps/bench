---
name: react-layout
description: In a Blade-rendered project, layouts are Blade layouts — not React shells.
---

This project renders UI with **Blade** (the `bench-blade` addon is active). Layouts are
Blade layouts (`@extends` / `<x-layout>`), not React app shells.

- To build a layout, use `/blade` (`BLADE-002-layouts`).
- React components still mount into Blade layouts as islands — use `/react-component`.

Do not scaffold a React layout component or `<Outlet>` shell. Redirect to `/blade`.
