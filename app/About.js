.pragma library

// The About screen's facts (F1 in game, `hyprfall --about` in a terminal).
// The version comes from the VERSION file that --version reads and the
// license text from LICENSE, both next to app/; these are the facts that
// live nowhere else. bin/hyprfall reads the ABOUT lines below with sed, so
// keep each one a single line of `  key: "text",` with no double quotes or
// backslashes inside. test/about.js checks both.

var ABOUT = {
  name: "Hyprfall",
  tagline: "A jungle caper for Omarchy",
  organization: "Nine Point Labs",
  created: "October 2026", // first commit: 2026-10-15
  license: "MIT License",
  copyright: "© 2026 Nine Point Labs", // as written in LICENSE
  supportEmail: "help@ninepointlabs.com",
  privacy: "No accounts, no telemetry, no network access: the game never connects to the internet, not even to hyprfall.ninepointlabs.com. High scores (score, treasures, date) and the mute switch are saved in ~/.local/state/hyprfall/save.json ($XDG_STATE_HOME/hyprfall), with your usual file permissions (0644 under umask 022). It reads your Omarchy theme's colors.toml, plays only its own sounds and never uses a microphone. It takes a screenshot only when a script asks over quickshell ipc, and only to a .png under ~/.cache. The one web address in it, quickshell.org, is printed by the launcher when Quickshell is missing.",
  credits: "The jungle, sprites, code and music are all original; the music and sound effects are synthesised by tools/make-sounds.py, and text uses your system monospace font. An affectionate parody, not affiliated with or endorsed by Activision, Omarchy's creator or 37signals."
}

// Highest minor version `has(major, minor)` accepts, as "major.minor"
// (Quickshell.hasVersion / hasQtVersion only answer yes or no), or "".
function probedVersion(has, major) {
  if (typeof has !== "function" || !has(major, 0)) return ""
  var minor = 0
  while (minor < 99 && has(major, minor + 1)) minor++
  return major + "." + minor
}

// "0.1.0" from the VERSION file's text, or "dev" like `hyprfall --version`.
function version(text) {
  var v = String(text || "").trim()
  return /^[0-9A-Za-z.+~-]{1,32}$/.test(v) ? v : "dev"
}

// One paragraph per line, so the license wraps to the card's width.
function reflowLicense(text) {
  var paragraphs = String(text || "").split(/\n\s*\n/)
  var out = []
  for (var i = 0; i < paragraphs.length; i++) {
    var p = paragraphs[i].replace(/\s+/g, " ").trim()
    if (p !== "") out.push(p)
  }
  return out.join("\n\n")
}

function builtWith(quickshell, qt) {
  return "Quickshell " + (quickshell || "?") + ", Qt " + (qt || "?")
}

// Version details for a support email.
function details(version, quickshell, qt, desktop) {
  return ABOUT.name + " " + version + "\n" + builtWith(quickshell, qt) + "\n" + (desktop || "unknown desktop")
}

function supportMailto(version, details) {
  return "mailto:" + ABOUT.supportEmail + "?subject=" + encodeURIComponent(ABOUT.name + " " + version)
    + "&body=" + encodeURIComponent("\n\n--\n" + details)
}
