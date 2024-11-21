#!/bin/bash

# 设置变量
APP_NAME="端口映射器"
BUILD_DIR="$(pwd)/.build/release"
APP_DIR="/Applications"
CONFIG_DIR="$HOME/.config/fc-port"
BUNDLE_NAME="$APP_NAME.app"
CONTENTS_DIR="$BUILD_DIR/$BUNDLE_NAME/Contents"

# 编译项目
echo "正在编译项目..."
swift build -c release

# 检查编译是否成功
if [ $? -ne 0 ]; then
    echo "编译失败！"
    exit 1
fi

# 创建应用程序包
echo "正在创建应用程序包..."
rm -rf "$BUILD_DIR/$BUNDLE_NAME"
mkdir -p "$CONTENTS_DIR/MacOS"
mkdir -p "$CONTENTS_DIR/Resources"

# 复制二进制文件
cp "$BUILD_DIR/FCPort" "$CONTENTS_DIR/MacOS/FCPort"
chmod +x "$CONTENTS_DIR/MacOS/FCPort"

# 复制 Info.plist
cp "Info.plist" "$CONTENTS_DIR/Info.plist"

# 复制图标
if [ -f "Resources/AppIcon.icns" ]; then
    cp "Resources/AppIcon.icns" "$CONTENTS_DIR/Resources/"
fi

# 复制状态栏图标
if [ -f "Resources/StatusBarIcon.svg" ]; then
    cp "Resources/StatusBarIcon.svg" "$CONTENTS_DIR/Resources/"
fi

# 如果配置目录不存在，创建它
if [ ! -d "$CONFIG_DIR" ]; then
    mkdir -p "$CONFIG_DIR"
fi

# 对应用程序进行签名
echo "正在签名应用程序..."
codesign --force --deep --sign - "$BUILD_DIR/$BUNDLE_NAME"

# 询问是否要复制到应用程序目录
echo "是否要将应用复制到应用程序目录？[y/N]"
read -r response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    # 如果应用已存在，先删除
    if [ -d "$APP_DIR/$BUNDLE_NAME" ]; then
        rm -rf "$APP_DIR/$BUNDLE_NAME"
    fi
    
    # 复制应用
    cp -R "$BUILD_DIR/$BUNDLE_NAME" "$APP_DIR/"
    
    # 移除隔离属性
    xattr -cr "$APP_DIR/$BUNDLE_NAME"
    
    # 复制现有配置（如果存在）
    if [ -f "$BUILD_DIR/config.json" ]; then
        cp "$BUILD_DIR/config.json" "$CONFIG_DIR/"
    fi
    
    echo "应用已安装到 $APP_DIR/$BUNDLE_NAME"
    echo "配置文件位置：$CONFIG_DIR"
else
    echo "应用包已创建在：$BUILD_DIR/$BUNDLE_NAME"
fi

echo "完成！"
