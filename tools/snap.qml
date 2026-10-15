import QtQuick
import QtQuick.Window
import "../app"
import "../app/Engine.js" as Engine

// Headless screenshots, no compositor needed (tools/snap.sh wraps this):
//   QT_QPA_PLATFORM=offscreen qml6 tools/snap.qml -- <outdir> <step>...
// Steps: start, scene:<name>[:<nth>], at:<x>,<y>[,<mode>[,under]],
// hold:<keys>:<frames> (keys like right+jump, or none), time:<seconds>,
// key:<name>, view:<name>, wait:<ms>, shot:<file.png>.
Window {
  id: win
  width: 1280
  height: 800
  visible: true

  Theme { id: theme }
  Save { id: save }
  Sfx { id: sfx; muted: true }

  Game {
    id: app
    anchors.fill: parent
    theme: theme
    save: save
    sfx: sfx
  }

  property var args: Qt.application.arguments.slice(Qt.application.arguments.indexOf("--") + 1).filter(function(a) { return String(a).indexOf("--env=") !== 0 })
  property string outDir: args[0]
  property int step: 1

  Timer {
    id: runner
    interval: 500
    running: save.loaded
    onTriggered: win.next()
  }

  function next() {
    if (step >= args.length) { Qt.quit(); return }
    try { run(args[step++]) } catch (e) { console.warn("snap: step " + (step - 1) + " failed: " + e); Qt.quit() }
  }

  function findScene(name, nth) {
    var r = Engine.START_ROOM, n = 0
    for (var i = 0; i < 255; i++) {
      if (Engine.room(r).scene === name && n++ === (nth || 0)) return r
      r = Engine.next(r)
    }
    throw "no scene " + name
  }

  function run(s) {
    var parts = s.split(":")
    var op = parts[0], arg = parts.slice(1).join(":")
    var delay = 250
    var g = app.game
    // "frozen" is play without the clock running: the steps move time here
    if (op === "start") { app.start(); app.view = "frozen" }
    else if (op === "scene") { g.room = findScene(parts[1], Number(parts[2] || 0)); Engine.enterRoom(g) }
    else if (op === "room") { g.room = Number(arg); Engine.enterRoom(g) }
    else if (op === "at") {
      var a = arg.split(",")
      g.p.x = Number(a[0]); g.p.y = Number(a[1]); g.p.mode = a[2] || "ground"; g.p.under = a[3] === "under"; g.p.vx = 0; g.p.vy = 0
    }
    else if (op === "face") g.p.face = Number(arg)
    else if (op === "walk") g.p.walk = Number(arg)
    else if (op === "time") g.t = Number(arg)
    else if (op === "clock") g.time = Number(arg)
    else if (op === "set") { var kv = arg.split("="); g[kv[0]] = Number(kv[1]) }
    else if (op === "hold") {
      var keys = parts[1].split("+"), frames = Number(parts[2])
      var inp = { left: false, right: false, up: false, down: false, jump: false }
      keys.forEach(function(k) { if (k in inp) inp[k] = true })
      for (var f = 0; f < frames && g.status === "play"; f++) { Engine.step(g, inp); g.events = [] }
    }
    else if (op === "view") app.view = arg
    else if (op === "eval") eval(arg)
    else if (op === "wait") delay = Number(arg)
    else if (op === "shot") {
      app.frame++
      Qt.callLater(function() { app.grabStage(outDir + "/" + arg) })
      delay = 700
    }
    if (op !== "wait" && op !== "shot") app.frame++
    runner.interval = delay
    runner.restart()
  }
}
