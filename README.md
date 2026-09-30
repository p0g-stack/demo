# demo

One page per surfaces affordance, on every host. Each page shows which of its
capabilities the host has and what the app does without them.

## Scope

In: the pages, the swappable-backends example (a trait, `available()`, a
preference order, and a page that reports which backend ran), the e2e walk
that drives every page under every fake host profile.

Out: reusable widgets (`surfaces_ui`), host probes and grading (`certify`),
build plumbing (`template-app` layout, `surfaces` CLI).

## Proposed nest

```
lib/
  home.dart           page registry: title, capabilities, page
  pages/              host, back, window, lifecycle, storage, files, feedback,
                      theme, apps, shell, ops, backends, core, sound
rust/
  core/               demo ops and jobs; backends/ with the trait example
  worker/ native/     as template-app
tool/
  e2e_steps.cjs       per-page steps; consumed by surfaces/tools/e2e as a pinned dependency
.github/workflows/    ci runs the e2e walk on all profiles and fails on page errors
```

## Rules

- A page per affordance, an affordance per page. New capability in `surfaces`
  means a new page here in the same change set.
- The e2e walk asserts page and console errors, not just step completion.

## License

LGPL-3.0-or-later with the LGPL-3.0 linking exception
(`LICENSE`, `LICENSE.exception`; SPDX `LGPL-3.0-or-later WITH LGPL-3.0-linking-exception`).
Apps may link this library statically or dynamically, private apps included,
without releasing their own code or shipping relinking material. Changes to
the library itself stay LGPL.
