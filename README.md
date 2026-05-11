# ExpressCharge — developer monorepo

Aggregator repo combining all three ExpressCharge components as git submodules
for one-clone-gets-everything development. Each submodule is also independently
useful and has its own CI / release pipeline.

```
expresscharge/
├── web/           ← Deno + Fresh fullstack web app (admin + customer)
├── email-worker/  ← Cloudflare Workers transactional email service
└── ios/           ← Swift / iOS 26 native app
```

## Quickstart

```bash
git clone --recursive git@github.com:expresscharge/monorepo.git expresscharge
cd expresscharge
make bootstrap
```

If you already cloned without `--recursive`:

```bash
make bootstrap   # runs: git submodule update --init --recursive
```

## Common commands

```bash
make update          # pull latest from each submodule's main, then bump pointers
make check           # web + email-worker + ios lint + typecheck
make test            # web + email-worker + ios test suites
make up              # docker compose up integrated stack (postgres + web + sync)
make down            # tear it down
```

Per-submodule targets (`web-dev`, `ios-build`, `email-worker-dev`, etc.) are
documented in the Makefile.

## Integrated dev stack

`docker-compose.yml` at the root builds `web/` from its Dockerfile and wires
it to a postgres container + the sync worker. The email worker runs on
Cloudflare and is not in the compose stack — for local email development,
`cd email-worker && npx wrangler dev` (and configure the web app's
`CF_EMAIL_WORKER_URL` to point at the wrangler dev URL).

## Submodule update flow

Submodules are pinned to specific commits — `git submodule status` shows the
current pin. To bump:

```bash
make update              # pulls each submodule's main
git add web email-worker ios
git commit -m "Bump submodules"
```

CI's `bump-submodules` workflow does this automatically on a weekly schedule.

## Per-component repos

| Component       | Repository                                           |
|-----------------|------------------------------------------------------|
| Web (Fresh)     | https://github.com/expresscharge/web                 |
| Email worker    | https://github.com/expresscharge/email-worker        |
| iOS app         | https://github.com/expresscharge/ios                 |

## License

MIT — see [LICENSE](LICENSE).
