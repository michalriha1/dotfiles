#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BREWFILE="$SCRIPT_DIR/Brewfile"
DOTFILES_ROOT="${HOME}/workspace/personal"
DOTFILES_REPO_URL="${DOTFILES_REPO_URL:-https://github.com/michalriha1/dotfiles.git}"
DOTFILES_DIR="${DOTFILES_ROOT}/dotfiles"
DOTFILES_STOW_DIR="${DOTFILES_DIR}/dotfiles"
APPLY_MACOS_DEFAULTS="${APPLY_MACOS_DEFAULTS:-true}"

source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/10-homebrew.sh"
source "$SCRIPT_DIR/20-ssh.sh"
source "$SCRIPT_DIR/30-dotfiles.sh"
source "$SCRIPT_DIR/40-cli.sh"
source "$SCRIPT_DIR/50-macos.sh"

usage() {
  cat <<'EOF'
Usage:
  ./bootstrap.sh                # run all categories
  ./bootstrap.sh brew ssh       # run only selected categories

Categories:
  brew      Homebrew + Brewfile packages
  ssh       SSH key setup
  dotfiles  Link ~/workspace/personal/dotfiles/dotfiles packages into $HOME
  shell     Oh My Zsh + plugins + powerlevel10k
  macos     macOS defaults tweaks
EOF
}

print_next_steps() {
  local public_key_path="$HOME/.ssh/id_ed25519.pub"

  log "Next manual steps"
  printf "1. Add SSH key to GitHub:\n"

  if [[ -f "$public_key_path" ]]; then
    printf "\n"
    cat "$public_key_path"
    printf "\n"
  else
    warn "SSH public key not found at $public_key_path"
  fi

  printf "2. Switch dotfiles repo remote to SSH:\n"
  printf "   ```bash\n"
  printf "   cd ~/workspace/personal/dotfiles\n"
  printf "   git remote set-url origin git@github.com:michalriha1/dotfiles.git\n"
  printf "   git remote -v\n"
  printf "   ```\n"
  printf "3. Setup:\n"
  printf "   - better display\n"
  printf "   - ice\n"
  printf "   - start Obsidian\n"
  printf "Final step: Reboot your Mac\n"

}

ensure_dotfiles_repo() {
  mkdir -p "$DOTFILES_ROOT"
  if [[ ! -d "$DOTFILES_DIR/.git" ]]; then
    log "Cloning dotfiles into $DOTFILES_DIR"
    git clone "$DOTFILES_REPO_URL" "$DOTFILES_DIR"
  fi
}

run_category() {
  case "$1" in
    brew) run_homebrew ;;
    ssh) run_ssh ;;
    dotfiles) run_dotfiles ;;
    shell) run_shell ;;
    macos) run_macos ;;
    -h|--help|help)
      usage
      exit 0
      ;;
    *)
      warn "Unknown category: $1"
      usage
      exit 1
      ;;
  esac
}

main() {
  log "Bootstrap started"

  ensure_dotfiles_repo

  if [[ $# -eq 0 ]]; then
    run_homebrew
    run_ssh
    run_dotfiles
    run_shell
    run_macos
  else
    local category
    for category in "$@"; do
      run_category "$category"
    done
  fi

  print_next_steps

  log "Done. Restart terminal (or run: exec zsh)."
}

main "$@"
