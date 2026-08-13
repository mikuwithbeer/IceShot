#!/usr/bin/env bash

set -euo pipefail

info() {
    echo -e "\033[1;32m==> $1\033[0m"
}

error() {
    echo -e "\033[1;31m==> error: $1\033[0m"
}

BUNDLE_MODE="${1:-release}"
BUNDLE_FILE="IceShot.app"

if [[ "$BUNDLE_MODE" != "release" && "$BUNDLE_MODE" != "debug" ]]; then
    error "invalid build mode '${BUNDLE_MODE}'!"
    exit 1
fi

BUNDLE_CONTENTS="${BUNDLE_FILE}/Contents"
BUNDLE_EXECUTABLES="${BUNDLE_CONTENTS}/MacOS"
BUNDLE_RESOURCES="${BUNDLE_CONTENTS}/Resources"

info "1. clean old build"
rm -rf "${BUNDLE_FILE}"

info "2. create bundle structure"
mkdir -p "${BUNDLE_EXECUTABLES}" "${BUNDLE_RESOURCES}"

info "3. build the worker:${BUNDLE_MODE}"
make -C worker clean "${BUNDLE_MODE}"
cp worker/output/IceShotWorker "${BUNDLE_EXECUTABLES}/"

info "4. build the daemon:${BUNDLE_MODE}"
make -C daemon clean "${BUNDLE_MODE}"
cp daemon/output/IceShotDaemon "${BUNDLE_EXECUTABLES}/"
cp daemon/assets/tray.pdf "${BUNDLE_RESOURCES}/"
cp daemon/assets/icon.icns "${BUNDLE_RESOURCES}/"

info "5. write bundle information"
cp LICENSE "${BUNDLE_RESOURCES}/"
cp README.md "${BUNDLE_RESOURCES}/"
cat <<EOF > "${BUNDLE_CONTENTS}/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>IceShot</string>
    <key>CFBundleExecutable</key>
    <string>IceShotDaemon</string>
    <key>CFBundleIdentifier</key>
    <string>com.mikuwithbeer.IceShot</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleIconFile</key>
    <string>icon</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>

    <key>CFBundleShortVersionString</key>
    <string>2026.08.13</string>
    <key>CFBundleVersion</key>
    <string>2026081300</string>

    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSSupportsAutomaticGraphicsSwitching</key>
    <true/>

    <key>NSHumanReadableCopyright</key>
    <string>Copyright © 2026 mikuwithbeer. Licensed under the BSD-2-Clause Plus Patent License.</string>
</dict>
</plist>
EOF

info "6. sign the application"
codesign --force --deep --sign - "${BUNDLE_FILE}"

info "${BUNDLE_FILE} (${BUNDLE_MODE}) has been built successfully!"
