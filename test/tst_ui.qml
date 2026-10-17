import QtQuick
import QtTest
import "../app"
import "../app/Engine.js" as Engine
import "../app/About.js" as About
import Quickshell

// End-to-end: real key events from the title screen into the jungle and out
// again, with the real 60 Hz loop. Run with test/ui.sh (headless).
Item {
  id: top
  width: 1280
  height: 800

  Theme { id: theme }
  Save { id: save }
  Sfx { id: sfx; muted: true }
  Game { id: app; anchors.fill: parent; theme: theme; save: save; sfx: sfx }

  TestCase {
    name: "Hyprfall"
    when: windowShown && save.loaded

    function test_1_play_and_quit() {
      app.forceActiveFocus()
      compare(app.view, "title")
      compare(app.px, 4)

      keyClick(Qt.Key_Return)
      compare(app.view, "play")
      // the hero drops out of the canopy onto the floor
      tryCompare(app.game.p, "mode", "ground", 3000)
      compare(app.game.p.y, Engine.GROUND)

      var x0 = app.game.p.x
      keyPress(Qt.Key_L)
      wait(500)
      keyRelease(Qt.Key_L)
      verify(app.game.p.x > x0 + 20, "vim keys run right: " + x0 + " -> " + app.game.p.x)

      keyClick(Qt.Key_Space)
      wait(80)
      verify(app.game.p.mode === "air" && app.game.p.y < Engine.GROUND, "a quick tap still jumps")
      tryCompare(app.game.p, "mode", "ground", 2000)

      var t = app.game.time
      keyClick(Qt.Key_P)
      compare(app.view, "paused")
      wait(300)
      compare(app.game.time, t)
      keyClick(Qt.Key_Return)
      compare(app.view, "play")
      wait(200)
      verify(app.game.time < t, "clock runs again")

      keyClick(Qt.Key_M)
      verify(save.muted)
      keyClick(Qt.Key_M)
      verify(!save.muted)

      keyClick(Qt.Key_Escape)
      keyClick(Qt.Key_Q)
      compare(app.view, "over")
      compare(app.game.cause, "quit")
      compare(save.scores.length, 1)
      compare(save.scores[0].score, app.game.score)
      compare(app.rank, 0)

      keyClick(Qt.Key_Escape)
      compare(app.view, "title")
      keyClick(Qt.Key_Space)
      compare(app.view, "play")
      compare(app.game.score, Engine.START_SCORE)
      compare(app.game.lives, Engine.LIVES)
    }

    function test_2_theme_change_repaints() {
      var rev = theme.revision
      theme.apply('accent = "#ff0000"\ngreen = "#00ff00"\n')
      verify(theme.revision > rev)
      compare(String(theme.role("teeLogo")), "#ff0000")
      compare(String(theme.canopy), "#00ff00")
    }

    function test_3_about() {
      // nothing may reach a mail client; copies land in the stub's clipboard
      app.externalLinks = false
      app.forceActiveFocus()
      // test 1 left a run going: give up and go back to the title
      keyClick(Qt.Key_Escape)
      keyClick(Qt.Key_Q)
      keyClick(Qt.Key_Escape)
      compare(app.view, "title")
      keyClick(Qt.Key_F1)
      compare(app.view, "about")
      verify(app.onTitle, "the title jungle stays behind About")
      compare(findChild(app, "aboutVersion").text, "Version dev")
      compare(findChild(app, "aboutPrivacy").text, About.ABOUT.privacy)

      keyClick(Qt.Key_R)
      var license = findChild(app, "aboutLicenseText")
      verify(license.visible)
      verify(license.text.indexOf("MIT License\n\nCopyright (c) 2026 Nine Point Labs\n\nPermission is hereby granted") === 0, license.text.slice(0, 60))
      keyClick(Qt.Key_R)
      verify(!license.visible)

      keyClick(Qt.Key_C)
      compare(Quickshell.clipboardText, "help@ninepointlabs.com")
      keyClick(Qt.Key_V)
      verify(Quickshell.clipboardText.indexOf("Hyprfall dev\nQuickshell ?, Qt ?\n") === 0, Quickshell.clipboardText)
      keyClick(Qt.Key_E)
      verify(app.lastExternalUrl.indexOf("mailto:help@ninepointlabs.com?subject=Hyprfall%20dev&body=") === 0, app.lastExternalUrl)

      // keys that mean something in the jungle do nothing here
      keyClick(Qt.Key_Return)
      keyClick(Qt.Key_Space)
      compare(app.view, "about")
      keyClick(Qt.Key_Escape)
      compare(app.view, "title")

      // mid-run, About pauses the game and Esc comes back to the pause card
      keyClick(Qt.Key_Return)
      compare(app.view, "play")
      tryCompare(app.game.p, "mode", "ground", 3000)
      keyPress(Qt.Key_L)
      wait(100)
      keyClick(Qt.Key_F1)
      compare(app.view, "about")
      keyRelease(Qt.Key_L)
      verify(!app.held.right, "a key let go behind About is let go")
      var t = app.game.time
      wait(300)
      compare(app.game.time, t)
      keyClick(Qt.Key_F1)
      compare(app.view, "paused")
      keyClick(Qt.Key_F1)
      compare(app.view, "about")
      keyClick(Qt.Key_Backspace)
      compare(app.view, "paused")
      keyClick(Qt.Key_Return)
      compare(app.view, "play")
      wait(200)
      verify(app.game.time < t, "clock runs again")
    }
  }
}
