#!/bin/bash

echo "Starting customization for OpenWrt build..."
set -e  # 遇到错误立即退出

# 使用正确的仓库名
REPO_URL="https://github.com/xiaomude521/small-package"
BRANCH="main"  # 使用 main 分支
TEMP_DIR="package/lean/temp-repo"

# 1. 克隆整个仓库到临时目录
echo "Cloning packages from: ${REPO_URL}"
echo "Using branch: ${BRANCH}"
rm -rf "$TEMP_DIR" 2>/dev/null || true

# 尝试克隆，如果失败则尝试使用 master 分支
if ! git clone --depth=1 --branch="$BRANCH" "$REPO_URL" "$TEMP_DIR"; then
    echo "Failed to clone with branch '$BRANCH', trying 'master'..."
    BRANCH="master"
    if ! git clone --depth=1 --branch="$BRANCH" "$REPO_URL" "$TEMP_DIR"; then
        echo "Error: Failed to clone repository with both 'main' and 'master' branches"
        echo "Available branches:"
        git ls-remote --heads "$REPO_URL" | cut -f2 | cut -d'/' -f3
        exit 1
    fi
fi

echo "Successfully cloned repository with branch: $BRANCH"

# 2. 移动所有需要的包
move_package() {
    local pkg_name=$1
    echo "Processing $pkg_name..."
    
    # 移除现有包（如果存在）
    rm -rf "package/lean/$pkg_name" 2>/dev/null || true
    
    # 检查并移动新包
    if [ -d "$TEMP_DIR/$pkg_name" ]; then
        mv "$TEMP_DIR/$pkg_name" "package/lean/"
        echo "Successfully added $pkg_name"
    else
        echo "Warning: $pkg_name not found in the repo"
        # 列出可用的包
        echo "Available packages in repo:"
        ls -la "$TEMP_DIR/" | grep -E '^d' | awk '{print $9}'
        return 1
    fi
}

# 添加 Argon 主题
move_package "luci-theme-argon"

# 添加 iStoreOS 风格的元素
move_package "luci-app-store"
move_package "luci-app-quickstart"

# 3. 清理临时目录
rm -rf "$TEMP_DIR"

# 4. 配置默认主题为 Argon
echo "Configuring default theme to Argon..."
if [ -d "package/lean/luci-theme-argon" ]; then
    # 修改 feeds 中的 Makefile
    if [ -f "feeds/luci/collections/luci/Makefile" ]; then
        sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/luci/Makefile
    fi
    
    # 确保 .config 中包含 Argon 主题
    if grep -q "CONFIG_PACKAGE_luci-theme-argon" .config; then
        sed -i 's/^# *CONFIG_PACKAGE_luci-theme-argon/CONFIG_PACKAGE_luci-theme-argon/' .config
    else
        echo "CONFIG_PACKAGE_luci-theme-argon=y" >> .config
    fi
    
    # 移除 Bootstrap 主题（如果存在）
    if grep -q "CONFIG_PACKAGE_luci-theme-bootstrap" .config; then
        sed -i 's/CONFIG_PACKAGE_luci-theme-bootstrap=y/# CONFIG_PACKAGE_luci-theme-bootstrap is not set/' .config
    fi
    
    echo "Default theme set to Argon"
else
    echo "Warning: luci-theme-argon not found, cannot set as default theme"
fi

# 5. 设置默认 LAN IP
echo "Setting default LAN IP to ${CUSTOM_IP:-192.168.10.5}..."
if [ -n "$CUSTOM_IP" ]; then
    sed -i "s/192.168.1.1/$CUSTOM_IP/g" package/base-files/files/bin/config_generate
else
    sed -i 's/192.168.1.1/192.168.10.5/g' package/base-files/files/bin/config_generate
fi

# 6. 修改默认主机名和欢迎信息
echo "Modifying hostname and banner..."
sed -i 's/OpenWrt/iStoreOS-Lite/g' package/base-files/files/bin/config_generate

# 创建自定义 banner
cat > package/base-files/files/etc/banner << 'EOF'
_________
    /        /\      _    ___ ___  ___
   /  LE    /  \    | |  | __|   \| __|
  /    DE  /    \   | |__| _|| |) | _|
 /________/  LE  \  |____|___|___/|___|
 \        \   DE /
  \    LE  \    /  -------------------------------------------
   \  DE    \  /    %D %V
    \________\/    -------------------------------------------
EOF

# 添加版本信息
if [ -n "$VERSION_TAG" ]; then
    sed -i "/-------------------------------------------/a\                 Version: $VERSION_TAG" package/base-files/files/etc/banner
else
    sed -i "/-------------------------------------------/a\                 Version: Custom Build" package/base-files/files/etc/banner
fi

echo "Customization script finished successfully."