import QtQuick
import qs.Commons

// Player text. Poolsuite theme: Chicago Kare (open-source bitmap Chicago) at
// its native 16px, or the IBM VGA 8x16 DOS face with `dos: true`. Omarchy
// theme: the user's Omarchy font. Colours come from the player's palette,
// found by walking up to the item that declares `isPalette`.
Text {
  property bool dos: false
  readonly property var pal: {
    for (var p = parent; p; p = p.parent) if (p.isPalette === true) return p
    return null
  }
  readonly property bool classic: !pal || pal.classic

  textFormat: Text.PlainText
  color: pal ? pal.ink : "#000000"
  font.family: classic ? (dos ? "PxPlus IBM VGA 8x16" : "Chicago Kare") : Style.fontFamily
  font.pixelSize: classic ? 16 : 13
  font.bold: !classic && !dos
  font.hintingPreference: Font.PreferFullHinting
  renderType: classic ? Text.NativeRendering : Text.QtRendering
  antialiasing: !classic
}
