#!/usr/bin/env bash

run_macos() {
  if [[ "${APPLY_MACOS_DEFAULTS}" != "true" ]]; then
    warn "Skipping macOS defaults (set APPLY_MACOS_DEFAULTS=true to enable)"
    return
  fi

  if [[ "$(uname)" != "Darwin" ]]; then
    warn "Not on macOS, skipping defaults"
    return
  fi

  log "Applying macOS defaults"

  defaults write NSGlobalDomain AppleShowAllExtensions -bool true
  defaults write com.apple.finder AppleShowAllFiles -bool true
  defaults write com.apple.finder ShowPathbar -bool true
  defaults write com.apple.finder ShowStatusBar -bool true

  defaults write com.apple.dock autohide -bool true
  defaults write com.apple.dock mru-spaces -bool false

  defaults write com.apple.PowerChime ChimeOnNoHardware -bool true

  # Max key repeat and shortest delay from macOS UI sliders
  defaults write NSGlobalDomain KeyRepeat -int 2
  defaults write NSGlobalDomain InitialKeyRepeat -int 15

  # Remap Caps Lock to Escape using macOS native modifier mapping (shows in Settings)
  # 30064771129 = 0x700000039 (Caps Lock), 30064771113 = 0x700000029 (Escape)
  local byhost_plist
  byhost_plist="$(ls "$HOME"/Library/Preferences/ByHost/.GlobalPreferences.*.plist 2>/dev/null | head -n1)"

  local kb_count=0
  while read -r vid pid loc usage_page usage _rest; do
    [[ "$vid" == "VendorID" ]] && continue
    [[ "$usage_page" == "1" && "$usage" == "6" ]] || continue

    local vid_dec=$((16#${vid#0x}))
    local pid_dec=$((16#${pid#0x}))
    local loc_dec=$((16#${loc#0x}))

    # Write both location-specific and location-agnostic keys.
    local keys=(
      "com.apple.keyboard.modifiermapping.${vid_dec}-${pid_dec}-${loc_dec}"
      "com.apple.keyboard.modifiermapping.${vid_dec}-${pid_dec}-0"
    )

    if [[ -n "$byhost_plist" ]]; then
      local key
      for key in "${keys[@]}"; do
        /usr/libexec/PlistBuddy -c "Delete :$key" "$byhost_plist" 2>/dev/null || true
        /usr/libexec/PlistBuddy -c "Add :$key array" "$byhost_plist" 2>/dev/null || true
        /usr/libexec/PlistBuddy -c "Add :$key:0 dict" "$byhost_plist" 2>/dev/null || true
        /usr/libexec/PlistBuddy -c "Add :$key:0:HIDKeyboardModifierMappingSrc integer 30064771129" "$byhost_plist" 2>/dev/null || true
        /usr/libexec/PlistBuddy -c "Add :$key:0:HIDKeyboardModifierMappingDst integer 30064771113" "$byhost_plist" 2>/dev/null || true
      done
      kb_count=$((kb_count + 1))
    fi
  done < <(hidutil list | awk 'f{print} /^Devices:/{f=1}')

  killall cfprefsd 2>/dev/null || true

  if [[ "$kb_count" -gt 0 ]]; then
    log "Applied Caps Lock -> Escape native mapping for $kb_count keyboard device(s)"
  else
    warn "No keyboard devices detected for native modifier mapping"
  fi

  log "Enabling tap to click"
  # Write both modern and legacy trackpad domains to make the setting actually take effect.
  defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true
  defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
  defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
  defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
  killall cfprefsd 2>/dev/null || true

  # Disable Spotlight shortcuts so Raycast can own Cmd+Space
  local symbolic_hotkeys_plist="$HOME/Library/Preferences/com.apple.symbolichotkeys.plist"
  /usr/libexec/PlistBuddy -c "Set :AppleSymbolicHotKeys:64:enabled false" "$symbolic_hotkeys_plist" 2>/dev/null || true
  /usr/libexec/PlistBuddy -c "Set :AppleSymbolicHotKeys:65:enabled false" "$symbolic_hotkeys_plist" 2>/dev/null || true

  # Set Raycast global hotkey to Cmd+Space (keycode 49)
  defaults write com.raycast.macos raycastGlobalHotkey -string "Command-49" 2>/dev/null || true

  # Launch Raycast so Cmd+Space works immediately
  open -a Raycast 2>/dev/null || true

  killall Finder Dock SystemUIServer 2>/dev/null || true
}
