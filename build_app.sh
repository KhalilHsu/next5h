#!/bin/bash
set -e

# UNIVERSAL=1 构建 arm64 + x86_64 通用二进制（用于发布）；SKIP_INSTALL=1 不同步到 /Applications。
SWIFT_BUILD_ARGS=(-c release)
if [ "${UNIVERSAL:-0}" = "1" ]; then
    SWIFT_BUILD_ARGS+=(--arch arm64 --arch x86_64)
fi

echo "🔨 正在编译 Next5h 原生二进制..."
swift build "${SWIFT_BUILD_ARGS[@]}"
BIN_DIR="$(swift build "${SWIFT_BUILD_ARGS[@]}" --show-bin-path)"

APP_NAME="Next5h"
BUNDLE_DIR="$PWD/${APP_NAME}.app"
CONTENTS_DIR="${BUNDLE_DIR}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"

echo "📦 正在打包 ${APP_NAME}.app..."
rm -rf "${BUNDLE_DIR}"
mkdir -p "${MACOS_DIR}" "${RESOURCES_DIR}"

cp "${BIN_DIR}/${APP_NAME}" "${MACOS_DIR}/${APP_NAME}"
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
    <string>com.khalil.next5h</string>
    <key>CFBundleName</key>
    <string>Next5h</string>
    <key>CFBundleDisplayName</key>
    <string>Next5h</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.1</string>
    <key>CFBundleVersion</key>
    <string>2</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>LSApplicationCategoryType</key>
    <string>public.app-category.developer-tools</string>
    <key>NSAppleEventsUsageDescription</key>
    <string>Next5h 在前台模式下需要控制 ChatGPT 与“系统事件”来粘贴并发送任务。Next5h controls ChatGPT and System Events to paste and send tasks in foreground mode.</string>
</dict>
</plist>
PLIST

echo "✅ 打包完成: ${BUNDLE_DIR}"

if [ "${SKIP_INSTALL:-0}" != "1" ] && [ -d "/Applications/${APP_NAME}.app" ]; then
    echo "🔄 正在同步更新 /Applications/${APP_NAME}.app..."
    rm -rf "/Applications/${APP_NAME}.app"
    cp -R "${BUNDLE_DIR}" "/Applications/${APP_NAME}.app"
    touch "/Applications/${APP_NAME}.app"
    /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "/Applications/${APP_NAME}.app" 2>/dev/null || true
    echo "✨ /Applications/${APP_NAME}.app 同步完成并已刷新图标缓存"
fi
