#!/bin/bash
# Build the GitHub Pages site into _site/ (what .github/workflows/site.yml
# publishes), and with --serve, preview it at http://localhost:8642.
#
# The site draws the real game sprites: app/Sprites.js is copied in as
# sprites.js, minus the QML-only `.pragma library` line.
set -euo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
out="$here/_site"
rm -rf "$out"
cp -r "$here/site" "$out"
sed '/^\.pragma library/d' "$here/app/Sprites.js" >"$out/sprites.js"
echo "built $out"
if [[ ${1:-} == "--serve" ]]; then
  cd "$out" && exec python3 -m http.server 8642 --bind 127.0.0.1
fi
