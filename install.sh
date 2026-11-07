#!/bin/bash
# Poolsuite for Omarchy installer. One line:
#
#   curl -fsSL https://raw.githubusercontent.com/lucasclgibson/omarchy-poolsuite/main/install.sh | bash
#
# It fetches the code into ~/.local/share/omarchy-poolsuite, installs any
# missing packages (asks for your password once), fetches the classic-look
# fonts, puts the palm tree on your bar and adds "Poolsuite" to the
# Super+Space menu. Run it again any time to update; `poolsuite update` does
# the same. Remove everything with `poolsuite uninstall`.
#
# From a clone you can also run ./install.sh directly; the installed files are
# then symlinked to that clone.

set -euo pipefail

REPO_URL="${POOLSUITE_REPO:-https://github.com/lucasclgibson/omarchy-poolsuite.git}"
SRC="${XDG_DATA_HOME:-$HOME/.local/share}/omarchy-poolsuite"
WIDGET="lucasclgibson.poolsuite"

say() { printf '\033[1;36m==>\033[0m \033[1m%s\033[0m\n' "$*"; }
warn() { printf '\033[33m%s\033[0m\n' "$*" >&2; }
die() { printf '\033[31m%s\033[0m\n' "$*" >&2; exit 1; }

# ---- Omarchy? -------------------------------------------------------------------
command -v omarchy >/dev/null && command -v omarchy-bar >/dev/null && command -v omarchy-shell >/dev/null ||
  die "This needs Omarchy (https://omarchy.org) with its Quickshell bar."

# ---- piped from curl: fetch the code, then run the real installer from it ----------
here=""
if [[ -n ${BASH_SOURCE[0]:-} && -f ${BASH_SOURCE[0]} ]]; then
  here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
fi
if [[ -z $here || ! -f $here/plugin/manifest.json ]]; then
  command -v git >/dev/null || omarchy pkg add git
  if [[ -d $SRC/.git ]]; then
    say "Updating Poolsuite"
    git -C "$SRC" pull --ff-only -q
  else
    say "Downloading Poolsuite"
    git clone -q --depth 1 "$REPO_URL" "$SRC"
  fi
  # Give the real installer the terminal (for the sudo prompt) when there is one.
  if (exec </dev/tty) 2>/dev/null; then exec bash "$SRC/install.sh" "$@" </dev/tty; fi
  exec bash "$SRC/install.sh" "$@"
fi
REPO=$here

# ---- packages -----------------------------------------------------------------------
PKGS=(mpv mpv-mpris yt-dlp jq socat unzip curl)
missing=()
for p in "${PKGS[@]}"; do pacman -Q "$p" >/dev/null 2>&1 || missing+=("$p"); done
if ((${#missing[@]})); then
  say "Installing packages: ${missing[*]}"
  omarchy pkg add "${missing[@]}"
fi

# ---- files (symlinked to the code, so updating the code updates everything) --------
BIN="$HOME/.local/bin"
SHARE="${XDG_DATA_HOME:-$HOME/.local/share}/poolsuite"
PLUGIN="$HOME/.config/omarchy/plugins/poolsuite"
FONTS="${XDG_DATA_HOME:-$HOME/.local/share}/fonts/poolsuite"

say "Installing the player"
chmod +x "$REPO/bin/poolsuite" "$REPO/install.sh" "$REPO/uninstall.sh"
mkdir -p "$BIN" "$SHARE" "$(dirname "$PLUGIN")"
ln -sfn "$REPO/bin/poolsuite" "$BIN/poolsuite"
ln -sfn "$REPO/share/guard.lua" "$SHARE/guard.lua"
[[ -L $PLUGIN || ! -e $PLUGIN ]] || rm -rf "$PLUGIN"
ln -sfn "$REPO/plugin" "$PLUGIN"

# ---- fonts for the classic look (from their original sources, checked) --------------
CHICAGO_URL="https://raw.githubusercontent.com/KingDuane/Chicago-Kare/dca7a9e4f2b971e39cf3a5e8a3f9309d4293d56d/ChicagoKare-Regular.ttf"
CHICAGO_SHA="23d870a6138aedf9c8479a537f7da47881bf2d6fef51d275b4031c67513057af"
CHICAGO_LICENSE="https://raw.githubusercontent.com/KingDuane/Chicago-Kare/dca7a9e4f2b971e39cf3a5e8a3f9309d4293d56d/LICENSE"
VGA_URL="https://int10h.org/oldschool-pc-fonts/download/oldschool_pc_font_pack_v2.2_linux.zip"
VGA_SHA="b30dc3ecc9931ad2dd8be7517dd01813c8834a1911b582ab7643191b41a3d759"

fetch() { # fetch <url> <sha256> <out>
  curl -fsSL "$1" -o "$3" && echo "$2  $3" | sha256sum -c --quiet - >/dev/null 2>&1
}

mkdir -p "$FONTS"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
if [[ ! -f $FONTS/ChicagoKare-Regular.ttf || ! -f $FONTS/PxPlus_IBM_VGA_8x16.ttf ]]; then
  say "Fetching the retro fonts"
  if fetch "$CHICAGO_URL" "$CHICAGO_SHA" "$tmp/ChicagoKare-Regular.ttf"; then
    cp "$tmp/ChicagoKare-Regular.ttf" "$FONTS/"
    curl -fsSL "$CHICAGO_LICENSE" -o "$FONTS/ChicagoKare-LICENSE" || true
  else
    warn "Couldn't fetch Chicago Kare; the classic look will use a fallback font."
  fi
  if fetch "$VGA_URL" "$VGA_SHA" "$tmp/pc.zip"; then
    unzip -o -j -q "$tmp/pc.zip" "ttf - Px (pixel outline)/PxPlus_IBM_VGA_8x16.ttf" LICENSE.TXT -d "$tmp"
    cp "$tmp/PxPlus_IBM_VGA_8x16.ttf" "$FONTS/"
    cp "$tmp/LICENSE.TXT" "$FONTS/int10h-LICENSE.TXT"
  else
    warn "Couldn't fetch the IBM VGA font; the classic look will use a fallback font."
  fi
  fc-cache -f "$FONTS" >/dev/null 2>&1 || true
fi

# ---- bar ------------------------------------------------------------------------------
SHELL_JSON="$HOME/.config/omarchy/shell.json"
if jq -e --arg id "$WIDGET" 'any(.bar.layout[][]?; .id == $id)' "$SHELL_JSON" >/dev/null 2>&1; then
  :
else
  say "Adding the palm tree to your bar"
  omarchy-bar put "$WIDGET" --section right --index 0 >/dev/null 2>&1 || true
  # Make sure it landed in shell.json (the shell hot-reloads it).
  if ! jq -e --arg id "$WIDGET" 'any(.bar.layout[][]?; .id == $id)' "$SHELL_JSON" >/dev/null 2>&1; then
    if [[ -f $SHELL_JSON ]] && jq --arg id "$WIDGET" '.bar.layout.right = [{id: $id}] + (.bar.layout.right // [])' \
      "$SHELL_JSON" >"$tmp/shell.json" 2>/dev/null; then
      cat "$tmp/shell.json" >"$SHELL_JSON"
    else
      warn "Couldn't place the widget; add it with: omarchy bar put $WIDGET --section right --index 0"
    fi
  fi
fi

# ---- Super+Space menu -------------------------------------------------------------------
MENU="$HOME/.config/omarchy/extensions/omarchy-menu.jsonc"
ENTRY='  "poolsuite": {"icon":"󱁕","label":"Poolsuite","description":"Ultra-summer internet radio in the bar","action":"poolsuite","aliases":["radio","music"]},'
if [[ -f $MENU ]] && grep -q '"poolsuite"[[:space:]]*:' "$MENU"; then
  :
else
  say "Adding Poolsuite to the Super+Space menu"
  mkdir -p "$(dirname "$MENU")"
  if [[ -f $MENU ]] && grep -q '^[[:space:]]*{[[:space:]]*$' "$MENU"; then
    # Insert right after the opening brace (trailing commas are fine in this file).
    awk -v entry="$ENTRY" '!done && /^[[:space:]]*\{[[:space:]]*$/ { print; print entry; done = 1; next } { print }' "$MENU" >"$tmp/menu" &&
      cat "$tmp/menu" >"$MENU"
  elif [[ ! -f $MENU ]]; then
    printf '{\n%s\n}\n' "$ENTRY" >"$MENU"
  else
    warn "Couldn't add the menu entry automatically; see extras/omarchy-menu.jsonc"
  fi
fi

cat <<EOF

$(printf '\033[1m')Poolsuite is installed.$(printf '\033[0m')

  Click the palm tree in your bar, pick it from the Super+Space menu,
  or run:  poolsuite

  poolsuite theme poolsuite   classic System 7 look (or: omarchy)
  poolsuite update            get the latest version
  poolsuite uninstall         remove it

EOF
