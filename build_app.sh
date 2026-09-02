#!/bin/bash
set -e

echo "🔨 正在编译 Next5h 原生二进制..."
swift build -c release

APP_NAME="Next5h"
BUNDLE_DIR="$PWD/${APP_NAME}.app"
CONTENTS_DIR="${BUNDLE_DIR}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"

echo "📦 正在打包 ${APP_NAME}.app..."
rm -rf "${BUNDLE_DIR}"
mkdir -p "${MACOS_DIR}" "${RESOURCES_DIR}"

cp ".build/release/${APP_NAME}" "${MACOS_DIR}/${APP_NAME}"
chmod +x "${MACOS_DIR}/${APP_NAME}"

if [ -f "assets/AppIcon.icns" ]; then
    cp "assets/AppIcon.icns" "${RESOURCES_DIR}/AppIcon.icns"
fi

cat << 'PLIST' > "${CONTENTS_DIR}/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>Next5h</string>
    <key>CFBundleIdentifier</key>
    <string>com.anti.next5h</string>
    <key>CFBundleName</key>
    <string>Next5h</string>
    <key>CFBundleDisplayName</key>
    <string>Next5h</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>LSApplicationCategoryType</key>
    <string>public.app-category.developer-tools</string>
</dict>
</plist>
PLIST

echo "✅ 打包完成: ${BUNDLE_DIR}"

if [ -d "/Applications/${APP_NAME}.app" ]; then
    echo "🔄 正在同步更新 /Applications/${APP_NAME}.app..."
    rm -rf "/Applications/${APP_NAME}.app"
    cp -R "${BUNDLE_DIR}" "/Applications/${APP_NAME}.app"
    touch "/Applications/${APP_NAME}.app"
    /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "/Applications/${APP_NAME}.app" 2>/dev/null || true
    echo "✨ /Applications/${APP_NAME}.app 同步完成并已刷新图标缓存"
fi
