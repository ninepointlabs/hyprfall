import QtQuick
import Quickshell
import Quickshell.Io

// The current Omarchy theme's colours, read from
// ~/.local/state/omarchy/current/theme/colors.toml and re-read whenever the
// theme changes, so `omarchy theme set` repaints the jungle live. The canopy
// is the theme's green, the swamp its blue, the hero's tee its accent, and so
// on; skin, hair and wood keep fixed colours so the hero stays recognisable.
QtObject {
  id: root

  readonly property string path: (Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state") + "/omarchy/current/theme/colors.toml"

  property color background: "#1a1b26"
  property color darkBackground: "#16161e"
  property color darkerBackground: "#101016"
  property color foreground: "#c0caf5"
  property color accent: "#7aa2f7"
  property color muted: "#444b6a"
  property color red: "#f7768e"
  property color green: "#9ece6a"
  property color yellow: "#e0af68"
  property color blue: "#7aa2f7"
  property color cyan: "#7dcfff"
  property color magenta: "#bb9af7"
  property string mode: "dark"
  // bumped on every theme change; sprites repaint when it moves
  property int revision: 0

  readonly property string font: "monospace"

  // ---- the scene, derived from the theme
  readonly property color hud: darkerBackground
  readonly property color backdrop: Qt.tint(background, Qt.rgba(green.r, green.g, green.b, 0.3))
  readonly property color canopy: green
  readonly property color canopyShade: Qt.darker(green, 1.7)
  readonly property color trunk: "#5a3a22"
  readonly property color trunkShade: "#3e2716"
  readonly property color grass: Qt.lighter(yellow, 1.1)
  readonly property color ground: Qt.darker(yellow, 1.2)
  readonly property color dirt: Qt.darker(yellow, 2.2)
  readonly property color tunnel: darkerBackground
  readonly property color bedrock: Qt.darker(yellow, 3.2)
  readonly property color brick: Qt.darker(red, 1.5)
  readonly property color mortar: Qt.darker(red, 3)
  readonly property color ladder: "#a7763f"
  readonly property color water: blue
  readonly property color waterShine: Qt.lighter(blue, 1.35)
  readonly property color tar: "#0c0c0f"
  readonly property color tarShine: "#2a2a33"
  readonly property color deps: Qt.darker(magenta, 1.6)
  readonly property color depsShine: magenta
  readonly property color cable: blue
  readonly property color sign: "#f2ead3"
  readonly property color signInk: Qt.darker(red, 1.3)

  property var roles: ({})

  function role(name) { return roles[name] || "#ff00ff" }

  function rebuild() {
    roles = {
      hair: "#1b1b20", skin: "#e2aa84", skinShade: "#b9805e", stubble: "#7d5c4b",
      shades: "#0d0d12", glint: cyan, shirt: accent, shirtShade: Qt.darker(accent, 1.4),
      jeans: "#34446e", jeansShade: "#232f50", shoes: "#ececec", dead: "#101014",
      gator: green, gatorShade: Qt.darker(green, 1.8), eye: "#f4f1d8", pupil: "#101014",
      teeth: "#f4f4f4", mouth: Qt.darker(red, 1.6),
      log: "#8b5a2b", logShade: "#5f3b1a", logEnd: "#c9955c",
      bug: red, bugSpot: yellow,
      dumpster: "#4b6354", dumpsterShade: "#33443a", fire: red, flame: "#ff8c1a",
      gold: yellow, goldShade: Qt.darker(yellow, 1.6),
      python: blue, pythonBelly: yellow, tongue: red,
      ink: "#101014", shine: "#ffffff",
      crystal: cyan, crystalShade: Qt.darker(cyan, 1.7),
      ruby: red, rubyShade: Qt.darker(red, 1.8),
      plug: "#d6dde0", plugPins: yellow
    }
    revision++
  }

  Component.onCompleted: rebuild()

  property var _file: FileView {
    path: root.path
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: root.apply(text())
  }

  function apply(raw) {
    var map = {}
    var lines = String(raw || "").split("\n")
    for (var i = 0; i < lines.length; i++) {
      var m = lines[i].match(/^\s*([A-Za-z_]+)\s*=\s*"([^"]*)"/)
      if (m) map[m[1]] = m[2]
    }
    function c(key, fallback) { return map[key] && /^#[0-9a-fA-F]{6,8}$/.test(map[key]) ? map[key] : fallback }
    background = c("background", background)
    darkBackground = c("dark_background", Qt.darker(background, 1.2))
    darkerBackground = c("darker_background", Qt.darker(background, 1.45))
    foreground = c("foreground", foreground)
    accent = c("accent", accent)
    muted = c("muted", muted)
    red = c("red", c("color1", red))
    green = c("green", c("color2", green))
    yellow = c("yellow", c("color3", yellow))
    blue = c("blue", c("color4", blue))
    magenta = c("magenta", c("color5", magenta))
    cyan = c("cyan", c("color6", cyan))
    mode = map.mode || "dark"
    rebuild()
  }
}
