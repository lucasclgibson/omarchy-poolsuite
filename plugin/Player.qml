import QtQuick
import qs.Commons
import qs.Commons as Commons

// The popup, built as a little Poolsuite window: 1-bit pixel sprites, raised
// keys with heavy bottom edges, a play key, an action key and a dither block.
//
// Two palettes (the widget's `theme` setting, toggled from the title bar):
//   "omarchy"   follows the current Omarchy theme and font, live
//   "poolsuite" System 7 cream, aqua and pink with Chicago + DOS VGA type
// PText, PixelIcon and Bevel find this item through `isPalette` and take
// their default colours from it.
Rectangle {
  id: ui

  required property var host
  readonly property var p: host.player

  // ---- palette --------------------------------------------------------------
  readonly property bool isPalette: true
  readonly property bool classic: host.themeName === "poolsuite"

  function mix(a, b, t) {
    return Qt.rgba(a.r + (b.r - a.r) * t, a.g + (b.g - a.g) * t, a.b + (b.b - a.b) * t, 1)
  }
  function alpha(c, a) { return Qt.rgba(c.r, c.g, c.b, a) }

  readonly property color themeBg: Commons.Color.popups.background
  readonly property color themeFg: Commons.Color.popups.text
  readonly property color themeAccent: Commons.Color.accent
  readonly property color themeUrgent: Commons.Color.urgent

  readonly property color paper:   classic ? "#f9f0e9" : themeBg                        // window
  readonly property color ink:     classic ? "#000000" : themeFg                        // outlines, text
  readonly property color card:    classic ? "#ffffff" : mix(themeBg, themeFg, 0.07)    // raised panels
  readonly property color aqua:    classic ? "#afe2e5" : themeAccent                    // play key
  readonly property color onAqua:  classic ? "#000000" : themeBg                        // glyph on play key
  readonly property color pink:    classic ? "#f6d5d5" : mix(themeBg, themeUrgent, 0.4) // action key
  readonly property color grey:    classic ? "#7d7d7d" : mix(themeFg, themeBg, 0.55)    // disabled glyphs
  readonly property color rule:    classic ? "#d6cec6" : mix(themeBg, themeFg, 0.22)    // hairlines, empty ticks
  readonly property color lcd:     classic ? "#2a2a2a" : mix(themeBg, "#000000", 0.4)   // screen
  readonly property color lcdInk:  classic ? "#f9f0e9" : themeAccent                    // screen ink
  readonly property color onAir:   classic ? "#fb5858" : themeUrgent                    // ON AIR dot

  property bool menuOpen: false

  implicitHeight: col.implicitHeight + 14
  color: paper
  antialiasing: false

  function fmt(secs) {
    var s = Math.max(0, Math.floor(secs || 0))
    var m = Math.floor(s / 60); s = s % 60
    return m + ":" + (s < 10 ? "0" : "") + s
  }
  function slug() {
    var t = (host.trackArtist ? host.trackArtist + "_" : "") + host.trackTitle
    t = t.toLowerCase().replace(/[^a-z0-9]+/g, "_").replace(/^_+|_+$/g, "")
    return t ? t.slice(0, 30) + ".mp3" : "poolsuite_fm.mp3"
  }
  readonly property string status: host.starting ? "Tuning…"
    : host.playing ? "Playing" : host.running ? "Paused"
    : host.errorText ? "Offline" : "Stopped"

  // ---- sprites --------------------------------------------------------------
  readonly property var sClose: ["#.....#", ".#...#.", "..#.#..", "...#...", "..#.#..", ".#...#.", "#.....#"]
  readonly property var sPalm: [
    "..####.###..",
    ".#...###..#.",
    "#..##.#.##.#",
    "..#..###..#.",
    ".#..#.#.#..#",
    ".#..#.#..#..",
    "...#..#.....",
    ".......#....",
    ".......#....",
    "......##....",
    "....#####...",
    ".#########.."
  ]
  readonly property var sPlay: ["#....", "##...", "###..", "####.", "#####", "####.", "###..", "##...", "#...."]
  readonly property var sPause: ["##.##", "##.##", "##.##", "##.##", "##.##", "##.##", "##.##", "##.##", "##.##"]
  readonly property var sStop: [".#####.", "#######", "#######", "#######", "#######", "#######", ".#####."]
  readonly property var sPrev: ["#...#...#", "#..##..##", "#.###.###", "#########", "#.###.###", "#..##..##", "#...#...#"]
  readonly property var sNext: ["#...#...#", "##..##..#", "###.###.#", "#########", "###.###.#", "##..##..#", "#...#...#"]
  readonly property var sDice: [".#.....##..", "###....#.#.", ".#.....#..#", ".......#...", ".......#...", "....####...", "...#####...", "...####...."]
  readonly property var sSmallL: ["..#", ".##", "###", ".##", "..#"]
  readonly property var sSmallR: ["#..", "##.", "###", "##.", "#.."]
  readonly property var sTri: ["#..", "##.", "#.."]
  readonly property var sDown: ["#####", ".###.", "..#.."]
  readonly property var sCheck: ["......#", ".....##", "#...##.", "##.##..", ".###...", "..#...."]
  readonly property var sSpeaker: ["...##..", "..#.#..", "##..#..", "#...#.#", "#...#.#", "##..#..", "..#.#..", "...##.."]

  Column {
    id: col
    x: 7; y: 6
    width: parent.width - 14
    spacing: 6

    // ---- title bar --------------------------------------------------------
    Item {
      width: parent.width; height: 20
      PixelIcon {
        rows: ui.sClose
        anchors.verticalCenter: parent.verticalCenter; x: 3
        MouseArea { anchors.fill: parent; anchors.margins: -5; cursorShape: Qt.PointingHandCursor; onClicked: ui.host.close() }
      }
      Rectangle {
        id: palmTile
        x: 18; width: 18; height: 18; radius: 2; color: ui.ink; antialiasing: false
        anchors.verticalCenter: parent.verticalCenter
        PixelIcon { rows: ui.sPalm; color: ui.paper; anchors.centerIn: parent }
      }
      // Theme switch: Omarchy theme <-> classic Poolsuite.
      Rectangle {
        id: themeKey
        anchors.left: palmTile.right; anchors.leftMargin: 6
        anchors.verticalCenter: parent.verticalCenter
        width: themeLabel.implicitWidth + 12; height: 18; radius: 2
        color: themeMouse.containsMouse ? ui.ink : "transparent"
        border.color: ui.ink; border.width: 1
        antialiasing: false
        PText {
          id: themeLabel
          anchors.centerIn: parent
          dos: true
          font.pixelSize: ui.classic ? 16 : 11
          color: themeMouse.containsMouse ? ui.paper : ui.ink
          text: ui.classic ? "CLASSIC" : "OMARCHY"
        }
        MouseArea {
          id: themeMouse
          anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
          onClicked: ui.host.setTheme(ui.classic ? "omarchy" : "poolsuite")
        }
      }
      Text {
        id: wordmark
        anchors.right: parent.right; anchors.rightMargin: 3
        anchors.verticalCenter: parent.verticalCenter
        text: "POOLSUITE"
        textFormat: Text.PlainText
        color: ui.ink
        font.family: ui.classic ? "Nimbus Roman" : Style.fontFamily
        font.bold: true
        font.pixelSize: ui.classic ? 21 : 16
        font.letterSpacing: ui.classic ? 0 : 1
        renderType: ui.classic ? Text.NativeRendering : Text.QtRendering
        // Classic: rendered at 1x and scaled up without smoothing (pixelated Times).
        layer.enabled: ui.classic
        layer.smooth: false
        layer.textureSize: Qt.size(Math.ceil(width), Math.ceil(height))
        transform: Scale { xScale: ui.classic ? 0.74 : 1; origin.x: wordmark.width }
      }
    }

    // ---- screen: now-playing LCD + file bar ---------------------------------
    Rectangle {
      width: parent.width; height: 86
      color: ui.ink; radius: 4; antialiasing: false
      Rectangle {
        id: lcdFace
        x: 1; y: 1; width: parent.width - 2; height: parent.height - 19
        topLeftRadius: 3; topRightRadius: 3; color: ui.lcd; antialiasing: false

        // Progress as the screen's top rule.
        Rectangle { x: 10; y: 9; width: parent.width - 20; height: 2; color: ui.alpha(ui.lcdInk, 0.2); antialiasing: false }
        Rectangle {
          x: 10; y: 9; height: 2; color: ui.lcdInk; antialiasing: false
          width: Math.round((parent.width - 20) * (ui.p && ui.p.length > 0 ? Math.min(1, ui.p.position / ui.p.length) : 0))
        }

        PText {
          x: 10; y: 18; dos: true; color: ui.lcdInk
          text: ui.host.channelName(ui.host.channel).toUpperCase()
        }
        PText {
          x: 10; y: 36; dos: true; color: ui.alpha(ui.lcdInk, 0.55)
          text: ui.status.toUpperCase()
        }

        Row {
          anchors.right: parent.right; anchors.rightMargin: 10
          anchors.bottom: parent.bottom; anchors.bottomMargin: 9
          spacing: 3
          Repeater {
            model: 11
            Rectangle {
              id: bar
              property int level: 2 + Math.round(index * 0.7)
              width: 5; color: ui.lcdInk; antialiasing: false
              height: 3 * Math.min(ui.host.playing ? level : 1, 9)
              anchors.bottom: parent.bottom
              Timer {
                interval: 150 + index * 17; repeat: true
                running: ui.host.playing && ui.host.popupOpen && !Style.reduceMotion
                onTriggered: bar.level = 1 + Math.floor(Math.random() * (3 + index * 0.75))
              }
            }
          }
        }
      }

      // File bar: tiny keys, track as a file name, time on the right.
      Item {
        x: 1; y: parent.height - 18; width: parent.width - 2; height: 17
        Rectangle {
          x: 2; y: 2; width: 13; height: 13; radius: 2; color: ui.paper; antialiasing: false
          PixelIcon { rows: ui.sSmallL; color: ui.ink; anchors.centerIn: parent }
          MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: if (ui.p) ui.p.previous() }
        }
        Rectangle {
          x: 17; y: 2; width: 13; height: 13; radius: 2; color: ui.paper; antialiasing: false
          PixelIcon { rows: ui.sSmallR; color: ui.ink; anchors.centerIn: parent }
          MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: if (ui.p) ui.p.next() }
        }
        PText {
          x: 38; anchors.verticalCenter: parent.verticalCenter
          width: parent.width - 38 - timeText.width - 14
          elide: Text.ElideRight
          color: ui.paper
          text: ui.slug()
        }
        PText {
          id: timeText
          anchors.right: parent.right; anchors.rightMargin: 6
          anchors.verticalCenter: parent.verticalCenter
          color: ui.paper
          text: ui.p && ui.p.length > 0 ? ui.fmt(ui.p.position) + "/" + ui.fmt(ui.p.length) : "--:--"
        }
      }
    }

    // ---- now playing card -------------------------------------------------
    Bevel {
      width: parent.width; height: 64; fill: ui.card
      Column {
        x: 10; y: 8; width: parent.width - 20; spacing: 5
        Row {
          spacing: 6
          PText { text: ui.host.channelName(ui.host.channel) + ": " + (ui.host.running ? "ON AIR" : "OFF AIR") }
          Rectangle {
            id: dot
            width: 4; height: 4; color: ui.onAir; antialiasing: false
            anchors.verticalCenter: parent.verticalCenter
            visible: ui.host.playing
            SequentialAnimation on opacity {
              running: dot.visible && ui.host.popupOpen && !Style.reduceMotion
              loops: Animation.Infinite
              PauseAnimation { duration: 600 }
              PropertyAction { value: 0 }
              PauseAnimation { duration: 400 }
              PropertyAction { value: 1 }
            }
          }
        }
        PText {
          width: parent.width; elide: Text.ElideRight; dos: true
          text: ui.host.errorText && !ui.host.running ? ui.host.errorText
            : ui.host.starting ? "Jumping into the pool…"
            : (ui.host.trackTitle || ui.host.trackArtist)
              ? (ui.host.trackArtist ? ui.host.trackArtist + " – " : "") + ui.host.trackTitle
              : "Swimwear optional."
        }
        Rectangle { width: parent.width; height: 1; color: ui.rule; antialiasing: false }
      }
    }

    // ---- status + transport -------------------------------------------------
    Row {
      width: parent.width; height: 40; spacing: 4

      Bevel {
        width: parent.width - transport.width - pinkKey.width - 8; height: parent.height; fill: ui.card
        PixelIcon { rows: ui.sTri; x: 10; y: 7 }
        PText { x: 10; y: 15; text: ui.status }
      }

      Row {
        id: transport
        spacing: -1
        height: parent.height
        Repeater {
          model: [
            { k: "play", w: 64, fill: ui.aqua },
            { k: "stop", w: 52, fill: ui.paper },
            { k: "prev", w: 38, fill: ui.paper },
            { k: "next", w: 38, fill: ui.paper }
          ]
          Bevel {
            id: key
            readonly property bool usable: modelData.k === "play" || (modelData.k === "stop" ? ui.host.running : !!ui.p)
            width: modelData.w; height: transport.height
            fill: modelData.fill
            roundLeft: index === 0
            roundRight: index === 3
            sunk: keyMouse.pressed && usable
            PixelIcon {
              anchors.centerIn: parent
              anchors.verticalCenterOffset: key.sunk ? 1 : 0
              color: !key.usable ? ui.grey : (modelData.k === "play" ? ui.onAqua : ui.ink)
              rows: modelData.k === "play" ? (ui.host.playing ? ui.sPause : ui.sPlay)
                : modelData.k === "stop" ? ui.sStop
                : modelData.k === "prev" ? ui.sPrev : ui.sNext
            }
            MouseArea {
              id: keyMouse
              anchors.fill: parent
              cursorShape: key.usable ? Qt.PointingHandCursor : Qt.ArrowCursor
              onClicked: {
                if (!key.usable) return
                if (modelData.k === "play") ui.host.playPause()
                else if (modelData.k === "stop") ui.host.cmd(["quit"])
                else if (modelData.k === "prev") ui.p.previous()
                else ui.p.next()
              }
            }
          }
        }
      }

      // Pink key: surprise me, a random other channel.
      Bevel {
        id: pinkKey
        width: 44; height: parent.height; fill: ui.pink
        sunk: pinkMouse.pressed
        PixelIcon { rows: ui.sDice; anchors.centerIn: parent; anchors.verticalCenterOffset: pinkKey.sunk ? 1 : 0 }
        MouseArea {
          id: pinkMouse
          anchors.fill: parent; cursorShape: Qt.PointingHandCursor
          onClicked: {
            var list = ui.host.channels.filter(function(c) { return c.id !== ui.host.channel })
            var pick = list[Math.floor(Math.random() * list.length)]
            ui.host.channel = pick.id
            ui.host.cmd(["play", pick.id])
          }
        }
      }
    }

    // ---- channel picker + volume + dither -------------------------------------
    Row {
      width: parent.width; height: 26; spacing: 4

      Bevel {
        id: chanBox
        width: Math.round(parent.width * 0.56); height: parent.height
        PText {
          x: 8; anchors.verticalCenter: parent.verticalCenter
          width: parent.width - 34; elide: Text.ElideRight
          text: "Channel: " + ui.host.channelName(ui.host.channel)
        }
        PixelIcon { rows: ui.sDown; anchors.right: parent.right; anchors.rightMargin: 9; anchors.verticalCenter: parent.verticalCenter }
        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: ui.menuOpen = !ui.menuOpen }
      }

      Bevel {
        id: volBox
        width: parent.width - chanBox.width - dither.width - 8; height: parent.height
        readonly property real value: ui.p ? Math.max(0, Math.min(1, ui.p.volume)) : 0
        PixelIcon { id: speaker; rows: ui.sSpeaker; x: 7; anchors.verticalCenter: parent.verticalCenter }
        Row {
          id: ticks
          x: 20; anchors.bottom: parent.bottom; anchors.bottomMargin: 6
          spacing: 2
          Repeater {
            model: 10
            Rectangle {
              width: 2; height: 3 + index; antialiasing: false
              anchors.bottom: parent.bottom
              color: (index + 1) / 10 <= volBox.value + 0.001 ? ui.ink : ui.rule
            }
          }
        }
        MouseArea {
          x: ticks.x - 2; width: ticks.width + 6; height: parent.height
          cursorShape: Qt.PointingHandCursor
          enabled: !!ui.p && ui.p.volumeSupported
          function set(mx) { ui.p.volume = Math.max(0, Math.min(1, Math.ceil((mx - 2) / 4) / 10)) }
          onPressed: function(m) { set(m.x) }
          onPositionChanged: function(m) { if (pressed) set(m.x) }
        }
      }

      // 25% dither: staggered 1px dots in the palette's ink.
      Canvas {
        id: dither
        width: 38; height: parent.height - 2; y: 1
        antialiasing: false
        property color dotColor: ui.ink
        onDotColorChanged: requestPaint()
        onPaint: {
          var c = getContext("2d")
          c.reset()
          c.fillStyle = dotColor
          for (var y = 0; y < height; y += 2)
            for (var x = (y % 4 === 0) ? 0 : 1; x < width; x += 2) c.fillRect(x, y, 1, 1)
        }
      }
    }

  }

  // ---- channel menu ----------------------------------------------------------
  // A System 7 pop-up menu: it floats over the window (never resizes it), opens
  // with the current channel lined up on the box, and is kept inside the
  // window. A click anywhere else in the window closes it.
  MouseArea {
    anchors.fill: parent
    z: 50
    visible: ui.menuOpen
    onClicked: ui.menuOpen = false
  }
  Item {
    id: menuLayer
    z: 51
    visible: ui.menuOpen
    readonly property int rowH: 20
    readonly property int current: {
      for (var i = 0; i < ui.host.channels.length; i++)
        if (ui.host.channels[i].id === ui.host.channel) return i
      return 0
    }
    // Where the channel box sits in the window; re-read whenever the menu
    // opens or the window's layout changes size.
    readonly property point box: ui.menuOpen && ui.width > 0 && ui.height > 0 && chanBox.width > 0
      ? chanBox.mapToItem(ui, 0, 0) : Qt.point(0, 0)
    width: menu.width + 2
    height: menu.height + 2
    // Item text lines up with the box text (box text sits 9px in).
    x: Math.round(Math.max(4, Math.min(ui.width - width - 4, box.x - 12)))
    // Current row centred on the box's centre line, clamped to the window.
    y: Math.round(Math.max(4, Math.min(ui.height - height - 4,
         box.y + chanBox.height / 2 - (1 + current * rowH + rowH / 2))))

    // Hard 2px drop shadow.
    Rectangle { x: 2; y: 2; width: menu.width; height: menu.height; color: ui.ink; antialiasing: false }
    Rectangle {
      id: menu
      width: chanBox.width + 24; height: menuCol.height + 2
      color: ui.card; border.color: ui.ink; border.width: 1; antialiasing: false
      Column {
        id: menuCol
        x: 1; y: 1; width: parent.width - 2
        Repeater {
          model: ui.host.channels
          Rectangle {
            width: menuCol.width; height: menuLayer.rowH
            color: itemMouse.containsMouse ? ui.ink : "transparent"
            antialiasing: false
            readonly property bool current: modelData.id === ui.host.channel
            PixelIcon {
              visible: parent.current
              rows: ui.sCheck; x: 6; anchors.verticalCenter: parent.verticalCenter
              color: itemMouse.containsMouse ? ui.card : ui.ink
            }
            PText {
              x: 20; anchors.verticalCenter: parent.verticalCenter
              text: modelData.name
              color: itemMouse.containsMouse ? ui.card : ui.ink
            }
            MouseArea {
              id: itemMouse
              anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
              onClicked: {
                ui.menuOpen = false
                ui.host.channel = modelData.id
                ui.host.cmd(["play", modelData.id])
              }
            }
          }
        }
      }
    }
  }
}
