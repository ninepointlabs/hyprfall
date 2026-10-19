//@ pragma AppId hyprfall
// ^ the window's Wayland app_id (Quickshell 0.3+), so docks, launchers and
//   window rules match it to hyprfall.desktop instead of org.quickshell.
import QtQuick
import Quickshell
import Quickshell.Io

// Hyprfall: a standalone Quickshell app. Launch with `hyprfall` (bin/hyprfall),
// which runs `quickshell -p` on this directory.
ShellRoot {
  FloatingWindow {
    id: win
    title: "Hyprfall"
    implicitWidth: 1280
    implicitHeight: 800
    minimumSize: Qt.size(640, 400)
    color: "#000000"

    onClosed: Qt.quit()

    Theme { id: theme }
    Save { id: save }
    Sfx { id: sfx; muted: save.muted }

    Game {
      id: game
      anchors.fill: parent
      theme: theme
      save: save
      sfx: sfx
      window: win
      Component.onCompleted: { forceActiveFocus(); sfx.track = "title" }
    }

    // `hyprfall --selftest`: start a game, let the real loop run for a
    // second, report, quit. Used by the release workflow on every distro.
    Timer {
      running: Quickshell.env("HYPRFALL_SELFTEST") === "1"
      interval: 300
      onTriggered: { game.start(); check.start() }
    }
    Timer {
      id: check
      interval: 1200
      onTriggered: {
        var g = game.game
        var ok = game.view === "play" && g.t > 0.5 && g.p.mode === "ground"
        console.info(ok ? "hyprfall: selftest ok (" + g.t.toFixed(2) + "s of play, room " + g.room + ")" : "hyprfall: selftest failed: " + JSON.stringify({ view: game.view, t: g.t, mode: g.p.mode }))
        Qt.exit(ok ? 0 : 1)
      }
    }

    // `quickshell ipc -p <app dir> call hyprfall <fn>`: drive the game from a
    // script, or raise a stuck pause from a keybinding.
    IpcHandler {
      target: "hyprfall"

      function state(): string {
        return JSON.stringify({ view: game.view, room: game.game.room, score: game.game.score, found: game.game.found, lives: game.game.lives, time: Math.round(game.game.time) })
      }
      function pause(): string { if (game.view === "play") game.view = "paused"; return game.view }
      function start(): string { game.start(); return "ok" }
      function about(): string { game.openAbout(); return game.view }
      // Saves a PNG of the stage; only ever under ~/.cache, only .png.
      function shot(path: string): string {
        var allowed = Quickshell.env("HOME") + "/.cache/"
        if (path.indexOf(allowed) !== 0 || path.indexOf("..") !== -1 || !/\.png$/.test(path)) return "refused: path must be a .png under ~/.cache"
        game.grabStage(path)
        return "ok"
      }
    }
  }
}
