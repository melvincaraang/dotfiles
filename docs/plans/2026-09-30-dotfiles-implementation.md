# dotfiles Implementation Plan

> **REQUIRED SUB-SKILL:** Use the executing-plans skill to implement this plan task-by-task.

**Goal:** Build the cross-OS (macOS/Arch/Ubuntu) dev-environment repo at `~/Development/dotfiles` so that `git clone + just setup` reproduces the full stack on a fresh machine.

**Architecture:** One repo = configs (kitty/nvim/tmux/pi/searxng/zsh) + `just`-driven
install/sync/doctor per tool. Provider split: OS packages for kitty/nvim/tmux/fonts,
`mise` for runtimes (just/uv/node/ripgrep/fzf/awscli), npm for pi. All secrets and
machine-local values live in a single gitignored `.env` (template `.env.example` committed,
`dotenv-load := true` just setting); per-tool env artifacts are rendered at `just sync` time.
Symlinks are computed via `git rev-parse --show-toplevel` so the repo works from any clone path.

**Tech Stack:** just, bash, mise, Brewfile/pacman/apt lists, lazy.nvim, pi + npm packages, uv, SearXNG.

**Worktree note:** no worktree — we build the repo itself; 2-commit repo, no competing state.

**Repo:** `~/Development/dotfiles` → `github-personal:melvincaraang/dotfiles.git`
(GitHub repo `melvincaraang/dotfiles` exists; visibility **public** — OK only because no company-specific content is committed: `pi/agent/AGENTS.md` is the generalized public-safe copy, personal/infra details live in the gitignored `AGENTS.private.md`, `.env.example` uses generic defaults.)

**Convention in this plan:** `ROOT` = `$(git rev-parse --show-toplevel)` (i.e. `~/Development/dotfiles`).
`OS` = `mac` | `arch` | `ubuntu`. Verify steps are the "tests": run → expected output → commit.

---

### Task 1: justfile + OS bootstrap skeleton

**Files:**
- Create: `.env.example` (placeholder; Task 2 fills it — just create empty file with header comment)
- Create: `justfile`
- Create: `lib/os.sh`
- Create: `secrets/.keep` (Task 2)
- Modify: `.gitignore` (add `just` cache if any — none expected)

**Step 1: Create `lib/os.sh`**

```bash
#!/usr/bin/env bash
# OS detection + shared helpers. Sourced by installers/syncers/doctor scripts.
set -euo pipefail

detect_os() {
  case "$(uname -s)" in
    Darwin) echo mac ;;
    Linux)
      if [ -f /etc/arch-release ]; then echo arch
      elif [ -f /etc/os-release ]; then
        . /etc/os-release
        case "${ID:-}" in ubuntu|debian|pop) echo ubuntu ;; *) echo linux-generic ;; esac
      else echo linux-generic; fi
      ;;
    *) echo unknown ;;
  esac
}
OS="$(detect_os)"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && git rev-parse --show-toplevel 2>/dev/null || pwd)"   # BASH_SOURCE (sourced lib), not $0
```

**Step 2: Create the `justfile`** (complete from day one — per-tool scripts arrive in later tasks; dispatchers print "not implemented yet" for missing ones):

```just
# portable dev environment — see docs/plans/2026-09-30-dotfiles-design.md
set export
set dotenv-load := true

# fresh machine, everything
setup:
    {{just()}} secrets
    ./installers/os-packages
    ./installers/runtimes
    ./installers/dispatch all
    ./syncers/dispatch all
    ./doctor/dispatch all

# binaries (runtimes = just uv node ripgrep fzf awscli, mise-pinned)
install-os-packages:
    ./installers/os-packages
install-runtimes:
    ./installers/runtimes

# tools: kitty nvim tmux pi searxng zsh  |  runtimes: uv node ripgrep fzf awscli just
[no-auto-escape]
install tool="all":
    ./installers/dispatch {{tool}}

# configs (idempotent)
[no-auto-escape]
sync tool="all":
    ./syncers/dispatch {{tool}}

# verification
[no-auto-escape]
doctor tool="all":
    ./doctor/dispatch {{tool}}

# secrets & helpers
secrets:
    ./secrets/init
secrets check:
    ./secrets/check
aws:
    ./helpers/aws
push:
    git push origin main
pull:
    git pull --rebase origin main
```

**Step 2b: Create the three dispatchers** (`installers/dispatch` shown; `syncers/` and `doctor/` are identical shape with dir swapped, calling `./syncers/$t` / `./doctor/$t`):

```bash
#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
tool="${1:-all}"
case "$tool" in
  all) for t in kitty nvim tmux pi searxng zsh; do ./installers/"$t"; done ;;
  uv|node|ripgrep|fzf|awscli|just|os-packages|runtimes) ./installers/"$tool" ;;
  kitty|nvim|tmux|pi|searxng|zsh)
    [ -x "./installers/$tool" ] || { echo "installers/$tool not implemented yet (later task)"; exit 0; }
    ./installers/"$tool" ;;
  *) echo "unknown: $tool (try: all | kitty nvim tmux pi searxng zsh | uv node ripgrep fzf awscli just)" >&2; exit 2 ;;
esac
```
(`[no-auto-escape]` is needed so `{{tool}}` stays unexpanded inside the recipe.
For the runtimes line: until `installers/runtimes` exists (Task 3), commit a stub: `#!/usr/bin/env bash\necho "not implemented yet (Task 3)"` + `exit 0`, same for `installers/os-packages` (Task 10) — each later task overwrites its stub.)

**Step 2c: Commit the `secrets/` stubs** (so `just --list` / `just secrets` never 127 before Task 2):
- `secrets/init`: `#!/usr/bin/env bash` + `set -euo pipefail` + `cd "$(dirname "${BASH_SOURCE[0]}")/.."` + `[ -f .env ] && { echo ".env present"; exit 0; }` + `cp .env.example .env; echo ".env created — fill values in: just secrets"`
- `secrets/check`: `echo "not implemented yet (Task 2)"; exit 0`
- `installers/runtimes`, `installers/os-packages`: stubs as above.
- `.env.example`: placeholder one-liner `# filled in Task 2` (real content in Task 2).

**Step 3: Verify**

Run: `just --list` and `just secrets`
Expected: targets listed (setup, install, sync, doctor, secrets, aws, push, pull); `.env` created (placeholder) — then `rm .env` to keep Task 2's real init clean.

**Step 4: Commit**

```bash
git add justfile lib/os.sh installers/dispatch syncers/dispatch doctor/dispatch secrets/ .env.example
git commit -m "feat(just): core targets, os detection, dispatchers, secrets stubs"
```

---

### Task 2: `.env` secrets engine

**Files:**
- Create: `.env.example`
- Create: `secrets/init`, `secrets/check`
- Create: `syncers/secrets`
- Modify: `.gitignore` (ensure `.env` + `secrets/*.env` ignored, `secrets/.keep` tracked)

**Step 1: Write `.env.example`** (comments are the user-facing documentation):

```env
# dotfiles machine-local values — copy to .env and fill in:  just secrets
# ── pi / Ollama ────────────────────────────────────────────
OLLAMA_BASE_URL=http://127.0.0.1:11434/v1   # your Ollama host (localhost or the LAN machine running it)
# ── SearXNG (local web service backing pi web_search) ──────
SEARXNG_HOME=$HOME/tools/searxng
SEARXNG_PORT=8080
SEARXNG_SECRET_KEY=      # 32+ chars; leave empty and `just secrets` generates one
PI_SEARXNG_URL=http://127.0.0.1:8080
# ── keys ───────────────────────────────────────────────────
CONTEXT7_API_KEY=        # https://context7.com (for pi's context7 tool)
CLICKUP_API_TOKEN=       # ClickUp personal API key (pk_...)
# ── aws ────────────────────────────────────────────────────
AWS_PROFILE=default   # your active awscli profile (`aws --list-profiles`)
```

**Step 2: `secrets/init`** (replaces Task 1's stub) — if `.env` missing: `cp .env.example .env`.
Then pre-fill from existing local files (non-destructive; never overwrites a non-empty value):
- `CONTEXT7_API_KEY` ← `grep -h '^CONTEXT7_API_KEY=' ~/.config/context7.env 2>/dev/null | cut -d= -f2`
- `CLICKUP_API_TOKEN` ← same from `~/.config/clickup.env`
- `SEARXNG_SECRET_KEY` ← `grep -oP 'secret_key:\s"\K[^"]+' ~/tools/searxng/settings.yml 2>/dev/null` *(keeping the secret stable when Task 8 adopts the existing local clone)*
Then, for each still-empty `*_KEY`/`*_TOKEN`: prompt `read -rs` (label + mask). `SEARXNG_SECRET_KEY` still empty → `openssl rand -hex 32`. Rewrite `.env` in place; print exactly which vars were filled (names only).

**Step 3: `secrets/check`** (replaces stub) — table `VAR | status (set|empty)` — names only, never values, never partial values.
Exits non-zero if any of `OLLAMA_BASE_URL PI_SEARXNG_URL CONTEXT7_API_KEY CLICKUP_API_TOKEN` is empty (REQUIRED for doctor-green); `SEARXNG_HOME/SEARXNG_PORT/AWS_PROFILE` have defaults.

**Step 4: `syncers/secrets`** — render from `.env`. **All templates use `${VAR}` syntax for `envsubst`** (never `{{VAR}}`):
- `~/.config/context7.env` ← `print -r -- "CONTEXT7_API_KEY=${CONTEXT7_API_KEY}"`
- `~/.config/clickup.env` ← `print -r -- "CLICKUP_API_TOKEN=${CLICKUP_API_TOKEN}"`
- `~/.pi/searxng.json` ← `echo "{\"searxngUrl\":\"${PI_SEARXNG_URL}\",\"timeoutMs\":15000,\"maxResults\":10}"`
- `~/.pi/agent/models.json` ← `envsubst < "$ROOT/pi/agent/models.json.template"` — **guard**: `[ -f "$ROOT/pi/agent/models.json.template" ] || exit 0` (template lands in Task 7; this keeps Task 2 alone runnable).
- `searxng` settings render is owned by `searxng/bootstrap` (Task 8) — do NOT duplicate here.

**Step 5: Verify**

```bash
# backup existing for parity check
cp ~/.config/context7.env /tmp/c7.bak
just secrets           # .env created with real values auto-filled (from this mac's existing env files)
just secrets check     # all REQUIRED vars: set
just sync secrets      # files rendered
diff <(sed 's/=.*/=X/' /tmp/c7.bak) <(sed 's/=.*/=X/' ~/.config/context7.env)   # same variable, same value line count
```
Expected: `secrets/check` all-set; rendered `searxng.json` equals `cat` of the pre-existing one.

**Step 6: Commit**

```bash
git add .env.example secrets/ syncers/secrets .gitignore
git commit -m "feat(secrets): .env engine (init pre-fill / check audit / sync renderers)"
```

---

### Task 3: mise runtimes installer

**Files:**
- Create: `installers/runtimes`
- Create: `mise.toml` (informational pins; real install via `mise use -g`)

**Step 1: `installers/runtimes`:**

```bash
#!/usr/bin/env bash
set -euo pipefail
command -v mise >/dev/null || curl https://mise.run | sh && . "$HOME/.local/bin/env" >/dev/null 2>&1 || true
# global, pinned, cross-OS:
mise use -g just@1.58.0 uv@0.9.7 node@22.19.0 ripgrep@15.1.0 fzf@0.66.1 awscli@2.31.28
```

(If `mise use -g` pinning fails on any tool on any OS, fallback per-tool: `mise install --tool` with the same pins — same outcome.)

**Step 2: Verify**

```bash
just install-runtimes 2>&1 | tail -5; mise ls | grep -E '^(just|uv|node|ripgrep|fzf|awscli) '
```
Expected: 6 tools listed with pinned versions.

**Step 3: Commit** — `feat(runtimes): mise-pinned just/uv/node/rg/fzf/awscli`

---

### Task 4: kitty (config split + font + install/sync/doctor)

**Files:**
- Create: `kitty/kitty.conf` (from `~/.config/kitty/kitty.conf` MINUS keybindings, plus font pin)
- Create: `kitty/keybindings-mac.conf` (the current `cmd+` mappings)
- Create: `kitty/keybindings-linux.conf` (same actions with `super+` equivalents)
- Create: `kitty/current-theme.conf` (copy, Catppuccin Mocha)
- Create: `installers/kitty`, `syncers/kitty`, `doctor/kitty`
- Modify: `.gitignore` (add `kitty/current-keybindings.conf` — machine artifact)
- Modify: `Brewfile` / `pacman.txt` / `apt.txt` via Task 10 lists (kitty + JetBrains font)

**Step 1: kitty.conf body** (base):

```
font_family JetBrainsMono
font_size 14
include current-theme.conf
include current-keybindings.conf
```

`keybindings-mac.conf` = the existing `cmd+` bindings verbatim from current kitty.conf.
`keybindings-linux.conf` = same binding lines with `cmd+`→`super+`.

**Step 2: `syncers/kitty`:**
```bash
mkdir -p ~/.config
ln -sfn "$ROOT/kitty" ~/.config/kitty
printf 'source keybindings-%s.conf\n' "$OS" > "$ROOT/kitty/current-keybindings.conf"   # gitignored
```
(`current-keybindings.conf` is a machine artifact derived from `$OS` at sync time — gitignore it.)

**Step 3: `installers/kitty`:** dispatch `$OS`:
- mac: `brew install --cask kitty font-jetbrains-mono`
- arch: `sudo pacman -S --needed kitty ttf-jetbrains-mono`
- ubuntu: `sudo apt-get install -y kitty fonts-jetbrains-mono`

**Step 4: `doctor/kitty`:** `kitty --version`; `fc-match JetBrainsMono` (font installed);
config-parse probe: `kitty +list-override-fonts >/dev/null 2>&1` (exits 0 iff kitty.conf + includes parse).

**Step 5: Verify** (BACKUP FIRST — this replaces the live kitty config):
```bash
cp -a ~/.config/kitty ~/.config/kitty.bak-$(date +%s)
just install kitty; just sync kitty; just doctor kitty
cat ~/.config/kitty/current-keybindings.conf   # -> source keybindings-mac.conf
zsh -ic 'kitty +' 2>/dev/null || kitty --version   # binary visible on PATH
```
**Step 6: Commit** — `feat(kitty): portable conf, per-OS keybinding bundle, font pin, doctor`

---

### Task 5: nvim (portable paths + install/sync/doctor)

**Files:**
- Modify: `nvim/init.lua` (remove the hardcoded `/Users/melvincaraang/.local/bin` → use `vim.fn.stdpath('data')..'/mason/bin'` or `~/.local/bin` via `os.getenv('HOME')`)
- Create: `installers/nvim`, `syncers/nvim`, `doctor/nvim`
- Modify: OS package lists (add `neovim`)

**Step 1: `nvim/init.lua` patch** — find the line referencing the absolute path and replace with:

```lua
vim.env.PATH = vim.fn.execpath() .. ':' .. vim.env.HOME .. '/.local/bin'
```

(match the existing intent: put mason local bin on PATH — read the file first, keep everything else).

**Step 2: `installers/nvim`:**
- mac: `brew install neovim`
- arch: `sudo pacman -S --needed neovim`
- ubuntu: `apt-cache policy neovim | awk '/Candidate/{print $2}'` → if version ≥ 0.9.5: `sudo apt-get install -y neovim`; else latest **stable** GitHub release — map `uname -m` (x86_64→`x86_64`, arm64→`aarch64`), tag from `https://api.github.com/repos/neovim/neovim/releases/latest`, download `nvim-linux-${arch}.tar.gz`, extract to `~/.local/share/nvim-stable`, symlink bins into `~/.local/bin`, print done.

**Step 3: `syncers/nvim`:**
```bash
ln -sfn "$ROOT/nvim" ~/.config/nvim
nvim --headless "+Lazy! sync" +qa    # one-time materialize of lazy-lock plugins
nvim --headless "+Mason! reset" +qa 2>/dev/null || true   # best-effort toolchain restore
```

**Step 4: `doctor/nvim`:** `nvim --version | head -1` ≥ v0.9;
`nvim --headless "+lua print(#require('lazy').plugins())" +qa 2>/dev/null` > 0;
lazy-lock present: `[ -f ~/.config/nvim/lazy-lock.json ]`.

**Step 5: Verify**

```bash
cp -a ~/.config/nvim /tmp/nvim.bak-$(date +%s)
just install nvim 2>&1 | tail -2; just sync nvim; just doctor nvim
nvim --version | head -1
```
Expected: v0.11.5 (mac brew); lazy plugin count > 0; no doctor failures.

**Step 6: Commit** — `feat(nvim): portable init.lua + install/sync/doctor`

---

### Task 6: tmux (verbatim port)

**Files:**
- Create: `tmux/tmux.conf` (copy of `~/.tmux.conf` — byte-for-byte)
- Create: `installers/tmux`, `syncers/tmux`, `doctor/tmux`
- Modify: OS package lists (add `tmux`)

**Step 1:** `cp ~/.tmux.conf tmux/tmux.conf` (5 lines; verify identical with `diff`).

**Step 2: `syncers/tmux`:** `ln -sfn "$ROOT/tmux/tmux.conf" ~/.tmux.conf`.

**Step 3: `doctor/tmux`:** `tmux -V`; then
```bash
tmux new-session -d -s dotprobe -e FOO=bar
tmux show-options -g automatic-rename | grep -q 'automatic-rename on' && tmux kill-session -t dotprobe
```
(proves the conf is parsed; `automatic-rename` is set in our conf).

**Step 4: Verify** — `just install tmux; just sync tmux; just doctor tmux` all green;
`diff <(tmux show-options -g automatic-rename) <(echo '\tautomatic-rename on')` (modulo tab).

**Step 5: Commit** — `feat(tmux): verbatim conf port + targets`

---

### Task 7: pi (settings committed, models/searxng rendered, install/sync/doctor)

**Files:**
- Create: `pi/agent/settings.json` (copy of current — fully portable, verify no machine paths)
- Create: `pi/agent/AGENTS.md` (**generalized, public-safe** copy — no company names/profiles/IPs/accounts)
- Create: `pi/agent/AGENTS.private.example.md` (skeleton with section headings + placeholders, NO values; real `AGENTS.private.md` is user-local, gitignored)
- Create: `pi/agent/models.json.template` (current models.json with `"baseUrl": "${OLLAMA_BASE_URL}"`)
- Create: `installers/pi`, `syncers/pi`, `doctor/pi` (dispatchers already exist from Task 1)
- Note: Task 2's `syncers/secrets` models.json render (guarded) becomes live now that the template exists — no changes needed there.

**Step 1: Verify pi settings portability** — `grep -nE '/Users/|localhost|127\.0\.0' pi/agent/settings.json pi/agent/AGENTS.md`
→ expected: AGENTS.md is the generalized copy: no `/Users/`, no company names/profiles/IPs/accounts. Spot-check locally by grepping for your own company terms, internal profile names, and internal IPs (do NOT put that literal check pattern in this committed doc — it would name the things we're hiding). It must instruct: read sibling `AGENTS.private.md` if present. The live private file is created locally (existing content preserved there); never committed (`.gitignore` has `AGENTS.private.md`).

**Step 2: `installers/pi`:**
```bash
command -v node ... || { echo "need node — run: just install-runtimes"; exit 1; }
npm i -g @earendil-works/pi-coding-agent@0.99.2
```
(pinned to current pi version.)

**Step 3: `syncers/pi`:** (symlinks the two static files; the two rendered files are owned by `syncers/secrets` — which has the template guard, so calling it after the template exists just works)
```bash
mkdir -p ~/.pi/agent
ln -sfn "$ROOT/pi/agent/settings.json" ~/.pi/agent/settings.json
ln -sfn "$ROOT/pi/agent/AGENTS.md"     ~/.pi/agent/AGENTS.md
./syncers/secrets   # renders ~/.pi/agent/models.json (via template) + ~/.pi/searxng.json
```

**Step 4: `doctor/pi`:** `pi --version` == 0.99.2; `~/.pi/agent/npm` non-empty (`[ -n "$(ls -A ~/.pi/agent/npm 2>/dev/null)" ]` after first pi run); 4 packages present: `ls ~/.pi/agent/npm/node_modules | grep -cE 'pi-superpowers|pi-subagents|context7-pi|pi-searxng'` → expects 4.

**Step 5: Verify** (BACKUP FIRST — symlink swap of live files; file-level, not whole-.pi — sessions dir can be large):
```bash
BK=$HOME/backups/pi-$(date +%Y%m%d-%H%M%S); mkdir -p "$BK"
cp -a ~/.pi/agent/settings.json ~/.pi/agent/AGENTS.md ~/.pi/agent/models.json ~/.pi/searxng.json "$BK/" 2>/dev/null || true
just install pi; just sync pi; just doctor pi
cat ~/.pi/agent/models.json | python3 -m json.tool >/dev/null && echo "models.json valid"
diff <(cat "$BK"/settings.json) <(cat ~/.pi/agent/settings.json)   # identical
```
Rollback on failure: `cp -a "$BK"/* ~/.pi/agent/ && rm ~/.pi/agent/models.json... ` — or simply re-run `just sync secrets` after fixing.

**Step 6: Commit** — `feat(pi): committed settings + AGENTS.md, templated models.json, install/sync/doctor`

---

### Task 8: SearXNG (templated settings, portable bootstrap)

**Files:**
- Create: `searxng/settings.yml.template`
- Create: `searxng/bootstrap` (clone-if-absent + venv + render settings from `.env`)
- Create: `searxng/start` (portable rewrite of current `start-searxng.sh`: `DIR` computed from env `SEARXNG_HOME`)
- Create: `installers/searxng` (deps: uv + git, via runtimes/os), `syncers/searxng` (`SEARXNG_HOME` dir prep), `doctor/searxng`
- Modify: `.env.example` (already has SEARXNG_* — verify names match)

**Step 1: `searxng/settings.yml.template`** (current settings.yml with):
```yaml
server:
  bind_address: 127.0.0.1
  port: ${SEARXNG_PORT}
  secret_key: "${SEARXNG_SECRET_KEY}"
```
rendered by `bootstrap` via `envsubst` into `$SEARXNG_HOME/settings.yml` (template stays in-repo; rendered file stays machine-local, gitignored by living outside the repo).

**Step 2: `searxng/bootstrap`:**
```bash
set -euo pipefail
: "${SEARXNG_HOME:?run: just secrets}"; : "${SEARXNG_SECRET_KEY:?}"
mkdir -p "$SEARXNG_HOME"
cd "$SEARXNG_HOME"
[ -d .git ] || git clone https://github.com/searxng/searxng .
envsubst < "$ROOT/searxng/settings.yml.template" > settings.yml
[ -d .venv ] || ( uv venv .venv --python 3.13 && uv pip install -r requirements.txt )
```

**Step 3: `searxng/start`** = current script with `DIR="${SEARXNG_HOME:-$HOME/tools/searxng}"`.

**Step 4: `doctor/searxng`:** `start status` → up; else `start` (idempotent) → then
`curl -sS -m 5 "http://127.0.0.1:${SEARXNG_PORT}/search?q=test&format=json" | head -c 60`
contains `"success":true` or categories array.

**Step 5: Verify**

```bash
# on this mac the existing clone at ~/tools/searxng should be ADOPTED (no re-clone):
ls ~/tools/searxng/.git >/dev/null && echo "adopt" ;  # -> adopt
cp ~/tools/searxng/settings.yml /tmp/searxng-settings.bak   # contains current secret key!
just install searxng; just sync searxng && just doctor searxng
```
**Secret continuity:** Task 2's `secrets/init` already pre-fills `SEARXNG_SECRET_KEY` from the existing `~/tools/searxng/settings.yml` — verify stability (service stays session-compatible):
`diff <(grep -oP 'secret_key:\s"\K.*' /tmp/searxng-settings.bak) <(grep -oP 'secret_key:\s"\K.*' ~/tools/searxng/settings.yml)` → identical.

**Step 6: Commit** — `feat(searxng): templated settings + portable bootstrap/start (secret in .env)`

---

### Task 9: zsh fragments + guarded sync

**Files:**
- Create: `zsh/base.zsh`, `zsh/mac.zsh`, `zsh/linux.zsh`
- Create: `installers/zsh` (fresh-box: oh-my-zsh + powerlevel10k), `syncers/zsh`
- Modify: `.gitignore` (add `zsh/local.zsh` if we ever create one — machine tail, not committed)

**Step 1: `zsh/base.zsh`** (portable):
```zsh
# dotfiles-managed: zsh/base.zsh
export PATH="$HOME/.local/bin:$PATH"
[ -n "${ZDOTDIR:-}" ] || export ZDOTDIR="$HOME"
# oh-my-zsh
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"
plugins=(git)
source $ZSH/oh-my-zsh.sh
# env
export AWS_PROFILE="${AWS_PROFILE:-default}"   # or set yours in ~/.zshrc.local / .env
[ -f "$HOME/.config/context7.env" ] && . "$HOME/.config/context7.env"
# mise
eval "$(command -v mise >/dev/null && mise activate zsh)"
```
**`zsh/mac.zsh`:** homebrew PATH, `HOMEBREW_NO_AUTO_UPDATE=1`, coreutils gnubin, nvm block, bun block, p10k theme+`~/.p10k.zsh` sourcing.
**`zsh/linux.zsh`:** p10k via `~/.cache/p10k` clone (installed by `installers/zsh`), AWS_PROFILE.
(Extract the EXACT current lines from this mac's `.zshrc` (lines 1-149) into the right fragment — do not retype; copy + strip machine-specific comments.)

**Step 2: `installers/zsh`:** `git clone --depth 1 https://github.com/ohmyzsh/ohmyzsh ~/.oh-my-zsh` (if absent); p10k: mac → `brew install powerlevel10k`; linux → `git clone --depth 1 https://github.com/romkatv/powerlevel10k ~/.cache/p10k`.

**Step 3: `syncers/zsh` (GUARDED):**
```bash
if [ -f ~/.zshrc ]; then
  # never clobber an existing user shell on an established machine:
  cp -n ~/.zshrc "$HOME/.zshrc.bak-$(date +%Y%m%d-%H%M%S)" 2>/dev/null || true
  [ -f ~/.zshrc.dotfiles-adopted ] || { mv ~/.zshrc ~/.zshrc.legacy; : > ~/.zshrc.dotfiles-adopted; }
fi
cat > ~/.zshrc <<EOF
# generated by dotfiles (`just sync zsh`) — machine tail: ~/.zshrc.local
source "$ROOT/zsh/base.zsh"
source "$ROOT/zsh/$OS.zsh"
[ -f "$HOME/.zshrc.local" ] && source "$HOME/.zshrc.local"
EOF
echo "zshrc managed; old one preserved at ~/.zshrc.legacy (on first run)"
```
*Rule:* on THIS mac, `.zshrc.dotfiles-adopted` does not exist → first `just sync zsh` moves current to `~/.zshrc.legacy`. **Before the verify step, the user's current .zshrc must be backed up** (the script does it, but also do `cp ~/.zshrc ~/zshrc.bak-manual-$(date +%s)` for safety, and `zsh -ic 'echo OK'` smoke test after).

**Step 4: Verify**

```bash
zsh -c 'source <(cat ~/.zshrc)' ; zsh -ic 'echo $AWS_PROFILE; command -v mise; alias | head -3'
```
Expected: `AWS_PROFILE` echoes the value from `.env`, mise present, no errors. Revert path if anything breaks: `mv ~/.zshrc.legacy ~/.zshrc`.

**Step 5: Commit** — `feat(zsh): base/mac/linux fragments + guarded zshrc adoption`

---

### Task 10: OS package dispatch + lists

**Files:**
- Create: `installers/os-packages`
- Create: `Brewfile`, `pacman.txt`, `apt.txt`

**Step 1: lists** (add any discovered during earlier tasks — keep in sync):
- `Brewfile`: `cask "kitty"`, `cask "font-jetbrains-mono"`, `brew "neovim"`, `brew "tmux"`, `brew "oh-my-zsh"`? (omz is manual clone → skip), `brew "powerlevel10k"`
- `pacman.txt`: `kitty ttf-jetbrains-mono neovim tmux git curl`
- `apt.txt`: `kitty fonts-jetbrains-mono neovim tmux git curl ca-certificates`

**Step 2: `installers/os-packages`:**
```bash
case "$OS" in
  mac) brew bundle --file "$(dirname "$0")/../Brewfile" ;;
  arch) sudo pacman -S --needed "$(tr '\n' ' ' < ../pacman.txt)" ;;
  ubuntu|linux-generic) sudo apt-get update && sudo apt-get install -y $(tr '\n' ' ' < ../apt.txt) ;;
  *) echo "unsupported os: $OS" >&2; exit 1 ;;
esac
```

**Step 3: Verify** — `just install-os-packages` (mac): brew says already-satisfied for all listed; exit 0. (On mac this must be a NO-OP — proves idempotency.)

**Step 4: Commit** — `feat(os): package lists + OS dispatch (brew/pacman/apt)`

---

### Task 11: helpers (aws, push/pull) + README

**Files:**
- Create: `helpers/aws`
- Create: `README.md`

**Step 1: `helpers/aws`:**
```bash
#!/usr/bin/env bash
set -euo pipefail
P="${AWS_PROFILE:?AWS_PROFILE must be set in .env}"
if aws --profile "$P" sts get-caller-identity >/dev/null 2>&1; then
  aws --profile "$P" sts get-caller-identity | grep -E 'Arn|AccountId'
else
  echo "profile '$P' not authenticated on this machine (SSO sessions don't travel)."
  echo "Run:  aws sso login --profile $P"
fi
```

**Step 2: `README.md`** — 5-line quickstart, target matrix from design §6, secrets flow (`just secrets`), OS notes (ubuntu nvim fallback, SSO is manual, SearXNG start is per-boot), repo identity, link to design doc.

**Step 3: Verify** — `just aws` (prints identity — this mac is already authed; expected 200-ish JSON, no crash when it fails).

**Step 4: Commit** — `feat: aws helper + README (new-machine quickstart)`

---

### Task 12: full acceptance pass on this Mac + push

**Step 1: Create GitHub repo (manual, one click, private)** —
`https://github.com/settings/repositories/new` → name `dotfiles`, **private**, no README.
(API route with the personal fine-grained PAT will 404 — PAT is repo-scoped to `dotfiles-nvim` only.)

**Step 2: Backup all live dotfiles ONE LAST TIME**
```bash
BK=$HOME/backups/pre-dotfiles-adopt-$(date +%Y%m%d-%H%M%S); mkdir -p "$BK"
cp -a ~/.config/kitty "$BK/kitty"; cp -a ~/.pi "$BK/pi"
cp -a ~/.tmux.conf "$BK/tmux.conf"; cp ~/.zshrc "$BK/zshrc"; cp -a ~/tools "$BK/tools" 2>/dev/null || true
```

**Step 3: Full run (the acceptance gate):**
```bash
just setup    # secrets (pre-filled) → os-packages (no-op) → runtimes → 6 installs → sync all → doctor all
just doctor   # explicit, capture output
```
**Pass criteria (all):**
1. `just doctor` exit 0 — battery: secrets-check (names only), kitty, nvim (lazy ≥1 plugin, ≥v0.9), tmux probe, pi (0.99.2 + 4 packages), searxng JSON `success:true`.
2. `git status --porcelain` empty.
3. `zsh -ic 'echo $AWS_PROFILE'` == the value from `.env`.
4. `curl -s localhost:8080/search?q=test&format=json` contains `"success":true`.
5. `pi --version` → `0.99.2`.

**Step 4: Push**

```bash
git push -u origin main
gh repo view melvincaraang/dotfiles --json url,visibility   # private? url?
```

**Step 5: Final commit** (if any doc drift) + verify.

---

## Out of scope (recorded, not tasks)

- Ollama install on the model-server box itself (that's a different machine's setup).
- Full migration of this mac's bespoke `.zshrc` extras (a custom bun alias, an internal zsh helper sourcing) — preserved via `~/.zshrc.local` tail on this machine; fresh-box fragments cover the baseline.
- Ubuntu/Arch actual runs — code is written for them; real verification happens when those boxes exist (design §12.2).
- pi session history sync (deliberate: not source of truth).
- tmux plugins / kitty powerline font glyphs (none currently used).

## Rollback

Every `syncers/*` that swaps live dotfiles was preceded by a backup in the verify step
(`~/.config/kitty.bak-*`, `~/.pi` → `/tmp/pi.bak-*`, `~/.zshrc.legacy`,
`~/backups/pre-dotfiles-adopt-*`). Any task failing its verify: restore the named backup,
fix, re-run that task only. Git: `git log --oneline` = per-task commits; `git revert <task-sha>`
reverts code; runtime dotfiles are restored from backup (git cannot undo a symlink swap —
that's why the backups exist).
