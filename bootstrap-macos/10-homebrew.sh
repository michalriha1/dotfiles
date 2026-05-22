#!/usr/bin/env bash

ensure_sudo_for_homebrew_install() {
  if [[ "$(uname -s)" != "Darwin" ]] || command -v brew >/dev/null 2>&1; then
    return
  fi

  if ! groups "$USER" | tr ' ' '\n' | grep -qx admin; then
    warn "Homebrew install requires an administrator account on macOS."
    warn "Current user '$USER' is not in the admin group."
    warn "Make this user an admin in System Settings > Users & Groups, then rerun ./bootstrap.sh brew."
    warn "Or skip Homebrew for now with: ./bootstrap.sh ssh dotfiles shell macos"
    return 1
  fi

  log "Checking sudo access for Homebrew install"
  sudo -v
}

ensure_homebrew() {
  if command -v brew >/dev/null 2>&1; then
    log "Homebrew already installed"
  else
    ensure_sudo_for_homebrew_install
    log "Installing Homebrew"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi

  if [[ -x "/opt/homebrew/bin/brew" ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x "/usr/local/bin/brew" ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi

  brew update
}

install_from_brewfile() {
  if [[ ! -f "$BREWFILE" ]]; then
    warn "Brewfile not found at $BREWFILE, skipping brew bundle"
    return
  fi

  log "Installing formulas/casks from Brewfile"
  brew bundle --file="$BREWFILE"
}

run_homebrew() {
  ensure_homebrew
  install_from_brewfile
}
