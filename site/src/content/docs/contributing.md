---
title: Contributing
description: "How to help with Glass: code, device reports, docs and removal-list evidence."
---

Glass is open source (Apache-2.0) and contributions are welcome. You do not need to finish a feature to help: device reports and docs fixes count.

## Repositories

- **Glass launcher:** [glass-tv-launcher](https://github.com/AazainKhan/glass-tv-launcher). Kotlin and Jetpack Compose for TV, one `app` module. Read its `CONTRIBUTING.md` for the build setup (JDK 17 or 21), UI testing and the GPU performance rules.
- **The rooted and full system installs, and this site:** coming soon as a separate public repository.

## Good first contributions

- A **device report**: what you installed it on, which way you installed it, what worked.
- Confirming a claim on the [no-root page](/glass-os/no-root/) on an unrooted stick.
- Fixing a doc or runbook step that did not match what you saw.

## Conventions

- **Conventional Commits**: `type(scope): summary`, where type is one of feat, fix, perf, refactor, test, docs, build, ci, chore, style. Docs changes use `docs(site): ...`.
- **Runbook steps** keep the fixed shape (precondition, action, verify, on failure, needs user) and every shell block must pass `bash -n`. Run `npm run check:runbooks` in `site/`.
- **No device serials, no home-directory paths, no Amazon binaries or decompiled code** anywhere in the repository. Summaries only. Run `npm run check:leaks` in `site/` before opening a PR.
- Mark anything not built yet as "coming soon". Do not document features that do not exist.

## Working on this site

Needs Node 22.12 or newer.

```bash title="Terminal"
cd site
npm install
npm run dev        # local preview
npm run build      # must pass; also writes dist/llms.txt
npm run check:runbooks
npm run check:leaks
```

## Proposing a package removal (rooted and full system installs)

Removals are evidence-based: say what the package does, show that nothing kept depends on it, and run a 24-hour disable test on a real stick. Removal lists, the lint and the process arrive with that repository.

## Adding another device or Fire OS build

Coming soon. It will need the build's hash on an allowlist, its partition sizes, and a pass of the device checks.
