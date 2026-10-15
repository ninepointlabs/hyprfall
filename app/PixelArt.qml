import QtQuick
import "Sprites.js" as Sprites

// One sprite from Sprites.js, painted at `px` screen pixels per art pixel in
// the current theme's colours. Moving it is free; only a new sprite, a new
// scale or a theme change repaints. `flip` mirrors it without a repaint.
Canvas {
  id: root

  property string sprite: ""
  property real px: 4
  property bool flip: false
  property var theme
  readonly property var rows: Sprites.SPRITES[sprite] || []
  readonly property int revision: theme ? theme.revision : 0

  width: rows.length ? rows[0].length * px : 0
  height: rows.length * px
  renderStrategy: Canvas.Cooperative
  antialiasing: false
  smooth: false
  transform: Scale { origin.x: root.width / 2; xScale: root.flip ? -1 : 1 }

  onRowsChanged: requestPaint()
  onPxChanged: requestPaint()
  onRevisionChanged: requestPaint()
  // a Canvas that was hidden when its content changed never paints on its own
  onVisibleChanged: if (visible) requestPaint()

  onPaint: {
    var ctx = getContext("2d")
    ctx.reset()
    var r = rows
    if (!r.length || !theme) return
    var w = r[0].length
    var p = px
    for (var y = 0; y < r.length; y++) {
      var row = r[y]
      var x = 0
      while (x < w) {
        var c = row.charAt(x)
        if (c === ".") { x++; continue }
        // paint horizontal runs of one colour as one rect
        var run = 1
        while (x + run < w && row.charAt(x + run) === c) run++
        ctx.fillStyle = theme.role(Sprites.roleOf(sprite, c))
        ctx.fillRect(Math.floor(x * p), Math.floor(y * p), Math.ceil(run * p), Math.ceil(p))
        x += run
      }
    }
  }
}
