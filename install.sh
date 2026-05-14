#!/usr/bin/env bash
# set -e

# DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# echo "Installing personal dotfiles from $DOTFILES_DIR"

# # Git config
# if [ -f "$DOTFILES_DIR/.gitconfig" ]; then
#   ln -sf "$DOTFILES_DIR/.gitconfig" "$HOME/.gitconfig"
# fi

# # Bash config
# if [ -f "$DOTFILES_DIR/.bashrc" ]; then
#   ln -sf "$DOTFILES_DIR/.bashrc" "$HOME/.bashrc"
# fi

# # Zsh config
# if [ -f "$DOTFILES_DIR/.zshrc" ]; then
#   ln -sf "$DOTFILES_DIR/.zshrc" "$HOME/.zshrc"
# fi

# # PowerShell profile
# if command -v pwsh >/dev/null 2>&1; then
#   mkdir -p "$HOME/.config/powershell"
#   if [ -f "$DOTFILES_DIR/powershell/Microsoft.PowerShell_profile.ps1" ]; then
#     ln -sf "$DOTFILES_DIR/powershell/Microsoft.PowerShell_profile.ps1" \
#       "$HOME/.config/powershell/Microsoft.PowerShell_profile.ps1"
#   fi
# fi

echo "Dotfiles installed."