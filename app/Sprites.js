.pragma library

// Hyprfall's pixel art, one string per row, one character per pixel ("." is
// transparent). Letters are colour roles, not colours: Theme.qml maps them
// to the current Omarchy theme (see palette()), so the jungle repaints itself
// when you run `omarchy theme set`. Sprites face right; QML mirrors them.

var SPRITES = {
  // ------------------------------------------------ the hero: a certain
  // Danish racing driver who also writes web frameworks and Linux distros.
  // Swept-back black hair, stubble, shades, a theme-coloured tee.
  stand: [
    "...hhhhh..",
    "..hhhhhhh.",
    ".hhhhssss.",
    ".hhhgggggg",
    ".hhssssGss",
    "..hsbbbbs.",
    "...sbbbb..",
    "....ss....",
    "..tttttt..",
    ".tttttttt.",
    ".tttttttt.",
    ".tTttttTs.",
    ".s.tttt...",
    "...jjjjj..",
    "...jjjjj..",
    "...jj.jj..",
    "...jj.jj..",
    "...jj.jj..",
    "...jJ.jJ..",
    "..www.www."
  ],
  run1: [
    "...hhhhh..",
    "..hhhhhhh.",
    ".hhhhssss.",
    ".hhhgggggg",
    ".hhssssGss",
    "..hsbbbbs.",
    "...sbbbb..",
    "....ss....",
    "..tttttt..",
    ".ttttttttt",
    "stttttt..s",
    "s.tttt....",
    "..tttt....",
    "..jjjjj...",
    ".jjjjjjj..",
    "jjj...jjj.",
    "jj.....jj.",
    "J.......jJ",
    "ww......ww",
    ".........."
  ],
  run2: [
    "...hhhhh..",
    "..hhhhhhh.",
    ".hhhhssss.",
    ".hhhgggggg",
    ".hhssssGss",
    "..hsbbbbs.",
    "...sbbbb..",
    "....ss....",
    "...tttt...",
    "..ttttts..",
    "..tttttt..",
    "..ttttts..",
    "...tttt...",
    "...jjjj...",
    "...jjjj...",
    "...jjjj...",
    "....jjj...",
    "....jjJ...",
    "....jjw...",
    "....www..."
  ],
  run3: [
    "...hhhhh..",
    "..hhhhhhh.",
    ".hhhhssss.",
    ".hhhgggggg",
    ".hhssssGss",
    "..hsbbbbs.",
    "...sbbbb..",
    "....ss....",
    "..tttttt..",
    "ttttttttt.",
    "s.ttttttts",
    "..tttt...s",
    "..tttt....",
    "...jjjjj..",
    "..jjjjjjj.",
    ".jjj..jjj.",
    ".jj....jj.",
    ".jJ.....jJ",
    ".ww.....ww",
    ".........."
  ],
  jump: [
    "...hhhhh..",
    "..hhhhhhh.",
    ".hhhhssss.",
    ".hhhgggggg",
    ".hhssssGss",
    "..hsbbbbs.",
    "s..sbbbb.s",
    "t...ss...t",
    "tttttttttt",
    "..tttttt..",
    "..tttttt..",
    "..tttttt..",
    "..jjjjjj..",
    ".jjjjjjjj.",
    ".jjj..jjj.",
    "jjJ....jjJ",
    "ww......ww",
    "..........",
    "..........",
    ".........."
  ],
  hang: [
    "..s....s..",
    "..t....t..",
    "..t....t..",
    "..thhhht..",
    "..hhhhhhh.",
    ".hhhhssss.",
    ".hhhgggggg",
    ".hhssssGss",
    "..hsbbbbs.",
    "...sbbbb..",
    "..tttttt..",
    "..tttttt..",
    "..tttttt..",
    "..tTttTt..",
    "...jjjj...",
    "...jjjj...",
    "...jj.jj..",
    "..jj...jj.",
    "..jJ...jJ.",
    "..ww...ww."
  ],
  climb1: [
    ".s.hhhhh..",
    ".t.hhhhhh.",
    ".thhhhhhh.",
    ".thhhhhhh.",
    ".thhhhhhh.",
    ".tthhhhhs.",
    "..tsssss..",
    "...tsss.t.",
    "..ttttttt.",
    ".ttttttt.s",
    ".tttttttt.",
    ".tttttttt.",
    "..tttttt..",
    "..jjjjjj..",
    "..jjjjjj..",
    "..jj..jj..",
    "..jj..jj..",
    "..jJ..jj..",
    "..ww..jJ..",
    "......ww.."
  ],
  climb2: [
    "...hhhhh.s",
    "..hhhhhh.t",
    "..hhhhhhht",
    "..hhhhhhht",
    "..hhhhhhht",
    "..shhhhhtt",
    "...sssssr.",
    ".t.ssst...",
    ".ttttttt..",
    "s.ttttttt.",
    ".tttttttt.",
    ".tttttttt.",
    "..tttttt..",
    "..jjjjjj..",
    "..jjjjjj..",
    "..jj..jj..",
    "..jj..jj..",
    "..jj..Jj..",
    "..Jj..ww..",
    "..ww......"
  ],
  dead: [
    "..........",
    "..........",
    "..........",
    "..........",
    "..........",
    "..........",
    "..........",
    "..........",
    "..........",
    "..........",
    "..........",
    "..........",
    "...hhhhh..",
    "..hhhhhhh.",
    ".hhhgggggg",
    ".hhsxsssxs",
    "..hsbbbbs.",
    "s.ttttttt.",
    "stttttttts",
    ".wjjjjjjw."
  ],

  // -------------------------------------- the anti-AI caucus of the swamp
  // A gator up to its eyes in the water. The sign is drawn by QML.
  gator: [
    "...........kkk........",
    "..........cEEPc.......",
    ".........ccEEPccc.....",
    "cccccccccccccccccccc..",
    "ccnnnnnncccccccccccccc",
    "CCCCCCCCCCCCCCCCCCCCCC",
    ".CCCCCCCCCCCCCCCCCCCC.",
    "......................"
  ],
  gatorYell: [
    "ccc...................",
    "cccc..................",
    ".cccc.....kkk.........",
    "..ccccc..cEEPc........",
    "...nnnnccccEEPcccc....",
    "........ccccccccccccc.",
    "mmmmmmmmcccccccccccccc",
    "nnnnnnnnCCCCCCCCCCCCCC",
    "CCCCCCCCCCCCCCCCCCCCC."
  ],

  // ---------------------------------------- rolling logs (journalctl -f)
  log1: [
    "..lllllllllll.",
    ".lLlllLllllrrr",
    "lllllllllllrRr",
    "lllLllllllrRrr",
    "llllllllLlrrRr",
    "lllllllllllrRr",
    ".llLlllllllrrr",
    "..lllllllllll.",
    ".............."
  ],
  log2: [
    "..lllllllllll.",
    ".lllLlllllrrr.",
    "llllllllLlrRrr",
    "lLllllllllrrRr",
    "lllllLllllrRrr",
    "lllllllllLrrRr",
    ".llllllLllrrr.",
    "..lllllllllll.",
    ".............."
  ],

  // -------------------------------------------------- the dumpster fire
  fire1: [
    "...y....o...",
    "..yoy..ooy..",
    ".yooy.yooy..",
    ".yoffyoffoy.",
    "yoffffffffoy",
    "dddddddddddd",
    "dDDDDDDDDDDd",
    "dDdDdDdDdDDd",
    "dDDDDDDDDDDd",
    "dddddddddddd",
    ".k........k."
  ],
  fire2: [
    "....o...y...",
    "...ooy.yoy..",
    "..yooy.yooy.",
    ".yoffoyoffy.",
    "yofffffffffy",
    "dddddddddddd",
    "dDDDDDDDDDDd",
    "dDdDdDdDdDDd",
    "dDDDDDDDDDDd",
    "dddddddddddd",
    ".k........k."
  ],

  // ------------------------------------------- a python (should've used Ruby)
  snake1: [
    "......BBB...",
    ".....BBkBB..",
    ".....BBBBBx.",
    ".....BB.....",
    "....BB......",
    "...BB.......",
    "..BBBBBB....",
    ".BYYYYYYBB..",
    "BYYBBBBYYYB.",
    "BYBYYYYYBYB.",
    ".BYYYYYYYB..",
    "..BBBBBBB..."
  ],
  snake2: [
    ".....BBB....",
    "....BBkBBx..",
    "....BBBBB.x.",
    ".....BB.....",
    ".....BB.....",
    "....BB......",
    "..BBBBBB....",
    ".BYYYYYYBB..",
    "BYYBBBBYYYB.",
    "BYBYYYYYBYB.",
    ".BYYYYYYYB..",
    "..BBBBBBB..."
  ],

  // ------------------------------------------------ a bug in the tunnel
  bug1: [
    "..k......k..",
    "...k....k...",
    "...RRRRRR...",
    ".kRRrRRrRRk.",
    "kRRRRkkRRRRk",
    ".RRrRkkRrRR.",
    "k.RRRRRRRR.k",
    ".k.k....k.k."
  ],
  bug2: [
    ".k........k.",
    "..k......k..",
    "...RRRRRR...",
    "kkRRrRRrRRkk",
    ".RRRRkkRRRR.",
    "kRRrRkkRrRRk",
    "..RRRRRRRR..",
    "k..k....k..k"
  ],

  // ----------------------------------------------------------- treasure
  keycap: [
    "..YYYYYYYY..",
    ".YyyyyyyyyY.",
    ".YyWyyyyyyY.",
    ".YyyyyyyyyY.",
    ".YyyykkyyyY.",
    ".YyyyyyyyyY.",
    "YYyyyyyyyyYY",
    "YYYYYYYYYYYY",
    ".YYYYYYYYYY."
  ],
  ruby: [
    "...xxxxxx...",
    "..xWxxxxXx..",
    ".xWxxxxxxXx.",
    "xxxxxxxxxxXX",
    ".XxxxxxxxxX.",
    "..XxxxxxxX..",
    "...XxxxxX...",
    "....XxxX....",
    ".....XX....."
  ],
  idol: [
    ".....yy.....",
    ".....yy.....",
    "....yyyy....",
    "....yWyy....",
    "...yyyyyy...",
    "...yyy.yyY..",
    "..yyy...yy..",
    "..yy.....yY.",
    ".yY......YY.",
    "YY........YY"
  ],
  crystal: [
    ".....aa.....",
    "....aWaA....",
    "...aWaaAA...",
    "...aaaaAA...",
    "..aaaaaaAA..",
    "..aaaaaaAA..",
    "...aaaaAA...",
    "....aaAA....",
    ".....aA....."
  ],
  sparkle: [
    "..W..",
    "..W..",
    "WWWWW",
    "..W..",
    "..W.."
  ],

  // -------------------------------------------------- the cable's plug
  plug: [
    "PPPP",
    "PQQP",
    "PQQP",
    "PPPP",
    ".PP."
  ],

  life: [
    ".hhh.",
    "hhggg",
    "hssss",
    ".ttt.",
    "ttttt",
    ".j.j."
  ]
}

// Colour roles each letter stands for. Theme.qml resolves the role names.
var ROLES = {
  h: "hair", s: "skin", S: "skinShade", b: "stubble", g: "shades", G: "glint",
  t: "shirt", T: "shirtShade", j: "jeans", J: "jeansShade", w: "shoes", r: "skin", x: "dead",
  c: "gator", C: "gatorShade", E: "eye", P: "pupil", n: "teeth", m: "mouth",
  l: "log", L: "logShade", R: "bug",
  d: "dumpster", D: "dumpsterShade", f: "fire", o: "flame", y: "gold", Y: "goldShade",
  B: "python", k: "ink", W: "shine",
  a: "crystal", A: "crystalShade", Q: "plugPins",
  // single-letter collisions resolved by sprite: logs use r/R for the end grain
  // (see LOG_ROLES), the ruby uses x/X (see RUBY_ROLES)
}

// Sprites that reuse a letter for something else.
var OVERRIDES = {
  log1: { r: "logEnd", R: "logShade" },
  log2: { r: "logEnd", R: "logShade" },
  bug1: { r: "bugSpot" },
  bug2: { r: "bugSpot" },
  ruby: { x: "ruby", X: "rubyShade" },
  snake1: { x: "tongue", Y: "pythonBelly" },
  snake2: { x: "tongue", Y: "pythonBelly" },
  plug: { P: "plug" },
  dead: { x: "ink" },
  climb2: { r: "skin" }
}

function roleOf(sprite, letter) {
  var o = OVERRIDES[sprite]
  if (o && o[letter]) return o[letter]
  return ROLES[letter]
}
