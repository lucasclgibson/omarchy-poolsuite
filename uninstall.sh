#!/bin/bash
# Remove Poolsuite for Omarchy (same as `poolsuite uninstall`).
#   --fonts   also remove the retro fonts it installed

set -uo pipefail

WIDGET="lucasclgibson.poolsuite"
SHELL_JSON="$HOME/.config/omarchy/shell.json"
MENU="$HOME/.config/omarchy/extensions/omarchy-menu.jsonc"
SRC="${XDG_DATA_HOME:-$HOME/.local/share}/omarchy-poolsuite"
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

[[ -x $HOME/.local/bin/poolsuite ]] && "$HOME/.local/bin/poolsuite" quit 2>/dev/null

# Take the widget off the bar.
if [[ -f $SHELL_JSON ]] && jq -e --arg id "$WIDGET" 'any(.bar.layout[][]?; .id == $id)' "$SHELL_JSON" >/dev/null 2>&1; then
  cp "$SHELL_JSON" "$SHELL_JSON.bak.$(date +%s)"
  tmp=$(mktemp)
  jq --arg id "$WIDGET" '.bar.layout |= map_values(if type == "array" then map(select(.id != $id)) else . end)' \
    "$SHELL_JSON" >"$tmp" && cat "$tmp" >"$SHELL_JSON"
  rm -f "$tmp"
fi

# Remove the Super+Space menu entry the installer added.
if [[ -f $MENU ]]; then
  sed -i '/^[[:space:]]*"poolsuite"[[:space:]]*:[[:space:]]*{.*"action":"poolsuite".*},\{0,1\}[[:space:]]*$/d' "$MENU"
fi

rm -rf "$HOME/.config/omarchy/plugins/poolsuite"
rm -f "$HOME/.local/bin/poolsuite"
rm -rf "${XDG_DATA_HOME:-$HOME/.local/share}/poolsuite"
rm -rf "${XDG_STATE_HOME:-$HOME/.local/state}/poolsuite"
rm -rf "${XDG_CACHE_HOME:-$HOME/.cache}/poolsuite"

if [[ ${1:-} == "--fonts" ]]; then
  rm -rf "${XDG_DATA_HOME:-$HOME/.local/share}/fonts/poolsuite"
  fc-cache -f >/dev/null 2>&1
fi

# The code itself, when it came from the one-line installer.
[[ $HERE == "$SRC" ]] && rm -rf "$SRC"

echo "Poolsuite removed. The packages it installed (mpv, yt-dlp, …) were left in place."
