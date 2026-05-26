#!/usr/bin/env bash

SHELL_CONFIG_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/illogical-impulse/config.json"

TARGET_LINK="${XDG_CONFIG_HOME:-$HOME/.config}/hypr/custom/lockscreen-wallpaper"

LOG="${XDG_CACHE_HOME:-$HOME/.cache}/hyprlock-wallpaper-sync.log"

{
  echo "---- $(date) ----"

  WALL="$(jq -r '.background.wallpaperPath' "$SHELL_CONFIG_FILE")"

  [ -f "$WALL" ] || {
    echo "ERROR: wallpaper does not exist: $WALL"
    exit 1
  }

  echo "Wallpaper:"
  echo "$WALL"

  ln -sfn "$WALL" "$TARGET_LINK"

  echo "Symlink updated:"
  ls -l "$TARGET_LINK"

} >>"$LOG" 2>&1
