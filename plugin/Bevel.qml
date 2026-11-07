import QtQuick

// Poolsuite's raised box: 1px ink outline with a 2px bottom edge and small
// stepped (non-antialiased) corners. `sunk` flips it while pressed.
//
// Corners: a standalone box rounds all four. Keys joined into a strip round
// only the strip's outer ends (roundLeft on the first, roundRight on the last)
// and stay square where they meet, so the strip reads as one piece. The fill
// uses radius - 1 so it sits concentric inside the outline.
Item {
  id: b
  readonly property var pal: {
    for (var p = parent; p; p = p.parent) if (p.isPalette === true) return p
    return null
  }
  property color fill: pal ? pal.paper : "#f9f0e9"
  property color ink: pal ? pal.ink : "#000000"
  property real radius: 4
  property bool roundLeft: true
  property bool roundRight: true
  property bool sunk: false
  default property alias content: inner.data

  readonly property real outerL: roundLeft ? radius : 0
  readonly property real outerR: roundRight ? radius : 0
  readonly property real innerL: Math.max(0, outerL - 1)
  readonly property real innerR: Math.max(0, outerR - 1)

  Rectangle {
    anchors.fill: parent
    color: b.ink
    antialiasing: false
    topLeftRadius: b.outerL; bottomLeftRadius: b.outerL
    topRightRadius: b.outerR; bottomRightRadius: b.outerR
  }
  Rectangle {
    id: inner
    anchors.fill: parent
    anchors.leftMargin: 1; anchors.rightMargin: 1
    anchors.topMargin: b.sunk ? 2 : 1
    anchors.bottomMargin: b.sunk ? 1 : 2
    color: b.fill
    antialiasing: false
    topLeftRadius: b.innerL; bottomLeftRadius: b.innerL
    topRightRadius: b.innerR; bottomRightRadius: b.innerR
  }
}
