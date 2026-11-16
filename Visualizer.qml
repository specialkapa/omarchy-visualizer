import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import qs.Commons
import qs.Commons as Commons
import qs.Ui
import "Logic.js" as Logic

// Animated audio spectrum for the Omarchy bar, in the style of YASB's cava
// widget: flat bars (or a smooth wave) filled with a height gradient taken
// from the current Omarchy theme. cava captures whatever PipeWire is playing
// and prints bar heights (bin/cava-bar); this only draws them. cava runs
// only while a media player reports it is playing and shell animations are
// on (omarchy toggle animations).
BarWidget {
  id: root
  moduleName: "specialkapa.visualizer"

  Commons.Translations { id: strings; directory: Qt.resolvedUrl("i18n") }

  readonly property string script: String(Qt.resolvedUrl("bin/cava-bar")).replace(/^file:\/\//, "")

  // ---------- settings ----------
  readonly property int barCount: Logic.clampBars(setting("bars", 10))
  readonly property string style: ["bars", "bars_mirrored", "waves", "waves_mirrored"].indexOf(setting("style", "bars")) >= 0
    ? setting("style", "bars") : "bars"
  readonly property bool waves: style.indexOf("waves") === 0
  readonly property bool mirrored: style.indexOf("mirrored") > 0
  readonly property real barWidth: Style.space(Logic.clampInt(setting("barWidth", 4), 1, 12, 4))
  readonly property real barSpacing: Style.space(Logic.clampInt(setting("barSpacing", 2), 0, 8, 2))
  readonly property real heightFraction: Logic.clampInt(setting("height", 60), 20, 100, 60) / 100
  readonly property bool gradient: setting("gradient", true) !== false
  readonly property bool hideWhenIdle: setting("hideWhenIdle", true) !== false

  // ---------- colors (follow the Omarchy theme) ----------
  FileView {
    id: themeFile
    path: Commons.Color.currentThemePath + "/colors.toml"
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
  }
  readonly property var palette: Logic.gradientColors(setting("colors", ""),
    Logic.themeColors(themeFile.loaded ? themeFile.text() : ""), String(Commons.Color.accent))
  readonly property color colorLow: palette[0]
  readonly property color colorMid: palette.length > 2 ? palette[1] : palette[0]
  readonly property color colorHigh: palette[palette.length - 1]

  // ---------- state ----------
  readonly property bool animationsOn: Style.duration(100) > 0
  readonly property bool anyPlaying: {
    var players = Mpris.players ? Mpris.players.values : []
    for (var i = 0; i < players.length; i++) if (players[i] && players[i].isPlaying) return true
    return false
  }
  readonly property bool running: anyPlaying && animationsOn
  readonly property bool shown: running || !hideWhenIdle
  property var levels: []
  property bool hovered: false
  readonly property bool tooltipHovered: visible && hovered

  // Drawing area: `run` along the bar, `span` across it.
  readonly property real run: barCount * barWidth + (barCount - 1) * barSpacing
  readonly property real span: Math.round(barSize * heightFraction)

  visible: shown
  implicitWidth: !shown ? 0 : (vertical ? barSize : run + Style.space(12))
  implicitHeight: !shown ? 0 : (vertical ? run + Style.space(12) : barSize)

  onRunningChanged: if (!running) levels = []

  Process {
    id: cava
    running: root.running && root.visible
    command: [root.script, String(root.barCount), "60"]
    stdout: SplitParser {
      splitMarker: "\n"
      onRead: function (line) { root.levels = Logic.parseLevels(line, root.barCount) }
    }
    onExited: root.levels = []
  }

  // Always laid out horizontally; on a vertical bar the whole drawing turns 90°.
  Item {
    id: canvas
    width: root.run
    height: root.span
    anchors.centerIn: parent
    rotation: root.vertical ? 90 : 0

    // ----- bars: each bar reveals part of a full-height gradient, so tall
    // bars show the "loud" color and quiet ones only the "quiet" color.
    Row {
      visible: !root.waves
      anchors.fill: parent
      spacing: root.barSpacing

      Repeater {
        model: root.barCount

        Item {
          id: bar
          required property int index
          readonly property real level: root.levels.length > index ? root.levels[index] : 0
          readonly property real length: root.mirrored ? Math.round(level * canvas.height / 2) * 2 : Math.round(level * canvas.height)
          width: root.barWidth
          height: canvas.height

          Item {
            clip: true
            width: parent.width
            height: bar.length
            y: root.mirrored ? (canvas.height - height) / 2 : canvas.height - height

            Rectangle {
              width: parent.width
              height: canvas.height
              y: root.mirrored ? -(canvas.height - bar.length) / 2 : -(canvas.height - bar.length)
              radius: Math.min(2, width / 2)
              gradient: Gradient {
                GradientStop { position: 0.0; color: root.gradient ? (root.mirrored ? root.colorHigh : root.colorHigh) : root.colorMid }
                GradientStop { position: root.mirrored ? 0.5 : 0.5; color: root.gradient ? (root.mirrored ? root.colorLow : root.colorMid) : root.colorMid }
                GradientStop { position: 1.0; color: root.gradient ? (root.mirrored ? root.colorHigh : root.colorLow) : root.colorMid }
              }
            }
          }
        }
      }
    }

    // ----- waves: one smooth filled curve through the bar heights.
    Shape {
      visible: root.waves
      anchors.fill: parent
      preferredRendererType: Shape.CurveRenderer

      ShapePath {
        strokeWidth: -1
        fillGradient: LinearGradient {
          x1: 0; y1: 0
          x2: 0; y2: canvas.height
          GradientStop { position: 0.0; color: root.gradient ? root.colorHigh : root.colorMid }
          GradientStop { position: 0.5; color: root.gradient ? (root.mirrored ? root.colorLow : root.colorMid) : root.colorMid }
          GradientStop { position: 1.0; color: root.gradient ? (root.mirrored ? root.colorHigh : root.colorLow) : root.colorMid }
        }
        PathSvg { path: Logic.wavePath(root.levels.length ? root.levels : [], canvas.width, canvas.height, root.mirrored) }
      }
    }
  }

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    // Left: open rmpc. Right: settings, shown in the Spotify Downloader panel's Settings tab.
    onClicked: function (mouse) {
      if (mouse.button === Qt.RightButton) Quickshell.execDetached(["omarchy-shell", "specialkapa.spotify-dl", "settings"])
      else Quickshell.execDetached(["omarchy-launch-or-focus-tui", "rmpc"])
    }
    onEntered: { root.hovered = true; if (root.bar) root.bar.showTooltip(root, strings.t("tooltip")) }
    onExited: { root.hovered = false; if (root.bar) root.bar.hideTooltip(root) }
  }
}
