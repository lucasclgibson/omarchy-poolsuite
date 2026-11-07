#!/bin/bash
# Install Poolsuite for Omarchy.
#
#   ./install.sh          copy the files into place
#   ./install.sh --link   symlink them to this checkout instead (for hacking on it)
#
# Installs:
#   ~/.local/bin/poolsuite                    the radio engine + CLI
#   ~/.local/share/poolsuite/guard.lua        mpv safeguard
#   ~/.config/omarchy/plugins/poolsuite/      the bar widget + player
#   ~/.local/share/fonts/poolsuite/           Chicago Kare + IBM VGA 8x16 (classic look)
# and puts the widget at the start of the bar's right section.

set -euo pipefail

REPO=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
WIDGET="lucasclgibson.poolsuite"
BIN="$HOME/.local/bin"
SHARE="${XDG_DATA_HOME:-$HOME/.local/share}/poolsuite"
PLUGIN="$HOME/.config/omarchy/plugins/poolsuite"
FONTS="${XDG_DATA_HOME:-$HOME/.local/share}/fonts/poolsuite"

LINK=0
[[ ${1:-} == "--link" ]] && LINK=1

say() { printf '\033[1m%s\033[0m\n' "$*"; }

# ---- dependencies -------------------------------------------------------------
missing=()
for cmd in mpv yt-dlp jq socat busctl curl unzip fc-cache omarchy-bar omarchy-shell; do
  command -v "$cmd" >/dev/null || missing+=("$cmd")
done
mpris_found=0
for f in /etc/mpv/scripts/mpris.so /usr/lib/mpv-mpris/mpris.so "$HOME/.config/mpv/scripts/mpris.so"; do
  [[ -e $f ]] && mpris_found=1
done
((mpris_found)) || missing+=("mpv-mpris")

if ((${#missing[@]})); then
  echo "Missing: ${missing[*]}"
  if [[ " ${missing[*]} " == *" omarchy-bar "* || " ${missing[*]} " == *" omarchy-shell "* ]]; then
    echo "This needs Omarchy (https://omarchy.org) with its Quickshell bar."
  fi
  echo "Install the packages with:  omarchy pkg add mpv mpv-mpris yt-dlp jq socat"
  exit 1
fi

# ---- files ----------------------------------------------------------------------
place() { # place <source> <target>
  mkdir -p "$(dirname "$2")"
  if ((LINK)); then ln -sfn "$1" "$2"; else rm -rf "$2"; cp -r "$1" "$2"; fi
}

say "Installing files"
place "$REPO/bin/poolsuite" "$BIN/poolsuite"
chmod +x "$REPO/bin/poolsuite"
place "$REPO/share/guard.lua" "$SHARE/guard.lua"
if ((LINK)); then
  rm -rf "$PLUGIN"
  place "$REPO/plugin" "$PLUGIN"
else
  mkdir -p "$PLUGIN"
  cp "$REPO"/plugin/* "$PLUGIN/"
fi

case ":$PATH:" in
  *":$BIN:"*) ;;
  *) echo "Note: $BIN is not on your PATH." ;;
esac

# ---- fonts (classic look) -----------------------------------------------------
# Fetched from their original sources and checked, not bundled here.
CHICAGO_URL="https://raw.githubusercontent.com/KingDuane/Chicago-Kare/dca7a9e4f2b971e39cf3a5e8a3f9309d4293d56d/ChicagoKare-Regular.ttf"
CHICAGO_SHA="23d870a6138aedf9c8479a537f7da47881bf2d6fef51d275b4031c67513057af"
CHICAGO_LICENSE="https://raw.githubusercontent.com/KingDuane/Chicago-Kare/dca7a9e4f2b971e39cf3a5e8a3f9309d4293d56d/LICENSE"
VGA_URL="https://int10h.org/oldschool-pc-fonts/download/oldschool_pc_font_pack_v2.2_linux.zip"
VGA_SHA="b30dc3ecc9931ad2dd8be7517dd01813c8834a1911b582ab7643191b41a3d759"

mkdir -p "$FONTS"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

fetch() { # fetch <url> <sha256> <out>
  curl -fsSL "$1" -o "$3"
  echo "$2  $3" | sha256sum -c --quiet - || { echo "Checksum mismatch for $1" >&2; return 1; }
}

if [[ ! -f $FONTS/ChicagoKare-Regular.ttf ]]; then
  say "Fetching Chicago Kare (MIT)"
  fetch "$CHICAGO_URL" "$CHICAGO_SHA" "$tmp/ChicagoKare-Regular.ttf"
  cp "$tmp/ChicagoKare-Regular.ttf" "$FONTS/"
  curl -fsSL "$CHICAGO_LICENSE" -o "$FONTS/ChicagoKare-LICENSE" || true
fi
if [[ ! -f $FONTS/PxPlus_IBM_VGA_8x16.ttf ]]; then
  say "Fetching IBM VGA 8x16 from the Ultimate Oldschool PC Font Pack (CC BY-SA 4.0)"
  fetch "$VGA_URL" "$VGA_SHA" "$tmp/pc.zip"
  unzip -o -j -q "$tmp/pc.zip" "ttf - Px (pixel outline)/PxPlus_IBM_VGA_8x16.ttf" LICENSE.TXT -d "$tmp"
  cp "$tmp/PxPlus_IBM_VGA_8x16.ttf" "$FONTS/"
  cp "$tmp/LICENSE.TXT" "$FONTS/int10h-LICENSE.TXT"
fi
fc-cache -f "$FONTS" >/dev/null

# ---- bar ------------------------------------------------------------------------
if jq -e --arg id "$WIDGET" 'any(.bar.layout[][]?; .id == $id)' "$HOME/.config/omarchy/shell.json" >/dev/null 2>&1; then
  say "Widget already on the bar"
else
  say "Adding the widget to the bar"
  omarchy-bar put "$WIDGET" --section right --index 0 >/dev/null
fi

cat <<EOF

Done. Click the palm tree in your bar, or run:  poolsuite

Optional extras (see README):
  * Super+Space menu entry and a keybinding: extras/
  * Classic System 7 look:  poolsuite theme poolsuite

Track lists are fetched in the background the first time each channel plays.
EOF
