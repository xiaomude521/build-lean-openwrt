#!/bin/bash

echo "Starting customization for OpenWrt build..."

# 1. 添加 Argon 主题 (从 xiaomude521/openwrt-packages 仓库)
echo "Adding and installing luci-theme-argon..."
rm -rf package/lean/luci-theme-argon 2>/dev/null || true
git clone https://github.com/xiaomude521/openwrt-packages.git package/lean/temp-repo
mv package/lean/temp-repo/luci-theme-argon package/lean/
rm -rf package/lean/temp-repo

# 2. 添加 iStoreOS 风格的元素
echo "Adding packages for iStoreOS-like interface..."

# 添加 luci-app-quickstart
if [ ! -d "package/lean/luci-app-quickstart" ]; then
    git clone https://github.com/xiaomude521/openwrt-packages.git package/lean/temp-repo
    mv package/lean/temp-repo/luci-app-quickstart package/lean/
    rm -rf package/lean/temp-repo
fi

# 添加 istore-ui 和 istore
if [ ! -d "package/lean/istore-ui" ]; then
    git clone https://github.com/xiaomude521/openwrt-packages.git package/lean/temp-repo
    mv package/lean/temp-repo/istore-ui package/lean/
    rm -rf package/lean/temp-repo
fi

if [ ! -d "package/lean/istore" ]; then
    git clone https://github.com/xiaomude521/openwrt-packages.git package/lean/temp-repo
    mv package/lean/temp-repo/istore package/lean/
    rm -rf package/lean/temp-repo
fi

# 3. 配置默认主题为 Argon
echo "Configuring default theme to Argon..."
sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/luci/Makefile
sed -i 's/+luci-theme-bootstrap/+luci-theme-argon/g' .config 2>/dev/null || echo "Ensure luci-theme-argon is selected in .config"

# 4. 设置默认 LAN IP (从环境变量获取)
echo "Setting default LAN IP to ${CUSTOM_IP:-192.168.10.1}..."
if [ -n "$CUSTOM_IP" ]; then
    sed -i "s/192.168.1.1/$CUSTOM_IP/g" package/base-files/files/bin/config_generate
else
    sed -i 's/192.168.1.1/192.168.10.1/g' package/base-files/files/bin/config_generate
fi

# 5. 尝试修改默认主机名和欢迎信息 (模仿iStoreOS风格)
echo "Modifying hostname and banner..."
sed -i 's/OpenWrt/iStoreOS-Lite/g' package/base-files/files/bin/config_generate
echo "_________" > package/base-files/files/etc/banner
echo "    /        /\      _    ___ ___  ___" >> package/base-files/files/etc/banner
echo "   /  LE    /  \    | |  | __|   \| __|" >> package/base-files/files/etc/banner
echo "  /    DE  /    \   | |__| _|| |) | _|" >> package/base-files/files/etc/banner
echo " /________/  LE  \  |____|___|___/|___|" >> package/base-files/files/etc/banner
echo " \        \   DE /" >> package/base-files/files/etc/banner
echo "  \    LE  \    /  -------------------------------------------" >> package/base-files/files/etc/banner
echo "   \  DE    \  /    %D %V" >> package/base-files/files/etc/banner
echo "    \________\/    -------------------------------------------" >> package/base-files/files/etc/banner

# 使用环境变量中的版本标签
if [ -n "$VERSION_TAG" ]; then
    echo "                 Version: $VERSION_TAG" >> package/base-files/files/etc/banner
else
    echo "                 Version: Custom Build" >> package/base-files/files/etc/banner
fi

echo "Customization script finished."