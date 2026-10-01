# dotfiles-managed: zsh/linux.zsh — Linux-only additions (sourced after zsh/base.zsh)
export AWS_PROFILE="${AWS_PROFILE:-default}"   # or set yours in ~/.zshrc.local / .env
# ── powerlevel10k (installers/zsh clones it to ~/.cache/p10k) ───────────
# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi
[[ -f "$HOME/.cache/p10k/powerlevel10k.zsh-theme" ]] && source "$HOME/.cache/p10k/powerlevel10k.zsh-theme"
# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
