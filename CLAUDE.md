# expresscharge/monorepo — project notes for Claude

This is an **aggregator-only** repo. It holds three submodules (`web`,
`email-worker`, `ios`) plus a top-level integrated dev stack (Makefile +
docker-compose.yml). No application code lives here.

## How to work in this repo

- **Don't commit code at the top level.** All real development happens
  inside the submodule directories (`web/`, `email-worker/`, `ios/`),
  which are independent git repositories with their own branches and CI.
- When you make a change inside a submodule, commit + push there first,
  then return to the monorepo and `git add <submodule>` + commit to bump
  the pinned commit.
- `make update` pulls the latest `main` from each submodule and stages
  the pointer bumps. Review with `git diff --submodule=log` before
  committing.

## Submodule pointers

`git submodule status` shows the pinned commit per submodule. CI's
`submodule-drift` check fails if the working tree's submodule HEADs
diverge from those pointers, which catches accidentally-uncommitted
submodule updates.

## Local CI fallback

When GitHub Actions is unavailable:

| CI job              | Local equivalent                                     |
|---------------------|------------------------------------------------------|
| `submodule-drift`   | `git submodule status` — any leading `+` or `-` is drift |
| `web`               | `cd web && bin/precommit.sh`                         |
| `email-worker`      | `cd email-worker && npm ci && npx tsc --noEmit && npx wrangler deploy --dry-run` |
| `ios`               | `cd ios && bin/precommit.sh` (requires macOS + Xcode + xcodegen) |
| `compose-build`     | `docker compose build`                               |

`make check` chains all the lint/typecheck steps; `make test` runs all
test suites; `make compose-build` runs the integrated docker build. Any
of those locally is roughly equivalent to the corresponding CI job.

## Things this repo does NOT do

- Build releases or container images (the per-component repos do this).
- Run the iOS TestFlight pipeline (lives in `ios/.github/workflows/main.yml`).
- Deploy the email worker to Cloudflare (lives in `email-worker/.github/workflows/deploy.yml`).
- Hold secrets — submodules manage their own.
