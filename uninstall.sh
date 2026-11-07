#!/bin/bash
# Remove Poolsuite for Omarchy.
#   ./uninstall.sh           remove the player, keep the fonts
#   ./uninstall.sh --fonts   also remove the fonts it installed

set -uo pipefail

WIDGET="lucasclgibson.poolsuite"
SHELL_JSON="$HOME/.config/omarchy/shell.json"

command -v poolsuite >/dev/null && poolsuite quit

# Take the widget off the bar.
if [[ -f $SHELL_JSON ]] && jq -e --arg id "$WIDGET" 'any(.bar.layout[][]?; .id == $id)' "$SHELL_JSON" >/dev/null 2>&1; then
  cp "$SHELL_JSON" "$SHELL_JSON.bak.$(date +%s)"
  tmp=$(mktemp)
  jq --arg id "$WIDGET" '.bar.layout |= map_values(if type == "array" then map(select(.id != $id)) else . end)' \
    "$SHELL_JSON" >"$tmp" && cat "$tmp" >"$SHELL_JSON"
  rm -f "$tmp"
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

echo "Removed. If you added the menu entry or keybinding from extras/, delete those lines too."
