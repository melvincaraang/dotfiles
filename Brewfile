# macOS OS packages — `just install-os-packages` → `brew bundle --file Brewfile` (no-op when all satisfied)
# Runtimes (just/uv/node/ripgrep/fzf/awscli) are mise-managed — see mise.toml, not listed here.
cask "font-jetbrains-mono"
brew "neovim"
brew "tmux"
brew "powerlevel10k"
# kitty: only via cask if the app is not already present (a manual /Applications/Kitty.app install
# is the working state on existing machines — brew cannot cleanly replace it; see installers/kitty)
if ! File.exist?("/Applications/Kitty.app")
  cask "kitty"
end
