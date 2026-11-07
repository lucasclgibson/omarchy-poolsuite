import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import qs.Ui
import qs.Commons
import qs.Commons as Commons

// Poolsuite in the bar. The pill shows a palm tree (lit while playing); click
// it for a Poolsuite-styled player. Audio is a headless mpv run by
// ~/.local/bin/poolsuite; this widget finds that mpv's MPRIS player by the
// bus name `poolsuite status` reports and drives it directly.
BarWidget {
  id: root
  moduleName: "lucasclgibson.poolsuite"

  // ---- engine state --------------------------------------------------------
  property bool running: false
  property string busName: ""
  property string channel: "official"
  property bool starting: false
  // Set when the engine stopped itself because tracks kept failing to load.
  property string errorText: ""

  // ---- look -------------------------------------------------------------------
  // "omarchy" follows the current Omarchy theme; "poolsuite" is the classic
  // System 7 look. Stored as `theme` on this widget's entry in shell.json; the
  // title-bar switch applies it at once and saves it with `poolsuite theme`.
  property string themeOverride: ""
  readonly property string themeName: {
    var t = themeOverride || String(setting("theme", "omarchy")).toLowerCase()
    return t === "poolsuite" ? "poolsuite" : "omarchy"
  }
  function setTheme(name) {
    themeOverride = name
    Quickshell.execDetached(["poolsuite", "theme", name])
  }

  readonly property var players: Mpris.players ? Mpris.players.values : []
  readonly property var player: {
    if (!busName) return null
    for (var i = 0; i < players.length; i++)
      if (players[i] && String(players[i].dbusName) === busName) return players[i]
    return null
  }
  readonly property bool playing: !!player && player.isPlaying
  readonly property string trackTitle: player ? (player.trackTitle || "") : ""
  readonly property string trackArtist: player ? (player.trackArtist || "") : ""

  readonly property var channels: [
    { id: "official",  name: "Poolsuite FM" },
    { id: "official2", name: "Poolsuite FM Two" },
    { id: "balearic",  name: "Balearic Sundown" },
    { id: "indie",     name: "Indie Summer" },
    { id: "tokyo",     name: "Tokyo Disco" },
    { id: "friday",    name: "Friday Nite Heat" },
    { id: "hangover",  name: "Hangover Club" },
    { id: "mixtapes",  name: "Mixtapes" }
  ]
  function channelName(id) {
    for (var i = 0; i < channels.length; i++) if (channels[i].id === id) return channels[i].name
    return "Poolsuite FM"
  }

  function refresh() { if (!statusProc.running) statusProc.running = true }
  function cmd(args) {
    Quickshell.execDetached(["poolsuite"].concat(args))
    if (args[0] === "play" || args[0] === "toggle") starting = !running
    refreshSoon.restart()
  }
  function playPause() {
    if (player) player.togglePlaying()
    else cmd(["toggle"])
  }

  onPlayersChanged: refresh()
  Component.onCompleted: refresh()

  Process {
    id: statusProc
    command: ["poolsuite", "status"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        try {
          var s = JSON.parse(text)
          root.running = !!s.running
          root.busName = String(s.bus || "")
          root.channel = String(s.channel || "official")
          root.errorText = root.running ? "" : String(s.error || "").trim()
          if (root.player || !root.running) root.starting = false
        } catch (e) {}
      }
    }
  }
  Timer { id: refreshSoon; interval: 700; repeat: false; onTriggered: root.refresh() }
  Timer { interval: root.starting ? 1000 : 15000; running: true; repeat: true; onTriggered: root.refresh() }
  // MPRIS position isn't pushed; poll it while the popup is showing.
  Timer {
    interval: 1000; repeat: true
    running: root.popupOpen && root.playing
    onTriggered: if (root.player) root.player.positionChanged()
  }

  // ---- panel contract (omarchy-shell shell toggle lucasclgibson.poolsuite) -----------
  property bool popupOpen: false
  readonly property bool opened: popupOpen
  function open() { popupOpen = true; refresh() }
  function close() { popupOpen = false; ui.menuOpen = false }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    active: root.playing
    // Blank glyph: the pixel palm is drawn on top (below) at exactly 1:1.
    text: " "
    tooltipText: root.popupOpen ? "" : (root.playing
      ? (root.trackArtist ? root.trackArtist + " – " : "") + root.trackTitle
      : "Poolsuite")
    onPressed: function(b) {
      if (b === Qt.MiddleButton) root.playPause()
      else if (b === Qt.RightButton && root.player) root.player.next()
      else root.popupOpen ? root.close() : root.open()
    }
    onWheelMoved: function(delta) {
      if (!root.player || !root.player.volumeSupported) return
      root.player.volume = Math.max(0, Math.min(1, root.player.volume + (delta > 0 ? 0.05 : -0.05)))
    }
  }

  // The same 1-bit palm as the player, drawn at 1:1 (one art pixel = one
  // logical pixel) and snapped to whole pixels. Bar icons are rescaled to the
  // theme's icon size, which would smear a 12px sprite, so it sits over the
  // button instead of going through iconComponent. Accent colour while playing.
  PixelIcon {
    id: barPalm
    x: Math.round((button.width - width) / 2)
    y: Math.round((button.height - height) / 2)
    scale: button.pressScale
    color: button.active ? button.activeColor : button.foreground
    rows: [
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
  }

  PopupCard {
    id: popup
    anchorItem: button
    bar: root.bar
    owner: root
    open: root.popupOpen
    padding: 0
    // Classic: a black window outline. Omarchy: the theme's own popup border.
    borderColor: themeName === "poolsuite" ? "#000000" : Commons.Color.popups.border
    contentWidth: popup.fittedContentWidth(352)
    contentHeight: popup.fittedContentHeight(ui.implicitHeight)

    Player {
      id: ui
      anchors.left: parent.left
      anchors.right: parent.right
      host: root
    }
  }
}
