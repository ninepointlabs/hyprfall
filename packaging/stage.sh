#!/usr/bin/env bash
# Lay Hyprfall out under a staging root, the way every package installs it.
# The PKGBUILD runs this into $pkgdir; the release workflow runs it into
# packaging/stage for nfpm, so all three packages ship the same files.
#
#   packaging/stage.sh <destdir> <version>
#
#   /usr/share/hyprfall/{app,bin,VERSION}   the game and its launcher
#   /usr/bin/hyprfall                       symlink to the launcher
#   /usr/share/applications/hyprfall.desktop
#   /usr/share/icons/hicolor/256x256/apps/hyprfall.png

set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
dest="${1:?usage: stage.sh <destdir> <version>}"
version="${2:?usage: stage.sh <destdir> <version>}"
share="$dest/usr/share/hyprfall"

mkdir -p "$share" "$dest/usr/bin"
cp -r "$here/app" "$here/bin" "$share/"
echo "$version" >"$share/VERSION"
chmod 755 "$share/bin/hyprfall"
find "$share" -type d -exec chmod 755 {} +
find "$share/app" -type f -exec chmod 644 {} +
ln -sfn /usr/share/hyprfall/bin/hyprfall "$dest/usr/bin/hyprfall"

install -Dm644 "$here/packaging/hyprfall.desktop" "$dest/usr/share/applications/hyprfall.desktop"
install -Dm644 "$here/assets/icon.png" "$dest/usr/share/icons/hicolor/256x256/apps/hyprfall.png"
install -Dm644 "$here/README.md" "$dest/usr/share/doc/hyprfall/README.md"
install -Dm644 "$here/LICENSE" "$dest/usr/share/licenses/hyprfall/LICENSE"
