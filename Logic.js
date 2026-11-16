.pragma library

// Parse one cava raw-ascii frame ("12;0;57;...;") into `count` levels in [0, 1].
function parseLevels(line, count) {
  var parts = String(line || "").split(";")
  var out = []
  for (var i = 0; i < count; i++) {
    var n = parseInt(parts[i], 10)
    out.push(isFinite(n) ? Math.max(0, Math.min(100, n)) / 100 : 0)
  }
  return out
}

function clampInt(value, lo, hi, fallback) {
  var n = Math.floor(Number(value))
  return isFinite(n) ? Math.max(lo, Math.min(hi, n)) : fallback
}

function clampBars(value) { return clampInt(value, 4, 48, 10) }

// Pull named colors out of an Omarchy theme's colors.toml ("cyan = \"#449dab\"").
function themeColors(toml) {
  var out = {}
  var lines = String(toml || "").split("\n")
  for (var i = 0; i < lines.length && i < 400; i++) {
    var m = /^\s*([a-z_]+)\s*=\s*"(#[0-9a-fA-F]{6})"\s*$/.exec(lines[i])
    if (m) out[m[1]] = m[2]
  }
  return out
}

// Gradient colors, bottom (quiet) to top (loud): custom "#a,#b,#c" or theme colors.
function gradientColors(custom, theme, fallback) {
  var picked = String(custom || "").split(",").map(function (c) { return c.trim() })
    .filter(function (c) { return /^#[0-9a-fA-F]{6}$/.test(c) }).slice(0, 3)
  if (picked.length > 0) return picked
  var t = theme || {}
  var fromTheme = [t.bright_cyan || t.cyan, t.blue || t.accent, t.bright_magenta || t.magenta].filter(Boolean)
  return fromTheme.length === 3 ? fromTheme : [fallback, fallback, fallback]
}

// SVG path for a smooth filled wave through the levels (Catmull-Rom as cubic Béziers).
// width/height in px; mirrored waves grow both ways from the middle.
function wavePath(levels, width, height, mirrored) {
  var n = levels.length
  if (n < 2 || width <= 0 || height <= 0) return ""
  var mid = height / 2
  var pts = []
  for (var i = 0; i < n; i++) {
    var x = n === 1 ? width / 2 : (i / (n - 1)) * width
    var h = Math.max(0, Math.min(1, levels[i])) * (mirrored ? mid : height)
    pts.push([x, mirrored ? mid - h : height - h])
  }
  function f(v) { return Math.round(v * 100) / 100 }
  function curve(points) {
    var d = ""
    for (var i = 0; i < points.length - 1; i++) {
      var p0 = points[Math.max(0, i - 1)], p1 = points[i], p2 = points[i + 1], p3 = points[Math.min(points.length - 1, i + 2)]
      var c1 = [p1[0] + (p2[0] - p0[0]) / 6, p1[1] + (p2[1] - p0[1]) / 6]
      var c2 = [p2[0] - (p3[0] - p1[0]) / 6, p2[1] - (p3[1] - p1[1]) / 6]
      d += " C " + f(c1[0]) + " " + f(c1[1]) + " " + f(c2[0]) + " " + f(c2[1]) + " " + f(p2[0]) + " " + f(p2[1])
    }
    return d
  }
  var base = mirrored ? mid : height
  var d = "M 0 " + f(base) + " L " + f(pts[0][0]) + " " + f(pts[0][1]) + curve(pts)
  if (mirrored) {
    var lower = pts.map(function (p) { return [p[0], height - p[1]] }).reverse()
    d += " L " + f(lower[0][0]) + " " + f(lower[0][1]) + curve(lower)
  } else {
    d += " L " + f(width) + " " + f(base)
  }
  return d + " Z"
}

if (typeof module !== "undefined") {
  module.exports = { parseLevels: parseLevels, clampBars: clampBars, clampInt: clampInt,
                     themeColors: themeColors, gradientColors: gradientColors, wavePath: wavePath }
}
