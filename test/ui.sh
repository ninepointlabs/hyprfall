#!/bin/bash
# Headless end-to-end UI test: real key events, no compositor, throwaway state.
set -euo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
rm -rf /tmp/hyprfall-stub-state
mkdir -p /tmp/hyprfall-stub-state/hyprfall
QML_IMPORT_PATH="$here/../tools/stub" QML_XHR_ALLOW_FILE_READ=1 QML_XHR_ALLOW_FILE_WRITE=1 \
  QT_QPA_PLATFORM=offscreen QT_FORCE_STDERR_LOGGING=1 \
  exec /usr/lib/qt6/bin/qmltestrunner -input "$here/tst_ui.qml" "$@"
