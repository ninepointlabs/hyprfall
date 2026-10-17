import QtQuick
import "Engine.js" as Engine

// The game screen: the 60 Hz loop, the keyboard, the HUD and the title,
// pause, game over, victory and About cards. The jungle itself is World.qml.
Item {
  id: app

  property var theme
  property var save
  property var sfx
  property var window

  // "title", "play", "paused", "over", "won", "about"
  property string view: "title"
  // where Esc goes back to from About; a run in progress comes back paused
  property string aboutFrom: "title"
  readonly property bool onTitle: view === "title" || (view === "about" && aboutFrom === "title")
  // About's Email button; off in tests so nothing reaches a mail client
  property bool externalLinks: true
  property string lastExternalUrl: ""
  property var game: Engine.newGame()
  property int frame: 0
  property real acc: 0
  property var held: ({ left: false, right: false, up: false, down: false, jump: false })
  // presses shorter than a frame still count: latched until a step sees them
  property var latched: ({})
  property int rank: -1
  property string toast: ""
  property real toastUntil: 0

  // fill the window; art pixels land on whole screen pixels where the scale allows
  readonly property real px: Math.max(1, Math.floor(Math.min(width / Engine.W, height / Engine.H) * 4) / 4)
  readonly property bool lowTime: game.time < 60

  focus: true
  Keys.onPressed: function(event) { if (app.onKey(event, true)) event.accepted = true }
  Keys.onReleased: function(event) { if (!event.isAutoRepeat && app.onKey(event, false)) event.accepted = true }

  function setHeld(name, down) {
    if (down) latched[name] = true
    if (held[name] === down) return
    var h = Object.assign({}, held)
    h[name] = down
    held = h
  }

  // returns true when the key meant something
  function onKey(event, down) {
    var k = event.key
    var dirs = {}
    dirs[Qt.Key_Left] = "left"; dirs[Qt.Key_A] = "left"; dirs[Qt.Key_H] = "left"
    dirs[Qt.Key_Right] = "right"; dirs[Qt.Key_D] = "right"; dirs[Qt.Key_L] = "right"
    dirs[Qt.Key_Up] = "up"; dirs[Qt.Key_W] = "up"; dirs[Qt.Key_K] = "up"
    dirs[Qt.Key_Down] = "down"; dirs[Qt.Key_S] = "down"; dirs[Qt.Key_J] = "down"
    dirs[Qt.Key_Space] = "jump"; dirs[Qt.Key_Z] = "jump"; dirs[Qt.Key_X] = "jump"
    if (view === "about") {
      // a run waits paused behind About: let go of held keys, ignore the rest
      if (dirs[k] && !down) setHeld(dirs[k], false)
      if (!down || event.isAutoRepeat) return true
      if (k === Qt.Key_Escape || k === Qt.Key_F1 || k === Qt.Key_Backspace) closeAbout()
      else if (k === Qt.Key_R) about.toggleLicense()
      else if (k === Qt.Key_E) about.email()
      else if (k === Qt.Key_C) about.copyEmail()
      else if (k === Qt.Key_V) about.copyDetails()
      // M and F11 still work below; nothing else reaches the game
      if (k !== Qt.Key_M && k !== Qt.Key_F11) return true
    }
    if (dirs[k]) {
      setHeld(dirs[k], down)
      if (down && view === "title" && dirs[k] === "jump" && !event.isAutoRepeat) start()
      return true
    }
    if (!down || event.isAutoRepeat) return false

    if (k === Qt.Key_M) { save.muted = !save.muted; return true }
    if (k === Qt.Key_F11) { if (window) window.fullscreen = !window.fullscreen; return true }
    if (k === Qt.Key_F1) { openAbout(); return true }
    if (k === Qt.Key_Return || k === Qt.Key_Enter) {
      if (view === "title" || view === "over" || view === "won") start()
      else if (view === "paused") view = "play"
      return true
    }
    if (k === Qt.Key_Escape || k === Qt.Key_P) {
      if (view === "play") { view = "paused"; sfx.play("pause") }
      else if (view === "paused") view = "play"
      else if (view === "over" || view === "won") view = "title"
      else if (view === "title" && k === Qt.Key_Escape) Qt.quit()
      return true
    }
    if (k === Qt.Key_Q && view !== "play") {
      if (view === "paused") end()
      else Qt.quit()
      return true
    }
    return false
  }

  function openAbout() {
    if (view === "about") return
    if (view === "play") sfx.play("pause")
    aboutFrom = view === "play" ? "paused" : view
    view = "about"
  }

  function closeAbout() {
    if (view === "about") view = aboutFrom
  }

  function openExternal(url) {
    lastExternalUrl = url
    if (externalLinks) Qt.openUrlExternally(url)
  }

  function start() {
    game = Engine.newGame()
    rank = -1
    acc = 0
    toast = ""
    view = "play"
    sfx.play("start")
    frame++
  }

  function end() {
    if (game.status === "play") { game.status = "over"; game.cause = "quit" }
    rank = save.record(game)
    view = game.status === "won" ? "won" : "over"
  }

  function say(text, seconds) {
    toast = text
    toastUntil = game.t + (seconds || 2)
  }

  function tick(dt) {
    acc = Math.min(acc + dt, 0.1)
    var steps = 0
    while (acc >= Engine.DT && game.status === "play") {
      var input = held
      if (Object.keys(latched).length) {
        input = Object.assign({}, held)
        for (var k in latched) input[k] = true
        // a tap is one frame of "down", then released for the edge to rearm
        latched = {}
      }
      Engine.step(game, input)
      acc -= Engine.DT
      steps++
    }
    var events = game.events
    game.events = []
    for (var i = 0; i < events.length; i++) {
      var e = events[i]
      var rm = Engine.room(game.room)
      if (e === "treasure") say("+" + rm.treasure.value + "  " + rm.treasure.name, 2.2)
      else if (e === "splash" || e === "sink" || e === "death") say(Engine.DEATHS[game.cause] || "", 2)
      else if (e === "thud") say("-100  Fell down a hole", 1.4)
      if (e !== "room" && e !== "land" && e !== "respawn") sfx.play(e)
    }
    if (game.status !== "play") end()
    if (steps) frame++
  }

  FrameAnimation {
    running: app.view === "play"
    onTriggered: app.tick(frameTime)
  }

  // the title screen's jungle drifts by on its own
  Timer {
    interval: 2600
    repeat: true
    running: app.view === "title"
    onTriggered: { app.game.room = Engine.next(app.game.room); app.game.logs = Engine.room(app.game.room).logs.slice(); app.frame++ }
  }
  FrameAnimation {
    running: app.view === "title"
    onTriggered: { app.game.t += frameTime; app.frame++ }
  }

  onViewChanged: sfx.track = onTitle ? "title" : view === "play" ? "jungle" : ""

  function grabStage(path) {
    if (!stage.grabToImage(function(r) { if (!r.saveToFile(path)) console.warn("hyprfall: could not save " + path) }))
      console.warn("hyprfall: grab failed")
  }

  Rectangle {
    anchors.fill: parent
    color: "#000000"
  }

  Item {
    id: stage
    width: Engine.W * app.px
    height: Engine.H * app.px
    anchors.centerIn: parent
    clip: true

    World {
      id: world
      game: app.game
      frame: app.frame
      px: app.px
      theme: app.theme
      // the title screen shows the jungle without the hero
      showHero: !app.onTitle
    }

    // ------------------------------------------------------------ HUD --
    Rectangle {
      width: parent.width
      height: 14 * app.px
      color: app.theme.hud
      visible: !app.onTitle

      Row {
        anchors.left: parent.left
        anchors.leftMargin: 6 * app.px
        anchors.verticalCenter: parent.verticalCenter
        spacing: 3 * app.px
        Text {
          text: String((app.frame, app.game.score))
          color: app.theme.foreground
          font.family: app.theme.font
          font.bold: true
          font.pixelSize: 8 * app.px
        }
        Item { width: 4 * app.px; height: 1 }
        Repeater {
          model: (app.frame, app.game.lives)
          PixelArt {
            theme: app.theme
            px: app.px
            sprite: "life"
            anchors.verticalCenter: parent.verticalCenter
          }
        }
      }

      Row {
        anchors.centerIn: parent
        spacing: 2 * app.px
        PixelArt {
          theme: app.theme
          px: app.px * 0.75
          sprite: "crystal"
          anchors.verticalCenter: parent.verticalCenter
        }
        Text {
          text: (app.frame, app.game.found) + " / " + Engine.TOTAL_TREASURES
          color: app.theme.foreground
          font.family: app.theme.font
          font.bold: true
          font.pixelSize: 8 * app.px
        }
      }

      Text {
        anchors.right: parent.right
        anchors.rightMargin: 6 * app.px
        anchors.verticalCenter: parent.verticalCenter
        text: Engine.clock((app.frame, app.game.time))
        color: app.lowTime && Math.floor(app.game.time * 2) % 2 ? app.theme.red : app.theme.foreground
        font.family: app.theme.font
        font.bold: true
        font.pixelSize: 8 * app.px
      }
    }

    // a line of news: treasure, falls, deaths
    Text {
      visible: app.view === "play" && app.toast !== "" && (app.frame, app.game.t < app.toastUntil)
      anchors.horizontalCenter: parent.horizontalCenter
      y: 62 * app.px
      text: app.toast
      color: app.theme.foreground
      font.family: app.theme.font
      font.bold: true
      font.pixelSize: 7 * app.px
      style: Text.Outline
      styleColor: app.theme.hud
    }

    // --------------------------------------------------------- cards --
    Card {
      visible: app.view === "title"
      theme: app.theme
      px: app.px
      title: "HYPRFALL"
      art: ["hang", "gnomeYell"]
      subtitle: "A jungle caper for Omarchy"
      lines: [
        "Find all " + Engine.TOTAL_TREASURES + " treasures in 20 minutes.",
        "Swing on the cable. Hop the gnomes' hats when they're quiet.",
        "Mind the tarballs, the python and the dumpster fires.",
        "",
        "←/→ or h/l run   Space jump   ↑/↓ or k/j climb",
        "P pause   M mute   F11 fullscreen   F1 about   Esc quit"
      ]
      footer: "Press Enter"
      scores: app.save.scores
    }

    Card {
      visible: app.view === "paused"
      theme: app.theme
      px: app.px
      title: "PAUSED"
      subtitle: "Touch grass. The jungle will wait."
      lines: ["Enter or P to keep going", "Q to give up and take your score", "F1 about"]
    }

    Card {
      visible: app.view === "over" || app.view === "won"
      theme: app.theme
      px: app.px
      title: app.view === "won" ? "YOU FOUND THEM ALL" : "GAME OVER"
      art: app.view === "won" ? ["keycap", "ruby", "idol", "crystal"] : ["dead"]
      subtitle: app.view === "won" ? "All " + Engine.TOTAL_TREASURES + " treasures with " + Engine.clock(app.game.time) + " to spare. Ship it."
                : app.game.cause === "quit" ? "You walked out of the jungle."
                : (Engine.DEATHS[app.game.cause] || "")
      lines: ["Score " + app.game.score + "   ·   treasures " + app.game.found + " / " + Engine.TOTAL_TREASURES,
              app.rank === 0 ? "A new high score!" : app.rank > 0 ? "Number " + (app.rank + 1) + " on the board." : ""]
      footer: "Enter to play again   ·   Esc for the title"
      scores: app.save.scores
      highlight: app.rank
    }

    AboutCard {
      id: about
      visible: app.view === "about"
      theme: app.theme
      px: app.px
      onOpenUrl: function(url) { app.openExternal(url) }
    }
  }
}
