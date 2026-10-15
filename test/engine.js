#!/usr/bin/env node
// Engine tests: the jungle ring, every kind of screen can be crossed, and
// thousands of frames of random input never break the state.
// Run: node test/engine.js
"use strict"

const fs = require("fs")
const path = require("path")
const vm = require("vm")
const assert = require("assert")

const source = fs.readFileSync(path.join(__dirname, "..", "app", "Engine.js"), "utf8").replace(/^\.pragma library\s*/m, "")
const ctx = {}
vm.runInNewContext(source + "\nthis.E = { next, prev, walk, room, newGame, step, vineTip, pitSpan, gnomesYelling, floorAt, treasureRooms, recordScore, sanitizeScores, clock, SCENES, TOTAL_TREASURES, START_ROOM, GROUND, TUNNEL, W, DT, PIT, GNOMES, LADDER_X, TUNNEL_SKIP }", ctx)
const E = ctx.E

let passed = 0
function test(name, fn) {
  try { fn(); passed++; console.log("ok   " + name) } catch (e) { console.error("FAIL " + name + "\n     " + e.message); process.exitCode = 1 }
}

const NONE = { left: false, right: false, up: false, down: false, jump: false }
const input = (o) => Object.assign({}, NONE, o || {})

// a game standing on the floor of a given screen
function standing(roomId, x, t) {
  const s = E.newGame()
  s.room = roomId
  s.p = { x, y: E.GROUND, vx: 0, vy: 0, mode: "ground", under: false, face: 1, stumble: 0, dying: 0, cooldown: 0, walk: 0 }
  s.logs = []
  s.t = t || 0
  return s
}

function firstRoom(pred) {
  let r = E.START_ROOM
  for (let i = 0; i < 255; i++) { if (pred(E.room(r))) return r; r = E.next(r) }
  throw new Error("no such room")
}

function run(s, frames, inp) {
  for (let i = 0; i < frames && s.status === "play"; i++) E.step(s, typeof inp === "function" ? inp(i, s) : input(inp))
  return s
}

test("the LFSR visits all 255 screens and runs backwards", () => {
  const seen = new Set()
  let r = E.START_ROOM
  for (let i = 0; i < 255; i++) {
    assert(!seen.has(r), "repeated " + r)
    seen.add(r)
    assert.strictEqual(E.prev(E.next(r)), r)
    r = E.next(r)
  }
  assert.strictEqual(r, E.START_ROOM)
  assert(!seen.has(0))
})

test("32 treasures, every scene type appears", () => {
  assert.strictEqual(E.TOTAL_TREASURES, 32)
  const kinds = new Set()
  let r = E.START_ROOM
  for (let i = 0; i < 255; i++) { kinds.add(E.room(r).scene); r = E.next(r) }
  assert.strictEqual(kinds.size, E.SCENES.length)
})

test("the start screen is safe to land on", () => {
  const s = E.newGame()
  run(s, 120, NONE)
  assert.strictEqual(s.p.mode, "ground")
  assert.strictEqual(s.status, "play")
})

test("a jump clears a ladder hole", () => {
  const r = firstRoom((rm) => rm.scene === "holes")
  const s = standing(r, 80)
  // run right, jump just before the first hole (96..112)
  run(s, 60, (i, g) => input({ right: true, jump: g.p.x > 88 && g.p.x < 92 }))
  assert(!s.p.under, "fell in")
  assert(s.p.x > 112)
})

test("walking into a hole drops you into the tunnel for -100", () => {
  const r = firstRoom((rm) => rm.scene === "hole")
  const s = standing(r, 140)
  const before = s.score
  run(s, 90, { right: true })
  run(s, 60, NONE)
  assert(s.p.under, "not underground")
  assert.strictEqual(s.p.y, E.TUNNEL)
  assert.strictEqual(s.score, before - 100)
})

test("ladder down and back up", () => {
  const r = firstRoom((rm) => rm.scene === "hole")
  const s = standing(r, 150)
  run(s, 120, { down: true })
  assert(s.p.under && s.p.mode === "ground", "didn't reach the tunnel: " + s.p.mode)
  run(s, 120, { up: true })
  assert(!s.p.under && s.p.mode === "ladder" && s.p.y === E.GROUND)
  run(s, 60, (i) => input({ right: i < 10 }))
  assert(!s.p.under && s.p.mode === "ground" && s.p.x > 168, "didn't hop off: " + JSON.stringify(s.p))
})

test("the tunnel skips three screens", () => {
  const r = firstRoom((rm) => rm.scene === "hole")
  const s = standing(r, 150)
  run(s, 120, { down: true })
  const wallLeft = E.room(r).wall < 160
  run(s, 600, (i, g) => g.room === r ? input(wallLeft ? { right: true } : { left: true }) : input())
  assert.strictEqual(s.room, E.walk(r, (wallLeft ? 1 : -1) * E.TUNNEL_SKIP))
})

test("the firewall blocks the tunnel", () => {
  const r = firstRoom((rm) => rm.scene === "hole")
  const s = standing(r, 150)
  run(s, 120, { down: true })
  const wallLeft = E.room(r).wall < 160
  run(s, 400, wallLeft ? { left: true } : { right: true })
  assert.strictEqual(s.room, r)
})

// Crossing a cable screen: wait at the edge, jump for the cable, ride it,
// let go on the far side. Some timing has to work, with a comfortable window.
function cableWindows(scene) {
  const r = firstRoom((rm) => rm.scene === scene)
  let grabs = 0, crossings = 0
  for (let d = 0; d < 200; d++) {
    const s = standing(r, E.PIT.left - 6, 0)
    run(s, d, NONE)
    run(s, 50, (i) => input({ right: i < 2, jump: i === 0 }))
    if (s.p.mode !== "vine") continue
    grabs++
    for (let hold = 0; hold < 200; hold++) {
      const g = JSON.parse(JSON.stringify(s))
      run(g, hold, NONE)
      if (g.p.mode !== "vine") break
      run(g, 1, { down: true })
      run(g, 120, NONE)
      if (g.status === "play" && g.p.mode === "ground" && !g.p.under && g.p.x > E.PIT.right) { crossings++; break }
    }
  }
  return { grabs, crossings }
}

for (const scene of ["tar", "swamp", "protest-cable", "deps"]) {
  test(`the cable gets you across a ${scene} screen`, () => {
    const w = cableWindows(scene)
    assert(w.grabs >= 6, "only " + w.grabs + " frames to grab the cable")
    assert(w.crossings >= 6, "only " + w.crossings + " ways across")
  })
}

test("letting go of the cable carries you, even at the end of the swing", () => {
  const r = firstRoom((rm) => rm.scene === "swamp")
  // hanging on, swinging right, at the far end of the swing (tip barely moving)
  const s = standing(r, 160, 0)
  const quarter = 3.2 / 4
  s.t = quarter - E.DT
  s.p.mode = "vine"
  s.p.face = 1
  run(s, 1, NONE)
  const x0 = s.p.x
  run(s, 1, { down: true })
  assert.strictEqual(s.p.mode, "air")
  run(s, 120, NONE)
  assert.strictEqual(s.p.mode, "ground", "landed: " + s.p.mode + " " + s.cause)
  assert(s.p.x - x0 >= 40, "only drifted " + (s.p.x - x0).toFixed(1) + "px")

  // leaning back the other way flies back the other way
  const b = standing(r, 160, 0)
  b.t = quarter - E.DT
  b.p.mode = "vine"
  b.p.face = 1
  run(b, 1, { left: true })
  run(b, 1, { left: true, jump: true })
  assert(b.p.vx < -60, "vx " + b.p.vx)
})

test("protesters can be hopped head to head", () => {
  const r = firstRoom((rm) => rm.scene === "protest")
  let ok = 0
  for (let d = 0; d < 240; d += 4) {
    const s = standing(r, 76, 0)
    run(s, d, NONE)
    // hop the moment you land, as long as they aren't about to start yelling
    run(s, 300, (i, g) => input({ right: g.p.mode === "ground" && g.p.x < 240 && (g.t % 4 < 0.3 || g.p.x > 100), jump: g.p.mode === "ground" && g.p.x < 240 && (g.t % 4 < 0.3 || g.p.x > 100) }))
    if (s.status === "play" && s.p.mode !== "dying" && s.lives === 3 && s.p.x > E.PIT.right) ok++
  }
  assert(ok >= 3, "only " + ok + " safe crossings")
})

test("yelling protesters are fatal, quiet ones are stepping stones", () => {
  const r = firstRoom((rm) => rm.scene === "protest")
  const s = standing(r, E.GNOMES[1], 0)
  run(s, 60, NONE)
  assert.strictEqual(s.p.mode, "ground")
  run(s, 120, NONE)
  assert.strictEqual(s.p.mode, "dying")
  assert.strictEqual(s.cause, "chomp")
})

test("a shifting pit closes so you can walk across", () => {
  const r = firstRoom((rm) => rm.scene === "treasure")
  const s = standing(r, E.PIT.left - 10, 0)
  run(s, Math.round(4.2 / E.DT), NONE)
  run(s, 150, { right: true })
  assert(s.p.x > E.PIT.right && s.p.mode !== "dying")
})

test("treasure scores and counts", () => {
  const r = firstRoom((rm) => rm.scene === "treasure")
  const s = standing(r, 250, 4.2)
  const value = E.room(r).treasure.value
  run(s, 40, { right: true })
  assert.strictEqual(s.found, 1)
  assert.strictEqual(s.score, 2000 + value)
  run(s, 1, { right: true })
  assert.strictEqual(s.found, 1)
})

test("dumpster fires and pythons kill, jumping clears them", () => {
  for (const kind of ["fire", "snake"]) {
    const r = firstRoom((rm) => rm.hazard && rm.hazard.kind === kind)
    const a = standing(r, 230)
    run(a, 120, { right: true })
    assert.strictEqual(a.cause, kind)
    const b = standing(r, 230)
    run(b, 70, (i, g) => input({ right: true, jump: g.p.x > 236 && g.p.x < 242 }))
    assert(b.p.mode !== "dying" && b.p.x > 280, kind + " not cleared: " + JSON.stringify(b.p))
  }
})

test("rolling logs cost points, not lives", () => {
  const r = firstRoom((rm) => rm.rolling)
  const s = standing(r, 40)
  s.logs = E.room(r).logs.slice()
  run(s, 600, NONE)
  assert(s.score < 2000, "never got hit")
  assert.strictEqual(s.lives, 3)
})

test("losing every life ends the game", () => {
  const r = firstRoom((rm) => rm.scene === "protest")
  const s = standing(r, 106)
  s.p.mode = "air"
  for (let i = 0; i < 3; i++) {
    run(s, 300, NONE)
    if (s.status !== "play") break
    s.p.x = 106; s.p.y = E.GROUND; s.p.mode = "air"
  }
  assert.strictEqual(s.status, "over")
  assert.strictEqual(s.lives, 0)
})

test("the clock runs out", () => {
  const s = E.newGame()
  s.time = 1
  run(s, 120, NONE)
  assert.strictEqual(s.status, "over")
  assert.strictEqual(s.cause, "time")
})

test("random play never breaks the state", () => {
  const keys = ["left", "right", "up", "down", "jump"]
  for (let g = 0; g < 200; g++) {
    const s = E.newGame()
    let held = input()
    for (let f = 0; f < 5000 && s.status === "play"; f++) {
      if (f % 15 === 0) { held = input(); for (const k of keys) held[k] = Math.random() < (k === "right" ? 0.6 : 0.2) }
      E.step(s, held)
      s.events.length = 0
      const p = s.p
      assert(Number.isFinite(p.x) && Number.isFinite(p.y) && Number.isFinite(s.score), "NaN")
      assert(p.x >= 0 && p.x <= E.W, "x out of bounds: " + p.x + " " + p.mode)
      assert(p.y > 0 && p.y <= E.TUNNEL + 30, "y out of bounds: " + p.y + " " + p.mode)
      assert(s.room > 0 && s.room < 256)
      assert(s.score >= 0)
      if (p.mode === "ground") assert(p.y === E.GROUND || p.y === E.TUNNEL, "standing in mid-air at " + p.y)
      if (f % 97 === 0) assert.strictEqual(JSON.stringify(JSON.parse(JSON.stringify(s))), JSON.stringify(s))
    }
  }
})

test("high scores keep the top five, sorted, and survive junk", () => {
  let list = E.sanitizeScores([{ score: "x" }, null, { score: 5 }, { score: -1 }])
  assert.strictEqual(list.length, 1)
  for (let i = 0; i < 8; i++) list = E.recordScore(list, { score: i * 100, found: i, status: "over" }, "2026-10-15").scores
  assert.strictEqual(list.length, 5)
  assert.strictEqual(list[0].score, 700)
  assert.strictEqual(E.clock(65.2), "1:06")
})

console.log(`\n${passed} passed${process.exitCode ? ", some FAILED" : ""}`)
