# Cross-agent memory (global)

User-level, cross-project memory for every pi session on this machine.
Append durable facts here — access, conventions, and standing instructions
that should survive compaction and project switches.

## How this memory works

Two files, same directory:

- **`AGENTS.md` (this file)** — the general, portable layer. Safe to commit
  and share. Contains workflow conventions and tooling that is fully local
  or public.
- **`AGENTS.private.md`** — the personal/infra layer: company or client
  names, account IDs, internal profile/endpoint names, internal IPs, and
  where secrets live. **Never committed to any repo.** Gitignored everywhere.

**On every session start:** if `AGENTS.private.md` exists in this
directory, read it and treat its contents as standing instruction.
**When you learn a durable fact** during a session: append it to the file
that owns it — private/personal → `AGENTS.private.md`; general workflow
conventions → here. Keep both files current and de-duplicated.

## Standing instructions

- **PR review flow:** for any PR that links a tracker ticket (issue-tracker
  comment with a ticket link), fetch the ticket and its checklist before
  finalizing the verdict. The ticket carries the Definition of Done,
  expected vs. actual behavior, root-cause analysis, and priority that the
  PR body often omits. A PR is not just "diff + green CI" — it must
  satisfy the ticket's DoD.
- **Secrets hygiene:** treat any API key, token, or credential as a secret
  by default. Read them from `.env` files or env vars; never print them,
  never commit them, never ship them in prompts, logs, or examples.
  `.env.example` files show names and format only — never real values.
- **Workflows:** for non-trivial changes, follow the installed `pi-superpowers`
  workflow (brainstorming → design doc → plan → execution) rather than
  jumping straight to code.
- **Verification before claiming success:** run the actual command and
  confirm the output before saying something works.

## Pi tooling (this machine)

Installed as pi packages (`~/.pi/agent/settings.json` → `packages`);
pi self-installs them into `~/.pi/agent/npm` on startup:

- `npm:pi-superpowers` — workflow skills (brainstorming, writing-plans,
  executing, debugging, TDD, …) + plan-tracker TUI extension.
- `npm:pi-subagents` — bounded delegation and workflows.
- `npm:@upstash/context7-pi` — Context7 tools (`resolve-library-id`,
  `query-docs`) for up-to-date library docs. The API key lives in a local
  env file (`~/.config/context7.env`, `CONTEXT7_API_KEY`), auto-sourced by
  the shell — set in every new shell / pi process. A pi session that is
  already running will not see changes (env is fixed at launch).
- `npm:pi-searxng` — `web_search`, `fetch_content` (auto-clones GitHub
  repo URLs read-only), `get_search_results`. Backed by a **local** SearXNG
  with `format=json` enabled; config at `~/.pi/searxng.json`
  (rendered from a template + `.env` by the dotfiles repo's
  `just sync secrets`).

### Local SearXNG

- Lives at `~/tools/searxng` (SearXNG source clone + `uv` venv, Python
  3.13), bound to **127.0.0.1** on the port from `~/.pi/searxng.json`
  (default 8080). Enabled formats: `html`, `json`; limiter off;
  `public_instance: false`.
- Not persistent across reboots by default — start it with the local
  start script in `~/tools/searxng` (subcommands: start/stop/status/logs).
  Required env at launch: `SEARXNG_SETTINGS_PATH` pointing at the SearXNG
  home dir; run the webapp via the venv Python as a module
  (running the script path directly fails on imports).
- Health check: `curl 'http://localhost:<port>/search?q=test&format=json'`
  → JSON. If that fails, start the service and check its logs.

## Conventions

- Git identity for personal repos comes from the machine's git config;
  use the `github-personal` SSH alias (see `~/.ssh/config`) for the
  personal account rather than the work account.
- Keep this file (and `AGENTS.private.md`) terse: facts and pointers, not
  essays. Delete stale entries instead of letting them accumulate.
