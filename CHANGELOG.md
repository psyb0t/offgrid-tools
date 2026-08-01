# Changelog

All notable changes per release. Versions follow [semver](https://semver.org).

## v0.1.3 — 2026-08-01

Repository infrastructure only — no change to any tool, script or image in this collection.

- Every push now mirrors the repo to GitLab and Codeberg.
- Pushes to the default branch and to tags, plus a monthly schedule, submit the repo to the Wayback Machine and Software Heritage.
- Issues opened on the GitLab and Codeberg mirrors are pulled back into GitHub every six hours.
- Ignored the local `.telemetry/` scratch dir in git and Docker builds.

## v0.1.2 — 2026-07-27

- Added a GitHub Actions CI status badge to the README.

## v0.1.1 — 2026-07-27

Add README status badges.

- Added self-hosted version and license badges (rendered as SVGs on the `badges` branch by the `create-badges` CI job, no third-party render service). Added a pipeline.yml running the badges job.
