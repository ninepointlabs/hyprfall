.pragma library

// Hyprfall: the game engine.
//
// Plain functions over one plain-JSON state object, stepped at a fixed 60 Hz,
// so the QML front end only draws and plays sounds, and node can test it
// (test/engine.js). Coordinates are art pixels on a 320x200 stage, y down;
// the player's x is the centre of their feet and y is where the feet are.
//
// The jungle is 255 screens in a ring. Each screen comes from one byte, and
// the bytes are walked with an 8-bit Galois LFSR that runs both ways (next()
// and prev()), so the same screens come back when you walk left again. The
// tunnel underneath skips three screens per screen.

var W = 320
var H = 200
var DT = 1 / 60
var GROUND = 128          // feet on the jungle floor
var TUNNEL = 184          // feet on the tunnel floor
var CEILING = 150         // tunnel roof
var START_ROOM = 0xC4
var START_SCORE = 2000
var START_TIME = 20 * 60
var LIVES = 3
var TUNNEL_SKIP = 3

var WALK = 72
var CLIMB = 46
var JUMP_V = 190
var GRAVITY = 620
var HEIGHT = 20
var HALF = 4              // half the player's width

var LADDER_X = 160
var VINE = { x: 160, y: 28, len: 74, amp: 0.7, period: 3.2 }
var PIT = { left: 100, right: 220 }
var CROCS = [120, 164, 208]   // a jump apart (2 * JUMP_V / GRAVITY * WALK = 44px)
var TREASURE_X = 266
var WALL_W = 8

var SCENES = ["hole", "holes", "tar", "swamp", "protest-cable", "treasure", "deps", "protest"]

var TREASURES = [
  { kind: "keycap", name: "Golden Keycap", value: 2000 },
  { kind: "ruby", name: "Ruby", value: 3000 },
  { kind: "idol", name: "Arch Idol", value: 4000 },
  { kind: "crystal", name: "Hypr Crystal", value: 5000 }
]

var DEATHS = {
  splash: "Fell in the swamp. The protesters cheered.",
  tar: "Sank in a tarball. Should have used --strip-components.",
  deps: "Swallowed by dependency hell.",
  chomp: "Got yelled at by the anti-AI caucus.",
  fire: "Walked into a dumpster fire.",
  snake: "Bitten by a python. Should have used Ruby.",
  bug: "Stung by a bug. It works on my machine.",
  time: "Out of time. The sprint is over."
}

// ------------------------------------------------------------ the jungle --

function next(r) {
  var lsb = r & 1
  r >>= 1
  if (lsb) r ^= 0xB8
  return r
}

function prev(r) {
  if (r & 0x80) return (((r ^ 0xB8) << 1) | 1) & 0xFF
  return (r << 1) & 0xFF
}

function walk(r, steps) {
  for (var i = 0; i < Math.abs(steps); i++) r = steps > 0 ? next(r) : prev(r)
  return r
}

// Everything about one screen, decoded from its byte:
//   bits 0-2  what's on the ground (logs, a dumpster fire, a python) or which treasure
//   bits 3-5  the scene (ladder holes, tar pit, swamp, protesters, treasure...)
//   bits 6-7  the tree pattern; bit 7 also puts the firewall left or right
function room(r) {
  var obj = r & 7
  var scene = SCENES[(r >> 3) & 7]
  var rm = {
    id: r,
    scene: scene,
    trees: (r >> 6) & 3,
    ladder: scene === "hole" || scene === "holes",
    holes: scene === "hole" ? [[152, 168]] : scene === "holes" ? [[96, 112], [152, 168], [208, 224]] : [],
    pit: null,
    crocs: scene === "protest" || scene === "protest-cable",
    vine: scene === "tar" || scene === "swamp" || scene === "protest-cable" || scene === "deps",
    treasure: scene === "treasure" ? TREASURES[obj & 3] : null,
    logs: [],
    rolling: false,
    hazard: null,
    wall: null,
    bug: false
  }
  if (scene === "tar") rm.pit = { kind: "tar", shifting: false }
  else if (scene === "swamp" || rm.crocs) rm.pit = { kind: "water", shifting: false }
  else if (scene === "treasure") rm.pit = { kind: "tar", shifting: true }
  else if (scene === "deps") rm.pit = { kind: "deps", shifting: true }

  if (!rm.treasure) {
    switch (obj) {
    case 0: rm.logs = [272]; rm.rolling = true; break
    case 1: rm.logs = [256, 288]; rm.rolling = true; break
    case 2: rm.logs = [200, 296]; rm.rolling = true; break
    case 3: rm.logs = [240, 272, 304]; rm.rolling = true; break
    case 4: rm.logs = [264]; break
    case 5: rm.logs = [240, 264, 288]; break
    case 6: rm.hazard = { kind: "fire", x: 262 }; break
    case 7: rm.hazard = { kind: "snake", x: 262 }; break
    }
  }
  // Logs don't roll across a swamp: in pit screens they lie still on the far side.
  if (rm.rolling && rm.pit) {
    rm.logs = rm.logs.map(function(x, i) { return 244 + i * 26 })
    rm.rolling = false
  }

  if (rm.ladder) rm.wall = (r & 0x80) ? W - 32 : 24
  else rm.bug = true
  return rm
}

function treasureRooms() {
  var list = []
  var r = START_ROOM
  for (var i = 0; i < 255; i++) {
    if (room(r).treasure) list.push(r)
    r = next(r)
  }
  return list
}

var TOTAL_TREASURES = treasureRooms().length

// The protesters keep their signs down most of the time, then all start
// yelling at once. Standing on a yelling head is fatal.
function crocOpen(t) { return (t % 4) > 2.6 }

// Shifting pits: open, closing, closed, opening over 8 seconds.
function pitSpan(rm, t) {
  if (!rm.pit) return null
  var f = 1
  if (rm.pit.shifting) {
    var c = t % 8
    if (c < 2.5) f = 1
    else if (c < 4) f = 1 - (c - 2.5) / 1.5
    else if (c < 6.5) f = 0
    else f = (c - 6.5) / 1.5
  }
  var half = (PIT.right - PIT.left) / 2 * f
  return [160 - half, 160 + half]
}

function vineTip(t) {
  var w = 2 * Math.PI / VINE.period
  var a = VINE.amp * Math.sin(w * t)
  var da = VINE.amp * w * Math.cos(w * t)
  return {
    angle: a,
    x: VINE.x + VINE.len * Math.sin(a),
    y: VINE.y + VINE.len * Math.cos(a),
    vx: VINE.len * Math.cos(a) * da,
    vy: -VINE.len * Math.sin(a) * da
  }
}

function holeAt(rm, x) {
  for (var i = 0; i < rm.holes.length; i++)
    if (within(x, rm.holes[i])) return rm.holes[i]
  return null
}

function within(x, span) { return span && x >= span[0] && x <= span[1] }

// The floor under x, or null for a hole or a pit you'd fall into.
function floorAt(s, rm, x, under) {
  if (under) return TUNNEL
  if (holeAt(rm, x)) return null
  var span = pitSpan(rm, s.t)
  if (span && span[1] - span[0] > 1 && within(x, span)) {
    if (rm.crocs)
      for (var c = 0; c < CROCS.length; c++)
        if (Math.abs(x - CROCS[c]) <= 9) return GROUND
    return null
  }
  return GROUND
}

// ---------------------------------------------------------------- state --

function newGame() {
  var s = {
    room: START_ROOM,
    score: START_SCORE,
    time: START_TIME,
    lives: LIVES,
    collected: {},
    found: 0,
    t: 0,
    status: "play",
    cause: "",
    events: [],
    prevJump: false,
    prevUp: false,
    p: null,
    logs: [],
    bugX: 0,
    bugFace: -1,
    bumpCd: 0
  }
  respawn(s, 20)
  enterRoom(s)
  return s
}

function respawn(s, x) {
  s.p = { x: x, y: 40, vx: 0, vy: 0, mode: "air", under: false, face: 1, stumble: 0, dying: 0, cooldown: 0, walk: 0 }
}

function enterRoom(s) {
  var rm = room(s.room)
  s.logs = rm.logs.slice()
  s.bugX = s.p.x < 160 ? 240 : 80
  s.bugFace = s.p.x < 160 ? -1 : 1
}

function emit(s, name) { s.events.push(name) }

function addScore(s, n) { s.score = Math.max(0, s.score + n) }

function die(s, cause) {
  var p = s.p
  if (p.mode === "dying") return
  p.mode = "dying"
  p.dying = cause === "tar" || cause === "deps" ? 1.8 : 1.4
  p.vx = 0
  p.vy = cause === "chomp" || cause === "fire" || cause === "snake" || cause === "bug" ? -120 : 0
  s.cause = cause
  emit(s, cause === "splash" ? "splash" : cause === "tar" || cause === "deps" ? "sink" : "death")
}

function loseLife(s) {
  s.lives--
  if (s.lives <= 0) {
    s.lives = 0
    s.status = "over"
    emit(s, "gameover")
    return
  }
  respawn(s, 20)
  enterRoom(s)
  emit(s, "respawn")
}

// input: { left, right, up, down, jump } booleans, held this frame.
function step(s, input) {
  if (s.status !== "play") return s
  var p = s.p
  var rm = room(s.room)
  var jumpEdge = input.jump && !s.prevJump
  var upEdge = input.up && !s.prevUp
  s.prevJump = !!input.jump
  s.prevUp = !!input.up
  s.t += DT
  s.time = Math.max(0, s.time - DT)
  if (s.bumpCd > 0) s.bumpCd -= DT
  if (p.cooldown > 0) p.cooldown -= DT
  if (p.stumble > 0) p.stumble -= DT

  if (s.time <= 0 && p.mode !== "dying") {
    s.cause = "time"
    s.status = "over"
    emit(s, "gameover")
    return s
  }

  // rolling logs roll left and wrap
  if (rm.rolling)
    for (var i = 0; i < s.logs.length; i++) {
      s.logs[i] -= 40 * DT
      if (s.logs[i] < -10) s.logs[i] += W + 20
    }

  // the bug patrols the tunnel, heading for the player when they're down there
  if (rm.bug) {
    var target = p.under ? p.x : (s.bugFace > 0 ? 280 : 40)
    if (Math.abs(target - s.bugX) > 2) s.bugFace = target > s.bugX ? 1 : -1
    else if (!p.under) s.bugFace = -s.bugFace
    s.bugX = Math.max(40, Math.min(280, s.bugX + s.bugFace * 22 * DT))
  }

  var dir = (input.right ? 1 : 0) - (input.left ? 1 : 0)

  switch (p.mode) {
  case "dying":
    p.dying -= DT
    if (s.cause === "tar" || s.cause === "deps" || s.cause === "splash") p.y += 9 * DT
    else { p.vy += GRAVITY * DT; p.y = Math.min(p.y + p.vy * DT, (p.under ? TUNNEL : GROUND) + 24) }
    if (p.dying <= 0) loseLife(s)
    return s

  case "vine":
    var tip = vineTip(s.t)
    p.x = tip.x
    p.y = tip.y + HEIGHT - 2
    if (jumpEdge || input.down) {
      p.mode = "air"
      p.vx = tip.vx + p.face * 60
      p.vy = Math.min(tip.vy, 0) - 80
      p.cooldown = 0.45
      emit(s, "release")
    }
    break

  case "ladder":
    var cdir = (input.down ? 1 : 0) - (input.up ? 1 : 0)
    p.y += cdir * CLIMB * DT
    p.walk += Math.abs(cdir) * DT
    if (p.y >= TUNNEL) {
      p.y = TUNNEL
      p.mode = "ground"
      p.under = true
    } else if (p.y <= GROUND) {
      p.y = GROUND
      p.under = false
      // at the top of the ladder: hop off to either side
      if (dir !== 0 || jumpEdge) {
        p.face = dir || p.face
        p.mode = "air"
        p.vx = p.face * WALK
        p.vy = -130
        emit(s, "jump")
      }
    }
    break

  case "ground":
    var speed = WALK * (p.stumble > 0 ? 0.45 : 1)
    p.vx = dir * speed
    if (dir) { p.face = dir; p.walk += DT } else p.walk = 0
    var atLadder = rm.ladder && Math.abs(p.x - LADDER_X) < 12
    if (atLadder && input.down && !p.under) {
      p.mode = "ladder"; p.x = LADDER_X; p.vx = 0
      break
    }
    if (atLadder && input.up && p.under) {
      p.mode = "ladder"; p.x = LADDER_X; p.vx = 0
      break
    }
    if (jumpEdge || (upEdge && !atLadder)) {
      p.mode = "air"
      p.vy = -JUMP_V
      emit(s, "jump")
    }
    p.x += p.vx * DT
    if (p.mode === "ground" && floorAt(s, rm, p.x, p.under) === null) {
      p.mode = "air"
      p.vy = 0
    }
    break

  case "drop":
    p.vy += GRAVITY * DT
    p.y += p.vy * DT
    if (p.y >= TUNNEL) {
      p.y = TUNNEL
      p.under = true
      p.mode = "ground"
      p.vy = 0
      addScore(s, -100)
      emit(s, "thud")
    }
    break

  case "air":
    var lastY = p.y
    p.vy += GRAVITY * DT
    p.x += p.vx * DT
    p.y += p.vy * DT
    if (p.under && p.y - HEIGHT < CEILING) {
      p.y = CEILING + HEIGHT
      if (p.vy < 0) p.vy = 0
    }
    if (rm.vine && !p.under && p.cooldown <= 0) {
      var t2 = vineTip(s.t)
      if (Math.abs(p.x - t2.x) < 7 && Math.abs(p.y - HEIGHT + 2 - t2.y) < 9) {
        p.mode = "vine"
        p.vx = 0; p.vy = 0
        p.face = t2.vx >= 0 ? 1 : -1
        emit(s, "grab")
        break
      }
    }
    var hole = !p.under && p.vy >= 0 && p.y > GROUND ? holeAt(rm, p.x) : null
    if (hole) {
      // down a hole: straight down the shaft into the tunnel
      p.mode = "drop"
      p.x = Math.max(hole[0] + HALF, Math.min(hole[1] - HALF, p.x))
      p.vx = 0
      break
    }
    var floor = floorAt(s, rm, p.x, p.under)
    // a few pixels of lip, so landing on the far edge of a pit counts
    if (floor !== null && p.vy >= 0 && p.y >= floor && lastY <= floor + 6) {
      p.y = floor
      p.mode = "ground"
      p.vx = 0
      emit(s, "land")
    } else if (!p.under && p.y > GROUND + 5) {
      var span = pitSpan(rm, s.t)
      if (rm.pit && within(p.x, span)) die(s, rm.pit.kind === "water" ? "splash" : rm.pit.kind)
      else if (p.y > GROUND + 12) {
        // the pit closed under you (or something stranger): stand back up
        p.y = GROUND
        p.mode = "ground"
        p.vx = 0
      }
    }
    break
  }

  if (p.mode === "dying") return s

  // the firewall
  if (p.under && rm.wall !== null) {
    var wl = rm.wall, wr = rm.wall + WALL_W
    if (p.x + HALF > wl && p.x - HALF < wr) {
      p.x = p.x < wl + WALL_W / 2 ? wl - HALF : wr + HALF
      p.vx = 0
    }
  }

  // screen edges
  if (p.x < 2 || p.x > W - 2) {
    var step = p.x < 2 ? -1 : 1
    if (p.mode === "vine" || p.mode === "ladder" || p.mode === "drop") {
      p.x = Math.max(2, Math.min(W - 2, p.x))
    } else {
      s.room = walk(s.room, step * (p.under ? TUNNEL_SKIP : 1))
      p.x = step < 0 ? W - 6 : 6
      enterRoom(s)
      emit(s, "room")
      rm = room(s.room)
    }
  }

  hazards(s, rm)
  return s
}

function overlap(ax0, ay0, ax1, ay1, bx0, by0, bx1, by1) {
  return ax0 < bx1 && ax1 > bx0 && ay0 < by1 && ay1 > by0
}

function hazards(s, rm) {
  var p = s.p
  var x0 = p.x - HALF, x1 = p.x + HALF, y0 = p.y - HEIGHT, y1 = p.y
  if (!p.under && p.mode !== "ladder") {
    for (var i = 0; i < s.logs.length; i++) {
      if (overlap(x0, y0, x1, y1, s.logs[i] - 7, GROUND - 9, s.logs[i] + 7, GROUND)) {
        addScore(s, -2)
        p.stumble = 0.3
        if (s.bumpCd <= 0) { emit(s, "bump"); s.bumpCd = 0.5 }
      }
    }
    if (rm.hazard) {
      var hx = rm.hazard.x
      var top = rm.hazard.kind === "fire" ? GROUND - 10 : GROUND - 12
      if (overlap(x0 + 1, y0, x1 - 1, y1, hx - 5, top, hx + 5, GROUND)) { die(s, rm.hazard.kind); return }
    }
    if (rm.crocs && p.mode === "ground" && crocOpen(s.t)) {
      for (var c = 0; c < CROCS.length; c++)
        if (p.x >= CROCS[c] - 8 && p.x <= CROCS[c] + 4) { die(s, "chomp"); return }
    }
    if (rm.treasure && !s.collected[rm.id] &&
        overlap(x0, y0, x1, y1, TREASURE_X - 6, GROUND - 12, TREASURE_X + 6, GROUND)) {
      s.collected[rm.id] = true
      s.found++
      addScore(s, rm.treasure.value)
      emit(s, "treasure")
      if (s.found >= TOTAL_TREASURES) {
        s.status = "won"
        emit(s, "win")
      }
    }
  }
  if (p.under && rm.bug && p.mode !== "ladder" &&
      overlap(x0 + 1, y0, x1 - 1, y1, s.bugX - 6, TUNNEL - 8, s.bugX + 6, TUNNEL)) {
    die(s, "bug")
  }
}

// Keep a save from an older version, or a hand-edited one, from breaking anything.
function sanitizeScores(list) {
  if (!Array.isArray(list)) return []
  return list.filter(function(e) {
    return e && typeof e.score === "number" && isFinite(e.score) && e.score >= 0
  }).map(function(e) {
    return { score: Math.floor(e.score), found: Math.max(0, Math.floor(Number(e.found) || 0)), won: !!e.won, date: String(e.date || "").slice(0, 10) }
  }).sort(function(a, b) { return b.score - a.score }).slice(0, 5)
}

function recordScore(list, s, date) {
  var entry = { score: s.score, found: s.found, won: s.status === "won", date: date }
  var out = sanitizeScores(list.concat([entry]))
  return { scores: out, rank: out.indexOf(out.filter(function(e) { return e.score === entry.score && e.date === entry.date && e.found === entry.found })[0]) }
}

function clock(seconds) {
  var t = Math.ceil(seconds)
  var m = Math.floor(t / 60), sec = t % 60
  return m + ":" + (sec < 10 ? "0" : "") + sec
}
