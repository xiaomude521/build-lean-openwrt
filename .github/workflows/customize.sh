#!/bin/bash

echo "Starting customization for OpenWrt build..."

# 1. 添加 Argon 主题源并安装 (针对 Lean's LEDE, 使用 18.06 分支)
echo "Adding and installing luci-theme-argon..."
rm -rf package/lean/luci-theme-argon 2>/dev/null || true # 清理可能存在的旧版
git clone -b 18.06 https://github.com/jerrykuku/luci-theme-argon.git package/lean/luci-theme-argon

# 2. 尝试添加 iStoreOS 风格的元素 (例如网络向导)
# 注意: 完全复制iStoreOS的闭源功能较复杂，这里添加一些类似风格的软件包
echo "Adding packages for iStoreOS-like interface..."

# 添加 luci-app-quickstart (一个常见的快速设置向导，类似iStoreOS的风格)
if [ ! -d "package/lean/luci-app-quickstart" ]; then
    git clone https://github.com/garypang13/luci-app-quickstart package/lean/luci-app-quickstart
fi

# 添加 luci-app-store (iStore 应用商店，是iStoreOS的核心组件之一)
if [ ! -d "package/lean/luci-app-store" ]; then
    git clone https://github.com/linkease/istore-ui package/lean/istore-ui
    git clone https://github.com/linkease/istore package/lean/istore
    # 注意: istore 的依赖和编译可能较复杂，可能需要进一步调整
fi

# 3. 配置默认主题为 Argon
echo "Configuring default theme to Argon..."
sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/luci/Makefile
sed -i 's/+luci-theme-bootstrap/+luci-theme-argon/g' .config 2>/dev/null || echo "Ensure luci-theme-argon is selected in .config"

# 4. 设置默认 LAN IP (可选，根据你的需求修改)
echo "Setting default LAN IP to 192.168.10.1..."
sed -i 's/192.168.1.1/192.168.10.1/g' package/base-files/files/bin/config_generate

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
echo "                 Version: ${{ github.event.inputs.version_tag }}" >> package/base-files/files/etc/banner

echo "Customization script finished."