# Design: portable dev-environment repo (`dotfiles`)

**Date:** 2026-09-30
**Status:** approved (brainstormed with owner)
**Repo:** local `~/Development/dotfiles` → remote `github-personal:melvincaraang/dotfiles` (personal GitHub account, SSH key `id_ed25519_personal`)

## 1. Purpose

One clonable repo + one command (`just setup`) that reproduces Melvin's full
dev environment on a fresh machine — macOS today; **Arch Linux and Ubuntu**
boxes are first-class, not afterthoughts.

## 2. Goals / non-goals

**Goals**
- Install binaries, link configs, and verify everything — idempotently, per-tool or all-at-once.
- Cross-OS: mac / arch / ubuntu share one code surface.
- Secrets never in git (`.example` files only); machine state never in git.

**Non-goals (YAGNI)**
- No chezmoi / nix / ansible / tmux-plugin-manager.
- No session history, no runtime state (pi `npm/`, nvim `lazy/`+`mason/`, brew caches).
- No per-machine *content* differences yet — the design supports them later (see §10).

## 3. Repo identity

- Local git root: `~/Development/dotfiles` (existed as a folder; `dotfiles-nvim`
  was folded in as `nvim/` per decision (a)).
- Remote: `github-personal:melvincaraang/dotfiles.git`.
- Auth: SSH alias `github-personal` (ssh config block gained `AddKeysToAgent yes`,
  `UseKeychain yes`). **Not** the HTTPS/`gh` path — the personal `gh` token is a
  fine-grained PAT scoped repo-by-repo and does not cover new repos.
- Commit identity (repo-local): `Melvin Caraang / meljc37@gmail.com`.
- Old `melvincaraang/dotfiles-nvim` GitHub repo remains as archive/history.

## 4. Tools and their providers

| tool     | provider                          | notes |
|----------|-----------------------------------|-------|
| kitty    | OS packages (brew/pacman/apt)     | binary only; config in repo |
| neovim   | OS packages + **Ubuntu: official binary/PPA** (apt's nvim is too old) | needs ≥0.9 for lazy.nvim; target 0.11 on mac |
| tmux     | OS packages                       | config is 5 portable lines |
| pi       | npm (`npm i -g @earendil-works/pi-coding-agent`) or curl installer | **self-installs its packages** from `settings.json` on first run — no manual plugin install |
| searxng  | git clone + `uv` venv (Python 3.13) | local web service @ 127.0.0.1:8080, JSON format on |
| uv       | **mise (pinned version)**         | SearXNG bootstrap hard-depends on it |
| node, just, ripgrep, fzf, awscli | mise (global pins) | cross-OS by design |
| fonts    | OS packages (fonts tap/packages)  | kitty needs an explicit font for cross-OS consistency |

**Provider split (the key cross-OS decision):**
```
OS packages (Brewfile / pacman.txt / apt.txt)  → kitty, neovim, tmux, fonts
mise (mise.toml)                               → uv, node, just, ripgrep, fzf, awscli
```

## 5. Repo layout (committed)

```
dotfiles/
├── justfile                     # entry points; OS dispatch; fan-out per tool
├── Brewfile                     # mac: kitty, neovim, tmux, fonts
├── pacman.txt                   # arch list
├── apt.txt                      # ubuntu list (+ nvim upgrade note)
├── mise.toml                    # pinned: uv, node, just, ripgrep, fzf, awscli
├── README.md                    # "new machine in 5 lines"
├── installers/                  # one script/tool: OS dispatch for that tool
├── syncers/                     # one script/tool: link configs (idempotent)
├── doctor/                      # one script/tool: verify
├── kitty/                       # kitty.conf, current-theme.conf (Catppuccin Mocha),
│   │                            #   keybindings-mac.conf, keybindings-linux.conf
├── nvim/                        # init.lua (portable paths), lazy-lock.json, lsp/, lua/…
├── pi/                          # agent/settings.json, agent/models.json (redacted),
│   │                            #   agent/AGENTS.md, searxng.json
├── tmux/                        # tmux.conf (verbatim port of ~/.tmux.conf)
├── searxng/                     # settings.yml, clone+bootstrap scripts (no hardcoded dirs)
├── zsh/                         # base + mac + linux fragments (see §8)
├── secrets/                     # context7.env.example, clickup.env.example (real values gitignored)
├── docs/plans/                  # design + implementation plans
└── .gitignore                   # .DS_Store, nvim/startup.log, secrets/*.env (!.example)
```

## 6. Command surface (just)

```
just setup                    # EVERYTHING fresh-box: OS pkgs + mise + all syncs + doctor
just install <tool>           # one binary (kitty|nvim|tmux|pi|searxng|uv)
just sync [tool]              # link one/all configs only (idempotent)
just doctor [tool]            # verify one/all
just aws | just secrets       # SSO re-auth helper / .env init + audit (names only)
just sync secrets             # render per-tool env artifacts from .env
just push | just pull         # git via github-personal
```

- `setup` fans out into the same per-tool targets (no duplicated install logic).
- `install` ≠ `sync`: binary vs config, orthogonal by design.
- All symlinks computed at runtime via `git rev-parse --show-toplevel`
  → repo works from any clone path, on any OS.

## 7. Sync specifics per tool

| tool      | mechanism |
|-----------|-----------|
| nvim      | `ln -sfn $ROOT/nvim ~/.config/nvim`; then **one headless `nvim +lazy +sync +qa`** using `lazy-lock.json`; mason tools rebuilt by `nvim --headless` Mason command or lazily at first use |
| kitty     | `ln -sfn $ROOT/kitty ~/.config/kitty`; kitty has **no OS conditional** in conf → syncer writes a runtime (uncommitted) `current-keybindings.conf` that includes `keybindings-mac.conf` or `keybindings-linux.conf` (current `cmd+` mappings are mac-only) |
| tmux      | `ln -sfn $ROOT/tmux/tmux.conf ~/.tmux.conf` |
| pi        | symlink `pi/agent/{settings,models,AGENTS}.md` → `~/.pi/agent/`, `pi/searxng.json` → `~/.pi/searxng.json`; on first `pi` run it reinstalls the 4 packages into `~/.pi/agent/npm` from `settings.json` — no manual plugin step |
| searxng   | clone to `~/tools/searxng` (if absent), copy `settings.yml`, run bootstrap (needs `uv`): creates `.venv` (Python 3.13) + `start.sh stop/start/status/logs` |
| zsh       | see §8 |

## 8. zsh policy

Keep the existing `~/.zshrc` working — **no big-bang rewrite**. Migration:
1. Snapshot current `~/.zshrc` as `zsh/existing.zsh` (reference, committed for parity).
2. Decompose the portable parts (env sourcing, context7 env, PATH bits)
   into `zsh/base.zsh`; mac-only bits (homebrew paths) into `zsh/mac.zsh`;
   linux equivalents in `zsh/linux.zsh`.
3. `just sync zsh` assembles `~/.zshrc` = managed header + `source` of
   base+OS fragments + an unmanaged `local.zsh` tail (machine-specific scraps
   stay there, never lost).
Fresh machines get a working zshrc from fragments alone.

## 9. Secrets & machine-local values

**Canonical pattern (owner-directed):** one gitignored `.env` at repo root = single source of
truth for **all** secrets AND machine-local coordinates (Ollama endpoint, SearXNG port,
AWS profile name). One committed `.env.example` lists every variable (names + format, no values).

Mechanics:
1. `justfile` sets `dotenv-load := true` → every just target sees the real values; no recipe hardcodes URLs/keys.
2. `pi/agent/models.json` becomes `pi/agent/models.json.template` (committed, `{{OLLAMA_BASE_URL}}` placeholder) rendered at `just sync pi`; same for `~/.pi/searxng.json` from `SEARXNG_BASE_URL`.
3. `just secrets` = INIT (copy example, prompt per empty var, hidden input) · `just secrets check` = audit set/missing/empty (names only) · `just sync secrets` = materialize per-tool env artifacts (`~/.config/context7.env`, `~/.config/clickup.env`, `~/.pi/agent/models.json`, `~/.pi/searxng.json`).
4. `setup` step 1 = `just secrets` — fresh box starts with the fill-in prompt, everything after consumes the env.
5. `doctor` includes `.env` presence + required vars non-empty (names only).

Never in git: `.env`, API key values, AWS SSO sessions, pi session history, `~/.pi/agent/npm`, `~/.local/share/nvim/{lazy,mason}`, `~/.config/gh/*`.

## 10. Cross-OS matrix (what `setup` does per OS)

| step            | mac                 | arch                | ubuntu                |
|-----------------|---------------------|---------------------|-----------------------|
| package layer   | `brew bundle`       | `pacman -S --needed`(pacman.txt) | `apt install`(apt.txt) + nvim via official .deb/PPA |
| runtimes        | `mise install` (uv, node, just, rg, fzf, awscli) — identical across all three OSes |||
| configs         | `syncers/*` identical |||
| verify          | `doctor/*` identical |||
| manual-only     | SSO login; secret files copied out-of-band; `~/tools/searxng` up after reboot |||

Known OS-specific risk: **neovim version on Ubuntu** (apt package lags) —
mitigation in `installers/nvim`: prefer official nightly/release tarball or the
community PPA; doctor asserts `nvim --version` ≥ 0.9.

## 11. Doctor battery (per tool)

- **kitty**: `kitty --version`; config-load probe (`kitty +list-fonts >/dev/null` or `KITTY_DEBUG` dry check); theme file present.
- **nvim**: `nvim --version` ≥ 0.9; `nvim --headless "+Lazy healthcheck" +qa` (lazy plugin health); lazy-lock in sync.
- **tmux**: `tmux -V`; `tmux new-session -d -s probe` then `show-options automatic-rename` (conf actually loaded), kill session.
- **pi**: `pi --version`; first-run package install landed (`~/.pi/agent/npm` non-empty); 4 packages present.
- **searxng**: port 8080 up OR started by doctor; `GET /search?q=test&format=json` returns JSON; `start.sh status` == running.
- **uv**: `uv --version`; `mise ls` shows pin.
- **global**: `git status --porcelain` clean (drift check), repo-remote identity, `gh auth status` (informational), `aws sts get-caller-identity` (informational).

## 12. Acceptance

1. **This Mac (now):** `just setup` from the committed state → `just doctor` green; `git status` clean; pushed to `melvincaraang/dotfiles`.
2. **Arch & Ubuntu (when a box is available):** `git clone` + `just setup` → `just doctor` green, without any mac-only path.

## 13. Decision log

1. (a) New top-level repo; `dotfiles-nvim` folded in as `nvim/` (nested `.git` dropped); old GitHub repo archived.
2. Auth via SSH `github-personal` alias (personal key registered on account + keychain-cached), not the fine-grained personal gh PAT.
3. No chezmoi/nix/stow: config *content* is OS-identical; only install commands differ → absorbed by justfile dispatch + mise. Revisit chezmoi if per-machine content divergence or in-repo encrypted secrets become real needs.
4. pi packages: never vendored — `settings.json` is the source of truth, pi self-installs.
5. nvim: `lazy-lock.json` pins; runtime dirs excluded.
6. tmux: current 5-line config verbatim, no plugin manager.
7. uv via mise pin (single version source, cross-OS); OS packages only for kitty/nvim/tmux/fonts.
8. zsh: keep-and-decompose, never clobber (`local.zsh` tail).
9. Fonts: pin an explicit family in kitty.conf (TBD at plan stage: JetBrainsMono suggested) + per-OS install list, because current kitty uses OS default → looks different per machine.
10. SearXNG: stays local (chosen over a docker instance on another machine) + the local `settings.yml` secret_key → `.env` variable, template rendered at bootstrap.
11. Secrets: **single repo-root `.env` (gitignored) + `.env.example` (committed)**; `dotenv-load := true`; `just secrets` init/audit; models.json & searxng.json rendered from templates + .env at sync time.

## 14. Open items for the implementation plan

- Exact font choice + install list per OS.
- Exact per-OS lists (Brewfile/pacman.txt/apt.txt) — audit `brew list`, `apt file`, arch AUR availability.
- `installers/nvim` ubuntu fallback (PPA vs tarball vs mise-community) — verify at plan stage.
- Doctor probe details (kitty config-load method; lazy healthcheck command).
- ~~pi models.json redaction / internal Ollama URL in git?~~ → **resolved by decision 11**: URL lives in `.env`, only the template is committed.
- Repo visibility: **public OK** — no company-specific content committed; personal/infra details live in gitignored `AGENTS.private.md` (see pi task: generalized `AGENTS.md` + `AGENTS.private.example.md` split).
