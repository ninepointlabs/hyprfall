import QtQuick

// A centred panel in the theme's colours: title, subtitle, some lines, an
// optional high score table and a footer.
Rectangle {
  id: card

  property var theme
  property real px: 4
  property string title: ""
  property string subtitle: ""
  property var lines: []
  property string footer: ""
  property var scores: null
  property int highlight: -1
  // a sprite or two from Sprites.js to show above the title
  property var art: []

  anchors.centerIn: parent
  width: 236 * px
  height: content.implicitHeight + 16 * px
  color: Qt.rgba(theme.darkerBackground.r, theme.darkerBackground.g, theme.darkerBackground.b, 0.94)
  border.color: theme.accent
  border.width: Math.max(1, px / 2)

  Column {
    id: content
    anchors.centerIn: parent
    width: parent.width - 16 * card.px
    spacing: 2 * card.px

    Row {
      visible: card.art.length > 0
      anchors.horizontalCenter: parent.horizontalCenter
      spacing: 10 * card.px
      Repeater {
        model: card.art
        PixelArt {
          required property string modelData
          theme: card.theme
          px: card.px * 1.5
          sprite: modelData
          anchors.bottom: parent.bottom
        }
      }
    }

    Text {
      width: parent.width
      horizontalAlignment: Text.AlignHCenter
      text: card.title
      color: card.theme.accent
      font.family: card.theme.font
      font.bold: true
      font.pixelSize: 18 * card.px
      font.letterSpacing: 2 * card.px
    }
    Text {
      width: parent.width
      horizontalAlignment: Text.AlignHCenter
      wrapMode: Text.WordWrap
      text: card.subtitle
      visible: text !== ""
      color: card.theme.foreground
      font.family: card.theme.font
      font.pixelSize: 6 * card.px
    }
    Item { width: 1; height: 2 * card.px }
    Repeater {
      model: card.lines
      Text {
        required property string modelData
        width: content.width
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
        text: modelData
        visible: modelData !== ""
        color: card.theme.foreground
        opacity: 0.85
        font.family: card.theme.font
        font.pixelSize: 5 * card.px
      }
    }
    Item { width: 1; height: 2 * card.px; visible: !!card.scores && card.scores.length > 0 }
    Column {
      visible: !!card.scores && card.scores.length > 0
      anchors.horizontalCenter: parent.horizontalCenter
      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: "HIGH SCORES"
        color: card.theme.accent
        font.family: card.theme.font
        font.bold: true
        font.pixelSize: 5 * card.px
      }
      Repeater {
        model: card.scores || []
        Text {
          required property var modelData
          required property int index
          text: (index + 1) + ".  " + String(modelData.score).padStart(6, " ") + "   " + String(modelData.found).padStart(2, " ") + " found  " + modelData.date + (modelData.won ? "  ★" : "")
          color: index === card.highlight ? card.theme.accent : card.theme.foreground
          font.family: card.theme.font
          font.bold: index === card.highlight
          font.pixelSize: 5 * card.px
        }
      }
    }
    Item { width: 1; height: 3 * card.px; visible: card.footer !== "" }
    Text {
      width: parent.width
      horizontalAlignment: Text.AlignHCenter
      text: card.footer
      visible: text !== ""
      color: card.theme.accent
      font.family: card.theme.font
      font.bold: true
      font.pixelSize: 6 * card.px
      SequentialAnimation on opacity {
        running: card.visible
        loops: Animation.Infinite
        NumberAnimation { to: 0.35; duration: 700 }
        NumberAnimation { to: 1; duration: 700 }
      }
    }
  }
}
