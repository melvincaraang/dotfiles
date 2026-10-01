# dotfiles

Portable dev environment — kitty, neovim, tmux, pi, SearXNG, zsh — on mac / Arch / Ubuntu
from one clone plus one command.

## New machine in 5 lines

```
git clone github-personal:melvincaraang/dotfiles.git && cd dotfiles
just secrets   # .env init — per-variable prompts (hidden input), values never land in git
just setup     # OS packages + mise runtimes + every tool: install → sync → doctor
aws sso login --profile $AWS_PROFILE   # SSO is manual; sessions don't travel ($AWS_PROFILE comes from .env)
./searxng/start   # SearXNG is a local service (127.0.0.1:8080) and must be (re)started per boot
```

## Targets

| target | what it does |
|---|---|
| `just setup` | everything fresh-box: OS packages + mise runtimes + all syncs + doctor |
| `just install <tool>` | one binary — tools: `kitty nvim tmux pi searxng zsh`; runtimes: `uv node ripgrep fzf awscli just` |
| `just sync <tool>` | link one/all configs only (idempotent) |
| `just doctor <tool>` | verify one/all (also `just doctor secrets`) |
| `just aws` | print identity for `$AWS_PROFILE`; if the profile isn't authenticated, tell you to re-login |
| `just secrets` · `just secrets check` | `.env` init / audit set·missing·empty (names only) |
| `just push` · `just pull` | git via the `github-personal` SSH alias |

`setup` fans out into the same per-tool targets — install (binary) and sync (config)
are orthogonal by design, and all paths are computed from `git rev-parse --show-toplevel`,
so the repo works from any clone path on any OS.

## Secrets

- `.env` at the repo root (gitignored) is the single source of truth for all secrets
  **and** machine-local coordinates (Ollama endpoint, SearXNG home/key/profile, AWS profile name).
- `.env.example` is committed — every variable name + format, no values.
- `just secrets` — INIT: copy example to `.env`, prompt per empty variable (hidden input).
- `just secrets check` — audit: set / missing / empty, **names only**.
- `just sync secrets` — render per-tool env artifacts from `.env`
  (`~/.config/context7.env`, `~/.config/clickup.env`, `~/.pi/agent/models.json`, `~/.pi/searxng.json`).

Never in git: `.env`, API key values, AWS SSO sessions, pi session history,
`~/.pi/agent/npm`, `~/.local/share/nvim/{lazy,mason}`.

## OS notes

- **Ubuntu — neovim:** apt's `neovim` lags (lazy.nvim needs ≥ 0.9). `just install nvim`
  prefers the official release/nightly tarball or the community PPA; `just doctor nvim`
  asserts `nvim --version` ≥ 0.9 (target 0.11 on mac).
- **AWS SSO is manual** on every machine — SSO sessions don't travel:
  `aws sso login --profile $AWS_PROFILE` (check with `just aws`).
- **SearXNG start is per boot** — local web service backing pi's web search:
  `./searxng/start` (status/logs: `./searxng/start status|logs`).

## Repo identity

- Local root: `~/Development/dotfiles`
- Remote: `github-personal:melvincaraang/dotfiles.git` (SSH alias; not the HTTPS/`gh` path)
- Commit identity (repo-local): `Melvin Caraang / meljc37@gmail.com`
- History: the old `dotfiles-nvim` repo was folded in as `nvim/` and remains as archive

## Docs

- Design: [`docs/plans/2026-09-30-dotfiles-design.md`](docs/plans/2026-09-30-dotfiles-design.md)
- Implementation plan: [`docs/plans/2026-09-30-dotfiles-implementation.md`](docs/plans/2026-09-30-dotfiles-implementation.md)
