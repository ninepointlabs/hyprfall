#!/usr/bin/env node
// Launcher tests: bin/hyprfall refuses a Quickshell older than 0.3 with a
// clear message, and carries on with 0.3+ or a version it can't read.
// A stub `quickshell` on PATH stands in for the real one.
// Run: node test/launcher.js
"use strict"

const fs = require("fs")
const os = require("os")
const path = require("path")
const assert = require("assert")
const { spawnSync } = require("child_process")

const root = path.join(__dirname, "..")

let passed = 0
function test(name, fn) {
  try { fn(); passed++; console.log("ok   " + name) } catch (e) { console.error("FAIL " + name + "\n     " + e.message); process.exitCode = 1 }
}

// run `hyprfall --selftest` against a stub quickshell that reports `versionLine`
// and, when asked to run the game, prints the selftest's success line
function selftest(versionLine) {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), "hyprfall-launcher-"))
  try {
    fs.writeFileSync(path.join(dir, "quickshell"),
      "#!/bin/sh\nif [ \"$1\" = --version ]; then printf '%s\\n' " + JSON.stringify(versionLine) + "; exit 0; fi\n" +
      "echo 'hyprfall: selftest ok (stub)'\n", { mode: 0o755 })
    fs.writeFileSync(path.join(dir, "notify-send"), "#!/bin/sh\nexit 0\n", { mode: 0o755 })
    return spawnSync(path.join(root, "bin", "hyprfall"), ["--selftest"], {
      encoding: "utf8",
      env: { ...process.env, PATH: dir + ":" + process.env.PATH },
    })
  } finally {
    fs.rmSync(dir, { recursive: true, force: true })
  }
}

test("Quickshell 0.2.1 is refused with a clear message", () => {
  const r = selftest("Quickshell 0.2.1 (revision abc, distributed by Fedora)")
  assert.strictEqual(r.status, 1)
  assert(r.stderr.includes("Hyprfall needs Quickshell 0.3 or newer (found 0.2.1)."), r.stderr)
})

test("Quickshell 0.3.0 and 1.0 are accepted", () => {
  for (const v of ["Quickshell 0.3.0", "Quickshell 0.3.2 (revision 2b4501a, distributed by Omarchy)", "Quickshell 1.0.0"]) {
    const r = selftest(v)
    assert.strictEqual(r.status, 0, v + ": " + r.stderr)
    assert(r.stdout.includes("selftest ok"), v)
  }
})

test("an unreadable version is not held against it", () => {
  const r = selftest("quickshell, a QtQuick shell toolkit")
  assert.strictEqual(r.status, 0, r.stderr)
})

console.log(passed + " passed")
