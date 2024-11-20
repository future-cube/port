#!/bin/bash

# 清理旧的构建目录
rm -rf dist
mkdir -p dist

# 构建应用
swift build -c release

# 创建应用包结构
mkdir -p dist/FCPort.app/Contents/{MacOS,Resources}

# 复制可执行文件
cp -f .build/release/FCPort dist/FCPort.app/Contents/MacOS/

# 创建 Info.plist
cat > dist/FCPort.app/Contents/Info.plist << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleIdentifier</key>
    <string>com.example.fcport</string>
    <key>CFBundleName</key>
    <string>FCPort</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>12.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
EOF

# 设置可执行权限
chmod +x dist/FCPort.app/Contents/MacOS/FCPort

echo "Application packaged at dist/FCPort.app"
