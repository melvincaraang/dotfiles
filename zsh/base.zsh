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
