import QtQuick
import Quickshell
import Quickshell.Io
import "About.js" as About

// The About screen (F1): a card like the others, with the version, license,
// support address, privacy and credits. Keys come from Game.qml; the buttons
// also take a click.
Rectangle {
  id: card

  property var theme
  property real px: 4
  property bool showLicense: false
  property string copied: ""
  // Game.qml opens the mailto: link, so a test can stop it reaching a mail client
  signal openUrl(string url)

  readonly property string version: About.version(versionFile.loaded ? versionFile.text() : "")
  readonly property string licenseText: licenseFile.loaded ? About.reflowLicense(licenseFile.text())
    : About.ABOUT.license + ", " + About.ABOUT.copyright
  readonly property string quickshellVersion: About.probedVersion(function(a, b) { return Quickshell.hasVersion(a, b) }, 0)
  readonly property string qtVersion: About.probedVersion(function(a, b) { return Quickshell.hasQtVersion(a, b) }, 6)
  readonly property string details: About.details(version, quickshellVersion, qtVersion,
    (Quickshell.env("XDG_CURRENT_DESKTOP") || "unknown desktop") + ", " + Qt.platform.pluginName)
  readonly property real font: 4.5 * px

  function localPath(url) {
    var s = String(url)
    return s.indexOf("file://") === 0 ? decodeURIComponent(s.slice(7)) : s
  }

  // the same VERSION file `hyprfall --version` reads; LICENSE sits next to it.
  // Quickshell blackholes Qt.resolvedUrl outside the shell dir, so go from
  // shellDir; the test stub has none and resolves the URL instead.
  readonly property string topDir: Quickshell.shellDir ? Quickshell.shellDir + "/.." : localPath(Qt.resolvedUrl(".."))
  FileView { id: versionFile; path: card.topDir + "/VERSION"; printErrors: false }
  FileView { id: licenseFile; path: card.topDir + "/LICENSE"; printErrors: false }

  function copy(text, what) {
    Quickshell.clipboardText = text
    copied = what
    copiedTimer.restart()
  }
  function copyEmail() { copy(About.ABOUT.supportEmail, "email") }
  function copyDetails() { copy(details, "details") }
  function email() { openUrl(About.supportMailto(version, details)) }
  function toggleLicense() { showLicense = !showLicense }

  Timer { id: copiedTimer; interval: 1500; onTriggered: card.copied = "" }
  onVisibleChanged: { showLicense = false; copied = "" }

  anchors.centerIn: parent
  width: 296 * px
  height: content.implicitHeight + 14 * px
  color: Qt.rgba(theme.darkerBackground.r, theme.darkerBackground.g, theme.darkerBackground.b, 0.96)
  border.color: theme.accent
  border.width: Math.max(1, px / 2)

  component Label: Text {
    width: 46 * card.px
    color: card.theme.accent
    font.family: card.theme.font
    font.bold: true
    font.pixelSize: card.font
  }
  component Value: Text {
    width: content.width - 46 * card.px - facts.columnSpacing
    wrapMode: Text.WordWrap
    textFormat: Text.PlainText
    color: card.theme.foreground
    font.family: card.theme.font
    font.pixelSize: card.font
  }
  component KeyButton: Rectangle {
    id: button
    property string key: ""
    property string label: ""
    signal activated()
    width: buttonText.implicitWidth + 6 * card.px
    height: buttonText.implicitHeight + 2 * card.px
    color: mouse.containsMouse ? Qt.rgba(card.theme.accent.r, card.theme.accent.g, card.theme.accent.b, 0.25) : "transparent"
    border.color: card.theme.accent
    border.width: Math.max(1, card.px / 4)
    Text {
      id: buttonText
      anchors.centerIn: parent
      text: button.key + "  " + button.label
      color: card.theme.foreground
      font.family: card.theme.font
      font.bold: true
      font.pixelSize: card.font
    }
    MouseArea {
      id: mouse
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: button.activated()
    }
  }

  Column {
    id: content
    anchors.centerIn: parent
    width: parent.width - 14 * card.px
    spacing: 3 * card.px

    Row {
      spacing: 6 * card.px
      // the app icon: the hero hanging from the cable
      Rectangle {
        width: 22 * card.px
        height: 28 * card.px
        color: card.theme.backdrop
        border.color: card.theme.accent
        border.width: Math.max(1, card.px / 4)
        PixelArt { anchors.centerIn: parent; theme: card.theme; px: card.px; sprite: "hang" }
      }
      Column {
        anchors.verticalCenter: parent.verticalCenter
        spacing: 1 * card.px
        Text {
          text: About.ABOUT.name.toUpperCase()
          color: card.theme.accent
          font.family: card.theme.font
          font.bold: true
          font.pixelSize: 12 * card.px
          font.letterSpacing: 2 * card.px
        }
        Text {
          text: About.ABOUT.tagline
          color: card.theme.foreground
          font.family: card.theme.font
          font.pixelSize: 5 * card.px
        }
        Text {
          objectName: "aboutVersion"
          text: "Version " + card.version
          color: card.theme.foreground
          opacity: 0.7
          font.family: card.theme.font
          font.pixelSize: card.font
        }
      }
    }

    Grid {
      id: facts
      visible: !card.showLicense
      columns: 2
      columnSpacing: 4 * card.px
      rowSpacing: 1.5 * card.px

      Label { text: "MADE BY" }
      Value { text: About.ABOUT.organization }
      Label { text: "CREATED" }
      Value { text: About.ABOUT.created }
      Label { text: "LICENSE" }
      Value { text: About.ABOUT.license + ", " + About.ABOUT.copyright }
      Label { text: "SUPPORT" }
      Value { text: About.ABOUT.supportEmail }
      Label { text: "PRIVACY" }
      Value { objectName: "aboutPrivacy"; text: About.ABOUT.privacy }
      Label { text: "CREDITS" }
      Value { text: About.ABOUT.credits }
      Label { text: "BUILT WITH" }
      Value { text: About.builtWith(card.quickshellVersion, card.qtVersion) }
    }

    Text {
      objectName: "aboutLicenseText"
      visible: card.showLicense
      width: content.width
      wrapMode: Text.WordWrap
      textFormat: Text.PlainText
      text: card.licenseText
      color: card.theme.foreground
      font.family: card.theme.font
      font.pixelSize: card.font
    }

    Flow {
      width: content.width
      spacing: 3 * card.px
      KeyButton { key: "R"; label: card.showLicense ? "Hide license" : "Read license"; onActivated: card.toggleLicense() }
      KeyButton { key: "E"; label: "Email"; onActivated: card.email() }
      KeyButton { key: "C"; label: card.copied === "email" ? "Copied" : "Copy email"; onActivated: card.copyEmail() }
      KeyButton { key: "V"; label: card.copied === "details" ? "Copied" : "Copy version details"; onActivated: card.copyDetails() }
    }

    Text {
      width: content.width
      horizontalAlignment: Text.AlignHCenter
      text: "Esc or F1 to go back"
      color: card.theme.accent
      font.family: card.theme.font
      font.bold: true
      font.pixelSize: 5 * card.px
    }
  }
}
