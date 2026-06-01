#!/usr/bin/env bash

run_dotfiles() {
  if [[ -z "$DOTFILES_STOW_DIR" || ! -d "$DOTFILES_STOW_DIR" ]]; then
    warn "Dotfiles stow directory not found at $DOTFILES_STOW_DIR, skipping linking"
    return
  fi

  if ! command -v stow >/dev/null 2>&1; then
    warn "GNU stow is not installed. Run 'bootstrap.sh brew' first (or: brew install stow)."
    return
  fi

  # Explicit list of stow packages to apply on macOS.
  local requested_packages=(zsh pi wezterm btop)
  local packages=()
  local pkg

  for pkg in "${requested_packages[@]}"; do
    if [[ -d "$DOTFILES_STOW_DIR/$pkg" ]]; then
      packages+=("$pkg")
    else
      warn "Dotfiles package not found, skipping: $pkg"
    fi
  done

  if [[ ${#packages[@]} -eq 0 ]]; then
    warn "No valid dotfiles packages selected"
    return
  fi

  # Handle common conflict: existing regular ~/.zshrc file
  if [[ -e "$HOME/.zshrc" && ! -L "$HOME/.zshrc" ]]; then
    local backup_path="$HOME/.zshrc.bootstrap-backup.$(date +%Y%m%d%H%M%S)"
    warn "Found existing non-symlink ~/.zshrc, backing up to $backup_path"
    mv "$HOME/.zshrc" "$backup_path"
  fi

  log "Stowing selected dotfiles packages from $DOTFILES_STOW_DIR"
  (
    cd "$DOTFILES_STOW_DIR"
    stow --target="$HOME" --restow "${packages[@]}"
  )

  log "Stowed packages: ${packages[*]}"
}
