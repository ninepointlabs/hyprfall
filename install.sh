#!/bin/bash
# Install Hyprfall for the current user.
#
#   ./install.sh               install (or update) the game
#   ./install.sh --uninstall   remove it, keep your high scores
#   ./install.sh --purge       remove it and the save too
#
# Everything lands in your home directory; nothing runs as root:
#
#   ~/.local/share/hyprfall/                      the game
#   ~/.local/bin/hyprfall                         launcher symlink
#   ~/.local/share/applications/hyprfall.desktop  app launcher entry
#   ~/.local/share/icons/hicolor/256x256/apps/hyprfall.png
#
# Saves live in ~/.local/state/hyprfall/ and survive reinstalls.

set -euo pipefail

src="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
data="${XDG_DATA_HOME:-$HOME/.local/share}"
state="${XDG_STATE_HOME:-$HOME/.local/state}"
dest="$data/hyprfall"
bin="$HOME/.local/bin/hyprfall"
desktop="$data/applications/hyprfall.desktop"
icon="$data/icons/hicolor/256x256/apps/hyprfall.png"
marker="X-Hyprfall-Install=1"

die() { echo "install.sh: $*" >&2; exit 1; }

# Only ever delete things we put there.
ours_dir() { [[ -d $1 && ! -L $1 && -f $1/app/shell.qml && -f $1/.hyprfall ]]; }
ours_link() { [[ -L $1 && $(readlink -- "$1") == "$dest/bin/hyprfall" ]]; }
ours_desktop() { [[ -f $1 && ! -L $1 ]] && grep -qxF "$marker" -- "$1"; }

stop_game() {
  if command -v quickshell >/dev/null 2>&1 && [[ -d $dest/app ]]; then
    quickshell kill --path "$dest/app" >/dev/null 2>&1 || true
  fi
}

remove() {
  stop_game
  if [[ -e $dest || -L $dest ]]; then
    ours_dir "$dest" && rm -rf -- "$dest" || echo "install.sh: $dest isn't ours; leaving it alone" >&2
  fi
  if [[ -e $bin || -L $bin ]]; then
    ours_link "$bin" && rm -f -- "$bin" || echo "install.sh: $bin isn't ours; leaving it alone" >&2
  fi
  if [[ -e $desktop ]]; then
    ours_desktop "$desktop" && rm -f -- "$desktop" || echo "install.sh: $desktop isn't ours; leaving it alone" >&2
  fi
  [[ -f $icon && ! -L $icon ]] && rm -f -- "$icon"
  return 0
}

case "${1:-}" in
  --uninstall)
    remove
    echo "Hyprfall is gone. Your high scores are still in $state/hyprfall."
    exit 0
    ;;
  --purge)
    remove
    [[ -d $state/hyprfall && ! -L $state/hyprfall ]] && rm -rf -- "$state/hyprfall"
    echo "Hyprfall is gone, high scores and all. The jungle grows back over everything."
    exit 0
    ;;
  "") ;;
  *) die "unknown option '$1' (use --uninstall or --purge)" ;;
esac

# ------------------------------------------------------------ dependencies
#
# Omarchy has everything already. Elsewhere, name the right package for the
# distro instead of a generic "install Qt".
distro="$( . /etc/os-release 2>/dev/null; echo "${ID:-} ${ID_LIKE:-}")"
hint() {
  # hint <arch> <fedora> <debian> <nix>
  case " $distro " in
    *" arch "*) echo "$1" ;;
    *" fedora "* | *" rhel "*) echo "$2" ;;
    *" debian "* | *" ubuntu "*) echo "$3" ;;
    *" nixos "*) echo "$4" ;;
    *) echo "$1 (Arch) / $2 (Fedora) / $3 (Debian, Ubuntu) / $4 (Nix)" ;;
  esac
}

if ! command -v quickshell >/dev/null 2>&1; then
  die "Quickshell is not installed. It ships with Omarchy; elsewhere: $(hint "pacman -S quickshell" "dnf copr enable errornointernet/quickshell && dnf install quickshell" "build it from https://quickshell.org" "nix profile install nixpkgs#quickshell")"
fi

# Sound is optional (the game runs silent without it), but worth a nudge.
qml_dirs=(/usr/lib/qt6/qml /usr/lib64/qt6/qml /usr/lib/*-linux-gnu/qt6/qml)
IFS=: read -r -a extra_dirs <<<"${QML_IMPORT_PATH:-}:${QML2_IMPORT_PATH:-}:${NIXPKGS_QT6_QML_IMPORT_PATH:-}"
qml_dirs+=("${extra_dirs[@]}")
found_qml=0 have_multimedia=0
for d in "${qml_dirs[@]}"; do
  [[ -n $d && -d $d ]] || continue
  found_qml=1
  [[ -f $d/QtMultimedia/qmldir ]] && have_multimedia=1
done
if ((found_qml && !have_multimedia)); then
  echo "install.sh: Qt 6 multimedia isn't installed, so the jungle will be silent." >&2
  echo "            For sound: $(hint "pacman -S qt6-multimedia" "dnf install qt6-qtmultimedia" "apt install qml6-module-qtmultimedia" "add qt6.qtmultimedia")" >&2
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "install.sh: jq isn't installed; the launcher can't float or focus the window on Hyprland (the game still runs)." >&2
  echo "            $(hint "pacman -S jq" "dnf install jq" "apt install jq" "add jq")" >&2
fi

if [[ -e $dest || -L $dest ]] && ! ours_dir "$dest"; then
  die "$dest exists and isn't a Hyprfall install; move it out of the way first"
fi
if [[ -e $bin || -L $bin ]] && ! ours_link "$bin"; then
  die "$bin exists and isn't our launcher; move it out of the way first"
fi
if [[ -e $desktop ]] && ! ours_desktop "$desktop"; then
  die "$desktop exists and wasn't written by this installer"
fi

stop_game

# Stage next to the destination and swap it in, so a half-copied game never
# exists under the real name.
mkdir -p "$data" "$HOME/.local/bin" "$(dirname "$desktop")" "$(dirname "$icon")"
stage="$(mktemp -d "$data/.hyprfall.XXXXXX")"
trap 'rm -rf -- "$stage"' EXIT
cp -r "$src/app" "$src/bin" "$stage/"
cp "$src/LICENSE" "$src/README.md" "$stage/" 2>/dev/null || true
touch "$stage/.hyprfall"
chmod 755 "$stage" "$stage/bin/hyprfall"
if [[ -d $dest ]]; then rm -rf -- "$dest"; fi
mv -T -- "$stage" "$dest"
trap - EXIT

ln -sfn -- "$dest/bin/hyprfall" "$bin"
cp "$src/assets/icon.png" "$icon"

tmp="$(mktemp "$(dirname "$desktop")/.hyprfall.XXXXXX")"
cat >"$tmp" <<DESKTOP
[Desktop Entry]
Type=Application
Version=1.0
Name=Hyprfall
GenericName=Jungle platformer
Comment=Swing on ethernet cables over tarballs and angry anti-AI gators. Find 32 treasures in 20 minutes.
Exec=$dest/bin/hyprfall
Icon=hyprfall
Terminal=false
Categories=Game;
Keywords=jungle;platformer;atari;retro;game;omarchy;
StartupNotify=false
$marker
DESKTOP
chmod 644 "$tmp"
mv -T -- "$tmp" "$desktop"

command -v gtk-update-icon-cache >/dev/null 2>&1 && gtk-update-icon-cache -q -t "$data/icons/hicolor" >/dev/null 2>&1 || true

echo "Installed Hyprfall to $dest"
case ":$PATH:" in *":$HOME/.local/bin:"*) ;; *) echo "Note: ~/.local/bin isn't on your PATH; launch it from the app menu or run $bin" ;; esac
echo "Play: hyprfall   ·   or find \"Hyprfall\" in your app launcher (Super + Space)"
