#!/bin/bash

echo "Starting customization for OpenWrt build..."

# 使用特定分支的仓库
REPO_URL="https://github.com/xiaomude521/openwrt-packages"
BRANCH="master"  # 使用 master 分支

# 1. 添加 Argon 主题
echo "Adding and installing luci-theme-argon..."
rm -rf package/lean/luci-theme-argon 2>/dev/null
git clone --depth=1 --branch="$BRANCH" "$REPO_URL" package/lean/temp-repo
# 检查主题目录是否存在然后移动
if [ -d "package/lean/temp-repo/luci-theme-argon" ]; then
    mv package/lean/temp-repo/luci-theme-argon package/lean/
    echo "Successfully added luci-theme-argon"
else
    echo "Warning: luci-theme-argon not found in the repo"
fi
rm -rf package/lean/temp-repo

# 2. 添加 iStoreOS 风格的元素
echo "Adding packages for iStoreOS-like interface..."

# 使用函数克隆和移动包
clone_and_move() {
    local pkg_name=$1
    if [ ! -d "package/lean/$pkg_name" ]; then
        echo "Adding $pkg_name..."
        git clone --depth=1 --branch="$BRANCH" "$REPO_URL" package/lean/temp-repo
        # 检查包是否存在，然后移动
        if [ -d "package/lean/temp-repo/$pkg_name" ]; then
            mv package/lean/temp-repo/$pkg_name package/lean/
            echo "Successfully added $pkg_name"
        else
            echo "Warning: $pkg_name not found in the repo"
        fi
        rm -rf package/lean/temp-repo
    else
        echo "$pkg_name already exists, skipping..."
    fi
}

# 添加 iStore 相关包（只添加确认存在的包）
clone_and_move "luci-app-store"
clone_and_move "luci-app-quickstart"

# 3. 配置默认主题为 Argon
echo "Configuring default theme to Argon..."
if [ -d "package/lean/luci-theme-argon" ]; then
    sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/luci/Makefile
    sed -i 's/+luci-theme-bootstrap/+luci-theme-argon/g' .config 2>/dev/null || echo "Ensure luci-theme-argon is selected in .config"
    echo "Default theme set to Argon"
else
    echo "Warning: luci-theme-argon not found, cannot set as default theme"
fi

# 4. 设置默认 LAN IP 为 192.168.10.5
echo "Setting default LAN IP to ${CUSTOM_IP:-192.168.10.5}..."
if [ -n "$CUSTOM_IP" ]; then
    sed -i "s/192.168.1.1/$CUSTOM_IP/g" package/base-files/files/bin/config_generate
else
    sed -i 's/192.168.1.1/192.168.10.5/g' package/base-files/files/bin/config_generate
fi

# 5. 修改默认主机名和欢迎信息
echo "Modifying hostname and banner..."
sed -i 's/OpenWrt/iStoreOS-Lite/g' package/base-files/files/bin/config_generate
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

if [ -n "$VERSION_TAG" ]; then
    sed -i "/-------------------------------------------/a\                 Version: $VERSION_TAG" package/base-files/files/etc/banner
else
    sed -i "/-------------------------------------------/a\                 Version: Custom Build" package/base-files/files/etc/banner
fi

echo "Customization script finished."
