// Hyprfall's site: the banner and card sprites are the real game art
// (sprites.js is app/Sprites.js, copied in by the Pages workflow), coloured
// the same way the game's Theme.qml colours them from an Omarchy theme.
"use strict"

const THEMES = {"tokyo-night":{"name":"Tokyo Night","background":"#1a1b26","dark_background":"#13141c","darker_background":"#0e0e14","foreground":"#a9b1d6","accent":"#7aa2f7","red":"#f7768e","green":"#9ece6a","yellow":"#e0af68","blue":"#7aa2f7","magenta":"#ad8ee6","cyan":"#449dab"},"catppuccin":{"name":"Catppuccin","background":"#1e1e2e","dark_background":"#161622","darker_background":"#101019","foreground":"#cdd6f4","accent":"#89b4fa","red":"#f38ba8","green":"#a6e3a1","yellow":"#f9e2af","blue":"#89b4fa","magenta":"#f5c2e7","cyan":"#94e2d5"},"gruvbox":{"name":"Gruvbox","background":"#282828","dark_background":"#1e1e1e","darker_background":"#161616","foreground":"#d4be98","accent":"#7daea3","red":"#ea6962","green":"#a9b665","yellow":"#d8a657","blue":"#7daea3","magenta":"#d3869b","cyan":"#89b482"},"rose-pine":{"name":"Rosé Pine","background":"#faf4ed","dark_background":"#ede7e1","darker_background":"#e1dbd5","foreground":"#575279","accent":"#56949f","red":"#b4637a","green":"#286983","yellow":"#ea9d34","blue":"#56949f","magenta":"#907aa9","cyan":"#d7827e"},"everforest":{"name":"Everforest","background":"#2d353b","dark_background":"#21272c","darker_background":"#181d20","foreground":"#d3c6aa","accent":"#7fbbb3","red":"#e67e80","green":"#a7c080","yellow":"#dbbc7f","blue":"#7fbbb3","magenta":"#d699b6","cyan":"#83c092"},"kanagawa":{"name":"Kanagawa","background":"#1f1f28","dark_background":"#17171e","darker_background":"#111116","foreground":"#dcd7ba","accent":"#dcd7ba","red":"#c34043","green":"#76946a","yellow":"#c0a36e","blue":"#7e9cd8","magenta":"#957fb8","cyan":"#6a9589"},"retro-82":{"name":"Retro 82","background":"#05182e","dark_background":"#031222","darker_background":"#020c17","foreground":"#f6dcac","accent":"#faa968","red":"#f85525","green":"#028391","yellow":"#e97b3c","blue":"#3f8f8a","magenta":"#3f8f8a","cyan":"#8cbfb8"},"flexoki-light":{"name":"Flexoki Light","background":"#FFFCF0","dark_background":"#f2efe4","darker_background":"#e5e2d8","foreground":"#100F0F","accent":"#205EA6","red":"#D14D41","green":"#879A39","yellow":"#D0A215","blue":"#205EA6","magenta":"#CE5D97","cyan":"#3AA99F"}}

// ------------------------------------------------------------ colours --
// Qt.darker/Qt.lighter/Qt.tint, near enough: HSV value scaled by a factor.
function rgb(hex) {
  const n = parseInt(hex.slice(1, 7), 16)
  return [(n >> 16) & 255, (n >> 8) & 255, n & 255]
}
function hex(c) { return "#" + c.map(v => Math.max(0, Math.min(255, Math.round(v))).toString(16).padStart(2, "0")).join("") }
function scaleValue(h, f) {
  const [r, g, b] = rgb(h)
  const max = Math.max(r, g, b)
  if (!max) return h
  const target = Math.min(255, max * f)
  const k = target / max
  // past white, push the other channels up instead of clipping the hue
  return hex([r, g, b].map(v => v * k + (max * f > 255 ? (max * f - 255) * (1 - v / max) : 0)))
}
const darker = (h, f) => scaleValue(h, 1 / f)
const lighter = (h, f) => scaleValue(h, f)
function tint(base, over, a) {
  const b = rgb(base), o = rgb(over)
  return hex(b.map((v, i) => v + (o[i] - v) * a))
}

function palette(t) {
  const c = (k, n) => t[k] || t[n]
  const green = c("green", "color2"), red = c("red", "color1"), yellow = c("yellow", "color3")
  const blue = c("blue", "color4"), cyan = c("cyan", "color6"), accent = t.accent
  const bg = t.background
  return {
    hud: t.darker_background, fg: t.foreground, accent, bg,
    backdrop: tint(bg, green, 0.3), canopy: green, canopyShade: darker(green, 1.7),
    trunk: "#5a3a22", trunkShade: "#3e2716", grass: lighter(yellow, 1.1), ground: darker(yellow, 1.2),
    dirt: darker(yellow, 2.2), garden: darker(yellow, 3.2), gardenShine: darker(green, 1.2),
    cable: blue, sign: "#f2ead3", signInk: darker(red, 1.3),
    roles: {
      hair: "#5e3d26", hairShine: "#94653f", skin: "#e8b896", beard: "#4a3020",
      tee: "#17171c", teeLogo: accent, jeans: "#4d6d9a", jeansShade: "#34507a", shoes: "#ececec", dead: "#101014",
      gnomeHat: red, gnomeHatShade: darker(red, 1.5), gnomeSkin: "#f2c4a4", gnomeNose: "#e0866a",
      gnomeCoat: blue, gnomeCoatShade: darker(blue, 1.6), mouth: darker(red, 1.9),
      log: "#8b5a2b", logShade: "#5f3b1a", logEnd: "#c9955c", bug: red, bugSpot: yellow,
      dumpster: "#4b6354", dumpsterShade: "#33443a", fire: red, flame: "#ff8c1a",
      gold: yellow, goldShade: darker(yellow, 1.6), python: blue, pythonBelly: yellow, tongue: red,
      ink: "#101014", shine: "#ffffff", crystal: cyan, crystalShade: darker(cyan, 1.7),
      ruby: red, rubyShade: darker(red, 1.8), plug: "#d6dde0", plugPins: yellow
    }
  }
}

let theme = "tokyo-night"
let pal = palette(THEMES[theme])

// -------------------------------------------------------------- sprites --
function drawSprite(ctx, name, x, y, s, flip) {
  const rows = SPRITES[name]
  if (!rows) return
  const w = rows[0].length
  for (let r = 0; r < rows.length; r++) {
    const row = rows[r]
    for (let i = 0; i < w; i++) {
      const ch = row[i]
      if (ch === ".") continue
      ctx.fillStyle = pal.roles[roleOf(name, ch)] || "#ff00ff"
      const dx = flip ? w - 1 - i : i
      ctx.fillRect(Math.round((x + dx) * s), Math.round((y + r) * s), Math.ceil(s), Math.ceil(s))
    }
  }
}

function paintCards() {
  for (const cv of document.querySelectorAll("canvas.sprite")) {
    const name = cv.dataset.sprite, s = Number(cv.dataset.scale || 4)
    const rows = SPRITES[name]
    if (!rows) continue
    cv.width = rows[0].length * s
    cv.height = rows.length * s
    const ctx = cv.getContext("2d")
    ctx.clearRect(0, 0, cv.width, cv.height)
    drawSprite(ctx, name, 0, 0, s, name === "fire1" || name === "snake1")
  }
}

// --------------------------------------------------------------- banner --
// A 320x112 slice of jungle: the hero runs in, hops across three gnome hats,
// grabs a crystal, and the gnomes yell after him.
const W = 320, H = 112, GROUND = 84, S = 4
const PIT = [122, 206], GNOMES = [136, 164, 192]
const SIGNS = ["NO AI", "RTFM", "AI = SLOP"]
const LOOP = 9

const canvas = document.getElementById("banner")
const ctx = canvas.getContext("2d")
let scenery = null

function paintScenery() {
  const off = document.createElement("canvas")
  off.width = W * S
  off.height = H * S
  const c = off.getContext("2d")
  const rect = (col, x, y, w, h) => { c.fillStyle = col; c.fillRect(Math.floor(x * S), Math.floor(y * S), Math.ceil(w * S), Math.ceil(h * S)) }
  let seed = 101
  const rnd = n => { seed = (seed * 73 + 41) % 251; return seed % n }

  for (let band = 0; band < 5; band++) rect(darker(pal.backdrop, 1 + band * 0.07), 0, band * 17, W, 17)
  for (let x = 6; x < W; x += 24 + rnd(12)) rect(darker(pal.backdrop, 1.35), x, 20, 3, GROUND - 20)
  for (const tx of [30, 96, 232, 290]) {
    rect(pal.trunkShade, tx - 1, 18, 9, GROUND - 18)
    rect(pal.trunk, tx, 18, 6, GROUND - 18)
    rect(lighter(pal.trunk, 1.25), tx + 1, 18, 1, GROUND - 18)
    rect(pal.trunk, tx - 3, GROUND - 3, 12, 3)
  }
  const blob = (col, cx, cy, r) => { for (let dy = -r; dy <= r; dy++) { const w = Math.floor(Math.sqrt(r * r - dy * dy) + 0.3); rect(col, cx - w, cy + dy, 2 * w + 1, 1) } }
  rect(pal.canopyShade, 0, 0, W, 14)
  const clumps = []
  for (let x = -6; x < W + 12; x += 11 + rnd(7)) clumps.push([x, 10 + rnd(8), 8 + rnd(5)])
  for (const [x, y, r] of clumps) blob(pal.canopyShade, x + 1, y + 3, r)
  for (const [x, y, r] of clumps) blob(pal.canopy, x, y, r)
  const light = lighter(pal.canopy, 1.22)
  for (const [x, y, r] of clumps) {
    blob(light, x - 3, y - r / 2, 2)
    if (rnd(3) === 0) { const len = 6 + rnd(14); rect(pal.canopyShade, x + 3, y + r, 1, len); rect(pal.canopy, x + 2, y + r + len - 2, 3, 2) }
  }
  rect(pal.grass, 0, GROUND, W, 2)
  for (let gx = 2; gx < W; gx += 7 + rnd(9)) rect(pal.canopy, gx, GROUND - 2, 1 + rnd(2), 2)
  rect(pal.ground, 0, GROUND + 2, W, 10)
  rect(pal.dirt, 0, GROUND + 12, W, H - GROUND - 12)
  for (let dx = 0; dx < W; dx += 16) rect(darker(pal.dirt, 1.3), dx + (dx / 16 % 2) * 7, GROUND + 15, 4, 2)
  // the gnome pit
  rect(pal.garden, PIT[0], GROUND + 1, PIT[1] - PIT[0], 19)
  rect(pal.gardenShine, PIT[0] + 4, GROUND + 3, PIT[1] - PIT[0] - 8, 1)
  scenery = off
}

function heroAt(t) {
  // [x, y (feet), sprite, airborne]
  const hop = (x0, x1, t0, u) => [x0 + (x1 - x0) * u, GROUND - 22 * Math.sin(Math.PI * u), "jump"]
  if (t < 2.6) return [-14 + t * 48, GROUND, ["run1", "run2", "run3", "run2"][Math.floor(t * 10) % 4]]
  const hops = [[110.8, GNOMES[0], 2.6], [GNOMES[0], GNOMES[1], 3.15], [GNOMES[1], GNOMES[2], 3.7], [GNOMES[2], 222, 4.25]]
  for (const [a, b, t0] of hops) {
    if (t < t0 + 0.45) return hop(a, b, t0, Math.max(0, (t - t0) / 0.45))
    if (t < t0 + 0.55) return [b, GROUND, "stand"]
  }
  const x = 222 + (t - 4.8) * 48
  return [x, GROUND, ["run1", "run2", "run3", "run2"][Math.floor(t * 10) % 4]]
}

function frame(ms) {
  const t = (ms / 1000) % LOOP
  if (!scenery) paintScenery()
  ctx.drawImage(scenery, 0, 0)
  const yelling = t > 5.2 && t < 8.2

  GNOMES.forEach((gx, i) => {
    const bob = yelling ? Math.round(Math.sin(t * 18 + i) * 1.5) : 0
    const lift = yelling ? 4 : 0
    // stick and sign
    ctx.fillStyle = pal.trunk
    ctx.fillRect((gx + 8) * S, (GROUND - 18 + bob - lift) * S, S, (20 + lift) * S)
    ctx.save()
    ctx.translate((gx + 8.5) * S, (GROUND - 23.5 + bob - lift) * S)
    if (yelling) ctx.rotate(Math.sin(t * 14 + i) * 0.14)
    ctx.fillStyle = pal.sign
    ctx.fillRect(-12 * S, -6 * S, 24 * S, 12 * S)
    ctx.strokeStyle = pal.trunkShade
    ctx.lineWidth = 2
    ctx.strokeRect(-12 * S, -6 * S, 24 * S, 12 * S)
    ctx.fillStyle = pal.signInk
    ctx.font = `bold ${3.4 * S}px "JetBrains Mono", monospace`
    ctx.textAlign = "center"
    ctx.textBaseline = "middle"
    ctx.fillText(SIGNS[i], 0, S * 0.5)
    ctx.restore()
    drawSprite(ctx, yelling ? "gnomeYell" : "gnome", gx - 6, GROUND + bob, S)
    if (yelling) {
      ctx.font = `${5 * S}px "Press Start 2P", monospace`
      ctx.fillStyle = pal.roles.gnomeHat
      ctx.textAlign = "center"
      ctx.fillText(["NO!", "BOO!", "SLOP!"][i], (gx - 14) * S, (GROUND - 12 - bob) * S)
    }
  })

  // the crystal, until he grabs it
  const crystalX = 262
  if (t < 6.6) drawSprite(ctx, "crystal", crystalX - 6, GROUND - 9 + Math.round(Math.sin(t * 3)), S)
  else if (t < 7.2) drawSprite(ctx, "sparkle", crystalX - 2, GROUND - 16, S)

  const [hx, hy, sprite] = heroAt(t)
  drawSprite(ctx, sprite, Math.round(hx - 6), Math.round(hy - 22), S)

  if (t > 6.6 && t < 8.2) {
    ctx.font = `${5 * S}px "Press Start 2P", monospace`
    ctx.fillStyle = pal.fg
    ctx.strokeStyle = pal.hud
    ctx.lineWidth = 6
    ctx.textAlign = "center"
    ctx.strokeText("+5000", 262 * S, 50 * S)
    ctx.fillText("+5000", 262 * S, 50 * S)
  }
  if (!reduced) requestAnimationFrame(frame)
}

const reduced = window.matchMedia("(prefers-reduced-motion: reduce)").matches

// -------------------------------------------------------- theme picking --
function setTheme(slug) {
  theme = slug
  pal = palette(THEMES[slug])
  scenery = null
  document.documentElement.style.setProperty("--accent", THEMES[slug].accent)
  document.documentElement.style.setProperty("--game-bg", THEMES[slug].darker_background)
  for (const b of document.querySelectorAll(".swatches button")) b.setAttribute("aria-pressed", String(b.dataset.theme === slug))
  const shot = document.getElementById("theme-shot")
  shot.src = `img/theme-${slug}.webp`
  shot.alt = `The same jungle screen in the ${THEMES[slug].name} theme`
  document.getElementById("theme-caption").textContent = THEMES[slug].name
  paintCards()
  if (reduced) frame(6000)
}

for (const id of ["swatches", "swatches-2"]) {
  const holder = document.getElementById(id)
  holder.textContent = ""
  for (const [slug, t] of Object.entries(THEMES)) {
    const b = document.createElement("button")
    b.type = "button"
    b.dataset.theme = slug
    b.innerHTML = `<span class="chips"><i style="background:${t.background}"></i><i style="background:${t.green}"></i><i style="background:${t.red}"></i><i style="background:${t.accent}"></i></span>${t.name}`
    b.addEventListener("click", () => setTheme(slug))
    holder.appendChild(b)
  }
}

// ------------------------------------------------------------- releases --
// Point the download links at the latest release's actual files.
fetch("https://api.github.com/repos/ninepointlabs/hyprfall/releases/latest")
  .then(r => r.ok ? r.json() : Promise.reject(r.status))
  .then(rel => {
    document.getElementById("release-link").textContent = `Release ${rel.tag_name}`
    document.getElementById("version-note").textContent = `Latest: ${rel.tag_name}.`
    for (const a of document.querySelectorAll("a.asset")) {
      const asset = rel.assets.find(x => x.name.endsWith(a.dataset.match))
      if (!asset) continue
      a.href = asset.browser_download_url
      a.textContent = `Download ${asset.name}`
      const code = a.closest(".install").querySelector("code[data-cmd]")
      if (code) code.textContent = code.textContent.replace(/hyprfall[-_]\*[^ ]*/, "./" + asset.name).replace("././", "./")
    }
  })
  .catch(() => {})

// copy buttons on every command, outside the scrolling <pre>
for (const pre of document.querySelectorAll("pre")) {
  const box = document.createElement("div")
  box.className = "codebox"
  pre.replaceWith(box)
  box.appendChild(pre)
  const b = document.createElement("button")
  b.className = "copy"
  b.type = "button"
  b.textContent = "Copy"
  b.addEventListener("click", () => {
    navigator.clipboard.writeText(pre.querySelector("code").textContent).then(() => {
      b.textContent = "Copied"
      setTimeout(() => (b.textContent = "Copy"), 1400)
    })
  })
  box.appendChild(b)
}

setTheme(theme)
document.fonts.ready.then(() => requestAnimationFrame(frame))
