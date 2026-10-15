import QtQuick
import Quickshell
import Quickshell.Io
import "Engine.js" as Engine

// High scores and the mute switch, in ~/.local/state/hyprfall/save.json.
// A game in progress isn't saved; a run is twenty minutes, like the arcade.
Item {
  id: root

  readonly property string dir: (Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state") + "/hyprfall"
  property var scores: []
  property bool muted: false
  property bool loaded: false

  function record(game) {
    var d = new Date()
    var date = d.getFullYear() + "-" + ("0" + (d.getMonth() + 1)).slice(-2) + "-" + ("0" + d.getDate()).slice(-2)
    var r = Engine.recordScore(scores, game, date)
    scores = r.scores
    save()
    return r.rank
  }

  function save() {
    if (!loaded) return
    file.setText(JSON.stringify({ version: 1, scores: scores, muted: muted }) + "\n")
  }

  onMutedChanged: save()

  Process {
    id: mkdir
    command: ["mkdir", "-p", root.dir]
    onExited: file.path = root.dir + "/save.json"
  }
  Component.onCompleted: mkdir.running = true

  FileView {
    id: file
    printErrors: false
    atomicWrites: true
    onLoaded: {
      try {
        var data = JSON.parse(text())
        root.scores = Engine.sanitizeScores(data.scores)
        root.muted = !!data.muted
      } catch (e) {
        console.warn("hyprfall: ignoring an unreadable save: " + e)
      }
      root.loaded = true
    }
    onLoadFailed: root.loaded = true
  }
}
