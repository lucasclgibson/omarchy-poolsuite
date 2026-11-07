import QtQuick

// A 1-bit pixel-art icon: `rows` is a list of strings, "#" = ink. Each art
// pixel is `px` logical pixels (2x2 device pixels on this screen), drawn
// without antialiasing so it stays crisp like the site's sprites.
Item {
  id: icon
  property var rows: []
  // Defaults to the player palette's ink (see Player.qml `isPalette`).
  readonly property var pal: {
    for (var p = parent; p; p = p.parent) if (p.isPalette === true) return p
    return null
  }
  property color color: pal ? pal.ink : "#000000"
  property real px: 1

  readonly property var cells: {
    var out = []
    for (var y = 0; y < rows.length; y++)
      for (var x = 0; x < rows[y].length; x++)
        if (rows[y][x] === "#") out.push({ x: x, y: y })
    return out
  }
  implicitWidth: (rows.length ? rows[0].length : 0) * px
  implicitHeight: rows.length * px
  width: implicitWidth
  height: implicitHeight

  Repeater {
    model: icon.cells
    Rectangle {
      x: modelData.x * icon.px; y: modelData.y * icon.px
      width: icon.px; height: icon.px
      color: icon.color
      antialiasing: false
    }
  }
}
