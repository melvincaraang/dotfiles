# portable dev environment — see docs/plans/2026-09-30-dotfiles-design.md
set export
set dotenv-load := true

# fresh machine, everything
setup:
    just secrets
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
install tool="all":
    ./installers/dispatch {{tool}}

# configs (idempotent)
sync tool="all":
    ./syncers/dispatch {{tool}}

# verification
doctor tool="all":
    ./doctor/dispatch {{tool}}

# secrets & helpers (secrets check="init" → `just secrets` runs init, `just secrets check` runs check)
secrets check="init":
    ./secrets/{{check}}
aws:
    ./helpers/aws
push:
    git push origin main
pull:
    git pull --rebase origin main
