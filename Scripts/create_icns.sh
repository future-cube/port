#!/bin/bash

# 设置变量
ICON_NAME="AppIcon"
ICONSET_DIR="$ICON_NAME.iconset"
SVG_FILE="../Resources/$ICON_NAME.svg"

# 创建临时目录
mkdir -p "$ICONSET_DIR"

# 使用 rsvg-convert 将 SVG 转换为不同尺寸的 PNG
# 需要先安装 librsvg: brew install librsvg
for size in 16 32 64 128 256 512 1024; do
    rsvg-convert -w $size -h $size "$SVG_FILE" > "$ICONSET_DIR/icon_${size}x${size}.png"
    
    # 创建 @2x 版本
    if [ $size -le 512 ]; then
        rsvg-convert -w $((size*2)) -h $((size*2)) "$SVG_FILE" > "$ICONSET_DIR/icon_${size}x${size}@2x.png"
    fi
done

# 重命名文件以符合 Apple 的命名规范
mv "$ICONSET_DIR/icon_16x16.png" "$ICONSET_DIR/icon_16x16.png"
mv "$ICONSET_DIR/icon_32x32.png" "$ICONSET_DIR/icon_32x32.png"
mv "$ICONSET_DIR/icon_64x64.png" "$ICONSET_DIR/icon_32x32@2x.png"
mv "$ICONSET_DIR/icon_128x128.png" "$ICONSET_DIR/icon_128x128.png"
mv "$ICONSET_DIR/icon_256x256.png" "$ICONSET_DIR/icon_256x256.png"
mv "$ICONSET_DIR/icon_512x512.png" "$ICONSET_DIR/icon_512x512.png"
mv "$ICONSET_DIR/icon_1024x1024.png" "$ICONSET_DIR/icon_512x512@2x.png"

# 使用 iconutil 创建 .icns 文件
iconutil -c icns "$ICONSET_DIR"

# 移动 .icns 文件到 Resources 目录
mv "$ICON_NAME.icns" "../Resources/"

# 清理临时文件
rm -rf "$ICONSET_DIR"

echo "图标已创建：../Resources/$ICON_NAME.icns"
