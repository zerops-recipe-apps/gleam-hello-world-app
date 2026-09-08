# gleam-hello-world-app

Minimal Gleam web app (Wisp + Mist) running on the BEAM/Erlang VM, with PostgreSQL via `gleam_pgo` and idempotent migrations.

## Zerops service facts

- HTTP port: `3000`
- Siblings: `db` (PostgreSQL) — env: `DB_HOST`, `DB_PORT`, `DB_USER`, `DB_PASS`, `DB_NAME`
- Runtime base: `gleam@1.5` on **`ubuntu`** (Gleam is not available on Alpine; the `gleam@1.5` base image already includes the CLI)

## Zerops dev

`setup: dev` idles on `zsc noop --silent`; the agent starts the dev server.

- Dev command: `gleam run`
- In-container rebuild without deploy: `gleam export erlang-shipment`

**All platform operations (start/stop/status/logs of the dev server, deploy, env / scaling / storage / domains) go through the Zerops development workflow via `zcp` MCP tools. Don't shell out to `zcli`.**

## Notes

- `HOME=/home/zerops` is required in dev runtime — rebar3 (used by Gleam's package compiler) crashes on `rebar_dir:home_dir/0` without it.
- After a container restart, re-run `gleam deps download` before `gleam run` to repopulate `build/packages/`.
- Migration runs once per deploy via `zsc execOnce ... -- sh -c "gleam deps download && gleam run -m migrate"` in `initCommands`.
