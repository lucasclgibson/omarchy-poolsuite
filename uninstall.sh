#!/bin/bash
# Remove Poolsuite for Omarchy when it was installed with install.sh
# (same as `poolsuite uninstall`). For the AUR package: `poolsuite unsetup`,
# then `yay -R omarchy-poolsuite`.
#   --fonts   also remove the retro fonts it installed

set -uo pipefail

HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
SRC="${XDG_DATA_HOME:-$HOME/.local/share}/omarchy-poolsuite"

# Bar, menu, plugin link, track lists.
bash "$HERE/bin/poolsuite" unsetup

rm -f "$HOME/.local/bin/poolsuite"
rm -rf "${XDG_DATA_HOME:-$HOME/.local/share}/poolsuite"   # older versions

if [[ ${1:-} == "--fonts" ]]; then
  rm -rf "${XDG_DATA_HOME:-$HOME/.local/share}/fonts/poolsuite"
  fc-cache -f >/dev/null 2>&1
fi

# The code itself, when it came from the one-line installer.
[[ $HERE == "$SRC" ]] && rm -rf "$SRC"

echo "Poolsuite removed. The packages it installed (mpv, yt-dlp, …) were left in place."
