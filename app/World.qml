import QtQuick
import "Engine.js" as Engine

// The playfield: one 320x200 screen of jungle at `px` screen pixels per art
// pixel. The static scenery is a Canvas that repaints only when the screen,
// the scale or the theme changes; everything that moves is an item bound to
// the engine state, re-read whenever `frame` ticks.
Item {
  id: world

  property var game
  property int frame: 0
  property real px: 4
  property var theme
  property bool showHero: true

  readonly property var rm: (frame, game ? Engine.room(game.room) : Engine.room(Engine.START_ROOM))
  readonly property real t: (frame, game ? game.t : 0)

  width: Engine.W * px
  height: Engine.H * px
  clip: true

  readonly property var signs: ["NO AI", "HUMANS\nONLY", "STOP\nVIBING", "AI = SLOP", "RTFM", "CTRL+Z\nTHE AI", "WRITE\nIT BY\nHAND"]

  // ---------------------------------------------------------- scenery --
  Canvas {
    id: scenery
    anchors.fill: parent
    renderStrategy: Canvas.Cooperative
    antialiasing: false
    smooth: false

    property var key: [world.rm.id, world.px, world.theme ? world.theme.revision : 0]
    onKeyChanged: requestPaint()

    onPaint: {
      var ctx = getContext("2d")
      var th = world.theme
      var p = world.px
      var rm = world.rm
      ctx.reset()
      function rect(c, x, y, w, h) { ctx.fillStyle = c; ctx.fillRect(Math.floor(x * p), Math.floor(y * p), Math.ceil(w * p), Math.ceil(h * p)) }

      rect(th.hud, 0, 0, Engine.W, 14)
      // jungle depth behind the trunks: darker the lower you look
      var deep = th.backdrop
      for (var band = 0; band < 6; band++)
        rect(Qt.darker(deep, 1 + band * 0.07), 0, 14 + band * 19, Engine.W, 19)

      var seed = rm.id * 7 + 13
      function rnd(n) { seed = (seed * 73 + 41) % 251; return seed % n }

      // far trees, thin and dim
      for (var ft = 8; ft < Engine.W; ft += 26 + rnd(14))
        rect(Qt.darker(deep, 1.35), ft, 40, 3, Engine.GROUND - 40)

      // trunks: four layouts, picked by bits 6-7
      var layouts = [[38, 112, 196, 278], [22, 92, 230, 300], [60, 140, 180, 262], [30, 128, 214, 290]]
      var trunks = layouts[rm.trees]
      for (var i = 0; i < trunks.length; i++) {
        var tx = trunks[i]
        rect(th.trunkShade, tx - 1, 40, 9, Engine.GROUND - 40)
        rect(th.trunk, tx, 40, 6, Engine.GROUND - 40)
        rect(Qt.lighter(th.trunk, 1.25), tx + 1, 40, 1, Engine.GROUND - 40)
        for (var k = 0; k < 4; k++) rect(th.trunkShade, tx + 2 + (k % 2) * 2, 56 + k * 17 + (i * 5) % 9, 2, 4)
        // roots
        rect(th.trunk, tx - 3, Engine.GROUND - 3, 12, 3)
        rect(th.trunkShade, tx - 4, Engine.GROUND - 1, 14, 1)
        // a branch
        var dir = i % 2 ? 1 : -1
        var byy = 48 + (i * 7) % 12
        rect(th.trunk, dir > 0 ? tx + 6 : tx - 12, byy, 12, 3)
        rect(th.canopy, dir > 0 ? tx + 14 : tx - 18, byy - 4, 8, 5)
      }

      // canopy: round clumps of leaves, a shaded underside, hanging tendrils
      function blob(c, cx, cy, r) {
        for (var dy = -r; dy <= r; dy++) {
          var w = Math.floor(Math.sqrt(r * r - dy * dy) + 0.3)
          rect(c, cx - w, cy + dy, 2 * w + 1, 1)
        }
      }
      rect(th.canopyShade, 0, 14, Engine.W, 22)
      var light = Qt.lighter(th.canopy, 1.22)
      var clumps = []
      for (var x = -6; x < Engine.W + 12; x += 11 + rnd(7)) clumps.push([x, 30 + rnd(10), 9 + rnd(6)])
      for (var c1 = 0; c1 < clumps.length; c1++) blob(th.canopyShade, clumps[c1][0] + 1, clumps[c1][1] + 3, clumps[c1][2])
      for (var c2 = 0; c2 < clumps.length; c2++) blob(th.canopy, clumps[c2][0], clumps[c2][1], clumps[c2][2])
      for (var c3 = 0; c3 < clumps.length; c3++) {
        var cl = clumps[c3]
        blob(light, cl[0] - 3, cl[1] - cl[2] / 2, 2)
        rect(light, cl[0] + 2, cl[1] - 2 + rnd(5), 2, 1)
        if (rnd(3) === 0) {
          var len = 8 + rnd(18)
          rect(th.canopyShade, cl[0] + 3, cl[1] + cl[2], 1, len)
          rect(th.canopy, cl[0] + 2, cl[1] + cl[2] + len - 2, 3, 2)
        }
      }
      rect(th.canopy, 0, 14, Engine.W, 8)

      // the jungle floor and the earth under it
      rect(th.grass, 0, Engine.GROUND, Engine.W, 2)
      for (var gx = 2; gx < Engine.W; gx += 7 + rnd(9)) rect(th.canopy, gx, Engine.GROUND - 2, 1 + rnd(2), 2)
      rect(th.ground, 0, Engine.GROUND + 2, Engine.W, 10)
      rect(th.dirt, 0, Engine.GROUND + 12, Engine.W, Engine.CEILING - Engine.GROUND - 12)
      for (var dx = 0; dx < Engine.W; dx += 16) rect(Qt.darker(th.dirt, 1.3), dx + (dx / 16 % 2) * 7, Engine.GROUND + 15, 4, 2)

      // the tunnel
      rect(th.tunnel, 0, Engine.CEILING, Engine.W, Engine.TUNNEL - Engine.CEILING)
      rect(th.bedrock, 0, Engine.TUNNEL, Engine.W, Engine.H - Engine.TUNNEL)
      rect(Qt.lighter(th.bedrock, 1.4), 0, Engine.TUNNEL, Engine.W, 1)

      // holes, and the ladder down the middle one
      for (var hi = 0; hi < rm.holes.length; hi++) {
        var hs = rm.holes[hi]
        rect(th.tunnel, hs[0], Engine.GROUND, hs[1] - hs[0], Engine.CEILING - Engine.GROUND)
      }
      if (rm.ladder) {
        var lx = Engine.LADDER_X - 6
        rect(th.ladder, lx, Engine.GROUND - 2, 2, Engine.TUNNEL - Engine.GROUND + 2)
        rect(th.ladder, lx + 10, Engine.GROUND - 2, 2, Engine.TUNNEL - Engine.GROUND + 2)
        for (var ry = Engine.GROUND + 2; ry < Engine.TUNNEL; ry += 7) rect(th.ladder, lx, ry, 12, 2)
      }

      // the firewall
      if (rm.wall !== null) {
        var wx = rm.wall
        rect(th.mortar, wx, Engine.CEILING, Engine.WALL_W, Engine.TUNNEL - Engine.CEILING)
        for (var by = Engine.CEILING; by < Engine.TUNNEL; by += 4) {
          var off = ((by - Engine.CEILING) / 4) % 2 ? 0 : 2
          for (var bx = -2; bx < Engine.WALL_W; bx += 4) {
            var x0 = Math.max(0, bx + off), x1 = Math.min(Engine.WALL_W, bx + off + 3)
            if (x1 > x0) rect(th.brick, wx + x0, by, x1 - x0, 3)
          }
        }
      }

      // the hook the cable hangs from
      if (rm.vine) {
        rect(th.trunkShade, Engine.VINE.x - 14, Engine.VINE.y - 4, 28, 3)
        rect(th.cable, Engine.VINE.x - 1, Engine.VINE.y - 2, 3, 3)
      }
    }
  }

  // ------------------------------------------------------------- the pit --
  Item {
    id: pit
    readonly property var span: (world.frame, Engine.pitSpan(world.rm, world.t))
    visible: !!span && span[1] - span[0] > 0.5
    x: span ? span[0] * world.px : 0
    y: (Engine.GROUND + 1) * world.px
    width: span ? (span[1] - span[0]) * world.px : 0
    height: 12 * world.px

    readonly property string kind: world.rm.pit ? world.rm.pit.kind : ""
    readonly property color fill: kind === "water" ? world.theme.water : kind === "deps" ? world.theme.deps : world.theme.tar
    readonly property color shine: kind === "water" ? world.theme.waterShine : kind === "deps" ? world.theme.depsShine : world.theme.tarShine

    Rectangle {
      anchors.fill: parent
      radius: 5 * world.px
      color: pit.fill
    }
    Rectangle {
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.margins: 4 * world.px
      y: 2 * world.px
      height: world.px
      color: pit.shine
      opacity: 0.7
    }
    // ripples / bubbles
    Repeater {
      model: 5
      Rectangle {
        required property int index
        readonly property real phase: (world.t * (pit.kind === "water" ? 9 : 4) + index * 23) % Math.max(1, pit.width / world.px)
        x: phase * world.px
        y: (4 + (index % 3) * 2) * world.px
        width: (pit.kind === "water" ? 6 : 2) * world.px
        height: world.px
        color: pit.shine
        opacity: 0.6
      }
    }
    Text {
      visible: pit.kind === "deps" && pit.width > 40 * world.px
      anchors.centerIn: parent
      text: "node_modules"
      color: pit.shine
      opacity: 0.55
      font.family: world.theme.font
      font.bold: true
      font.pixelSize: 6 * world.px
    }
  }

  // ------------------------------------------- the anti-AI swamp caucus --
  Repeater {
    model: world.rm.crocs ? Engine.CROCS.length : 0
    Item {
      id: croc
      required property int index
      readonly property real cx: Engine.CROCS[index]
      readonly property bool yelling: (world.frame, Engine.crocOpen(world.t))
      readonly property real bob: yelling ? Math.round(Math.sin(world.t * 18 + index) * 1.5) : 0

      // the picket sign, held up behind the head
      Rectangle {
        x: (croc.cx + 11) * world.px
        y: (Engine.GROUND - 18 + croc.bob - (croc.yelling ? 4 : 0)) * world.px
        width: world.px
        height: (20 + (croc.yelling ? 4 : 0)) * world.px
        color: world.theme.trunk
      }
      Rectangle {
        id: sign
        width: 26 * world.px
        height: 13 * world.px
        x: (croc.cx + 11.5) * world.px - width / 2
        y: (Engine.GROUND - 30 + croc.bob - (croc.yelling ? 4 : 0)) * world.px
        color: world.theme.sign
        border.color: world.theme.trunkShade
        border.width: Math.max(1, world.px / 2)
        rotation: croc.yelling ? Math.sin(world.t * 14 + croc.index) * 8 : 0
        Text {
          anchors.centerIn: parent
          width: parent.width - 2 * world.px
          horizontalAlignment: Text.AlignHCenter
          text: world.signs[(world.rm.id + croc.index * 3) % world.signs.length]
          color: world.theme.signInk
          font.family: world.theme.font
          font.bold: true
          font.pixelSize: 3.2 * world.px
          lineHeight: 0.85
          fontSizeMode: Text.Fit
          minimumPixelSize: 2
          height: parent.height - world.px
          verticalAlignment: Text.AlignVCenter
        }
      }
      PixelArt {
        theme: world.theme
        px: world.px
        sprite: croc.yelling ? "gatorYell" : "gator"
        x: (croc.cx - 11) * world.px
        y: (Engine.GROUND - 2 - (croc.yelling ? 1 : 0)) * world.px
      }
      Text {
        visible: croc.yelling
        text: ["NO!", "BOO!", "SLOP!"][(croc.index + world.rm.id) % 3]
        x: (croc.cx - 20) * world.px
        y: (Engine.GROUND - 12 - croc.bob) * world.px
        color: world.theme.red
        font.family: world.theme.font
        font.bold: true
        font.pixelSize: 5 * world.px
        style: Text.Outline
        styleColor: world.theme.hud
      }
    }
  }

  // ----------------------------------------------------- rolling logs --
  Repeater {
    model: (world.frame, world.game ? world.game.logs.length : 0)
    PixelArt {
      required property int index
      theme: world.theme
      px: world.px
      readonly property real lx: (world.frame, world.game.logs[index] || 0)
      sprite: world.rm.rolling && Math.floor(lx / 4) % 2 ? "log2" : "log1"
      x: Math.round(lx - 7) * world.px
      y: (Engine.GROUND - 8) * world.px
    }
  }

  // --------------------------------------- the dumpster fire / the python
  PixelArt {
    visible: !!world.rm.hazard
    theme: world.theme
    px: world.px
    sprite: !world.rm.hazard ? "" : world.rm.hazard.kind === "fire"
            ? (Math.floor(world.t * 7) % 2 ? "fire2" : "fire1")
            : (Math.floor(world.t * 2.5) % 2 ? "snake2" : "snake1")
    flip: true
    x: world.rm.hazard ? (world.rm.hazard.x - 6) * world.px : 0
    y: (Engine.GROUND - height / world.px + 1) * world.px
  }

  // ---------------------------------------------------------- treasure --
  Item {
    visible: (world.frame, !!world.rm.treasure && !!world.game && !world.game.collected[world.rm.id])
    PixelArt {
      id: loot
      theme: world.theme
      px: world.px
      sprite: world.rm.treasure ? world.rm.treasure.kind : ""
      x: (Engine.TREASURE_X - 6) * world.px
      y: (Engine.GROUND - height / world.px + Math.round(Math.sin(world.t * 3))) * world.px
    }
    PixelArt {
      theme: world.theme
      px: world.px
      sprite: "sparkle"
      visible: (world.t % 1.4) < 0.25
      x: (Engine.TREASURE_X + 2) * world.px
      y: (Engine.GROUND - 14) * world.px
    }
  }

  // ----------------------------------------------- the bug in the tunnel
  PixelArt {
    visible: world.rm.bug
    theme: world.theme
    px: world.px
    sprite: Math.floor(world.t * 6) % 2 ? "bug2" : "bug1"
    flip: (world.frame, !!world.game && world.game.bugFace < 0)
    x: (world.frame, world.game ? Math.round(world.game.bugX - 6) * world.px : 0)
    y: (Engine.TUNNEL - 8) * world.px
  }

  // ------------------------------------------- the ethernet cable vine --
  Item {
    visible: world.rm.vine
    readonly property var tip: (world.frame, Engine.vineTip(world.t))
    Rectangle {
      x: Engine.VINE.x * world.px - width / 2
      y: Engine.VINE.y * world.px
      width: Math.max(1, Math.round(world.px * 1.25))
      height: Engine.VINE.len * world.px
      color: world.theme.cable
      transformOrigin: Item.Top
      rotation: -parent.tip.angle * 180 / Math.PI
      antialiasing: true
    }
    PixelArt {
      theme: world.theme
      px: world.px
      sprite: "plug"
      x: (parent.tip.x - 2) * world.px
      y: (parent.tip.y - 2) * world.px
    }
  }

  // --------------------------------------------------------- the hero --
  PixelArt {
    id: hero
    readonly property var p: (world.frame, world.game ? world.game.p : null)
    readonly property bool sinking: world.frame >= 0 && !!p && p.mode === "dying" && world.game && (world.game.cause === "splash" || world.game.cause === "tar" || world.game.cause === "deps")
    visible: !!p && world.showHero
    theme: world.theme
    px: world.px
    flip: !!p && p.face < 0
    sprite: {
      world.frame
      if (!p) return "stand"
      switch (p.mode) {
      case "vine": return "hang"
      case "ladder": return Math.floor(p.y / 5) % 2 ? "climb1" : "climb2"
      case "air": return "jump"
      case "drop": return "jump"
      case "dying": return sinking ? "jump" : "dead"
      }
      if (p.walk <= 0) return "stand"
      return ["run1", "run2", "run3", "run2"][Math.floor(p.walk * 10) % 4]
    }
    x: (world.frame, p ? Math.round(p.x - 6) * world.px : 0)
    // feet on the bottom row; hanging, the hands go on the plug instead
    y: (world.frame, p ? Math.round(p.y - (p.mode === "vine" ? 19 : 22)) * world.px : 0)
    opacity: (world.frame, sinking ? Math.max(0, p.dying / 1.8) : 1)
  }

  // the surface of the pit hides a sinking hero's legs
  Rectangle {
    visible: hero.sinking && pit.visible
    x: pit.x
    width: pit.width
    y: pit.y + 2 * world.px
    height: pit.height - 2 * world.px
    radius: 4 * world.px
    color: pit.fill
  }
}
