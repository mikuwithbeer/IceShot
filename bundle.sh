#!/usr/bin/env bash

set -e

BUNDLE_FILE="IceShot.app"
BUNDLE_CONTENTS="${BUNDLE_FILE}/Contents"
BUNDLE_EXECUTABLES="${BUNDLE_CONTENTS}/MacOS"
BUNDLE_RESOURCES="${BUNDLE_CONTENTS}/Resources"

echo "-> 1. clean old build"
rm -rf "${BUNDLE_FILE}"

echo "-> 2. create bundle structure"
mkdir -p "${BUNDLE_EXECUTABLES}"
mkdir -p "${BUNDLE_RESOURCES}"

echo "-> 3. build the worker"
cd worker
make clean
make release
cp ./output/IceShotWorker "../${BUNDLE_EXECUTABLES}/"
cd ..

echo "-> 4. build the daemon"
cd daemon
make clean
make release
cp ./output/IceShotDaemon "../${BUNDLE_EXECUTABLES}/"
cp ./assets/tray.pdf "../${BUNDLE_RESOURCES}/"
cp ./assets/icon.icns "../${BUNDLE_RESOURCES}/"
cd ..

echo "-> 5. copy information"
cat <<EOF > "${BUNDLE_CONTENTS}/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
<key>CFBundleName</key><string>IceShot</string>
<key>CFBundleExecutable</key><string>IceShotDaemon</string>
<key>CFBundleIdentifier</key><string>com.mikuwithbeer.IceShot</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>LSUIElement</key><true/>
<key>NSHighResolutionCapable</key><true/>
<key>CFBundleIconFile</key><string>icon</string>
</dict>
</plist>
EOF

echo "${BUNDLE_FILE} has been built successfully!"
