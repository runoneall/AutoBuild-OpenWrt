#!/bin/bash
#=================================================
# Copyright (c) 2019-2020 P3TERX <https://p3terx.com>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part2.sh
# Description: OpenWrt DIY script part 2 (After Update feeds)
#=================================================

# Modify default IP 修改openwrt登陆地址,把下面的192.168.3.1修改成你想要的就可以了
sed -i 's/192.168.1.1/10.32.0.1/g' package/base-files/files/bin/config_generate

# 修改网关
sed -i 's/192.168.$((addr_offset++)).1/10.32.$((addr_offset++)).1/g' package/base-files/files/bin/config_generate

# 修改默认wifi名称ssid为Xiaomi-Wifi
cp -rf $GITHUB_WORKSPACE/patchs/xiaomi_mi-router/mt76x8/mac80211.sh package/kernel/mac80211/files/lib/wifi/mac80211.sh

# #Enable 802.11k/v/r
# sed -i 's/RRMEnable=0/RRMEnable=1/g' package/kernel/mt-drivers/mt_wifi/files/mt7615.1.2G.dat
# sed -i 's/RRMEnable=0/RRMEnable=1/g' package/kernel/mt-drivers/mt_wifi/files/mt7615.1.5G.dat
# sed -i 's/FtSupport=0/FtSupport=1/g' package/kernel/mt-drivers/mt_wifi/files/mt7615.1.2G.dat
# sed -i 's/FtSupport=0/FtSupport=1/g' package/kernel/mt-drivers/mt_wifi/files/mt7615.1.5G.dat
# echo 'WNMEnable=1' >> package/kernel/mt-drivers/mt_wifi/files/mt7615.1.2G.dat
# echo 'WNMEnable=1' >> package/kernel/mt-drivers/mt_wifi/files/mt7615.1.5G.dat

# 打补丁
wget -O package/firmware/xt_FULLCONENAT.c https://raw.githubusercontent.com/Chion82/netfilter-full-cone-nat/master/xt_FULLCONENAT.c
cp -rf package/firmware/xt_FULLCONENAT.c package/libs/libnetfilter-conntrack/xt_FULLCONENAT.c

# nft-fullcone
git clone -b main --single-branch https://github.com/fullcone-nat-nftables/nftables-1.0.5-with-fullcone package/nftables
git clone -b master --single-branch https://github.com/fullcone-nat-nftables/libnftnl-1.2.4-with-fullcone package/libnftnl

# 测试编译时间
YUOS_DATE="$(date +%Y.%m.%d)(月更版)"
BUILD_STRING=${BUILD_STRING:-$YUOS_DATE}
echo "Write build date in openwrt : $BUILD_DATE"
echo -e '\n小渔学长 Build @ '${BUILD_STRING}'\n'  >> package/base-files/files/etc/banner
sed -i '/DISTRIB_REVISION/d' package/base-files/files/etc/openwrt_release
echo "DISTRIB_REVISION=''" >> package/base-files/files/etc/openwrt_release
sed -i '/DISTRIB_DESCRIPTION/d' package/base-files/files/etc/openwrt_release
echo "DISTRIB_DESCRIPTION='小渔学长 Build @ ${BUILD_STRING}'" >> package/base-files/files/etc/openwrt_release


#升级cmake
rm -rf tools/cmake
mkdir -p tools/cmake/
cp -rf $GITHUB_WORKSPACE/patchs/5.4/tools/cmake/* tools/cmake/

### 后补的

#FullCone Patch
git clone -b master --single-branch https://github.com/QiuSimons/openwrt-fullconenat package/fullconenat
# Patch FireWall for fullcone
mkdir package/network/config/firewall/patches
wget -P package/network/config/firewall/patches/ https://raw.githubusercontent.com/LGA1150/fullconenat-fw3-patch/master/fullconenat.patch

pushd feeds/luci
wget -O- https://raw.githubusercontent.com/LGA1150/fullconenat-fw3-patch/master/luci.patch | git apply
popd


# 删除多余组件
rm -rf feeds/small8/fullconenat-nft
rm -rf feeds/small8/fullconenat

# 为保障流畅，针对SSR做特定版本处理
# xray 1.7.5
cp -rf $GITHUB_WORKSPACE/patchs/5.4/xray-core/1.7.5/* feeds/helloworld/xray-core/
cp -rf $GITHUB_WORKSPACE/patchs/5.4/xray-core/1.7.5/* feeds/small/xray-core/
cp -rf $GITHUB_WORKSPACE/patchs/5.4/xray-core/1.7.5/* feeds/small8/xray-core/

# tailscale 1.40.0
cp -rf $GITHUB_WORKSPACE/patchs/5.4/tailscale/* feeds/packages/net/tailscale/
cp -rf $GITHUB_WORKSPACE/patchs/5.4/tailscale/* feeds/small/tailscale/
cp -rf $GITHUB_WORKSPACE/patchs/5.4/tailscale/* feeds/helloworld/tailscale/

# naiveproxy
cp -rf feeds/small8/naiveproxy/* feeds/small/naiveproxy/
cp -rf feeds/small8/naiveproxy/* feeds/small8/naiveproxy/
cp -rf feeds/small8/naiveproxy/* feeds/helloworld/naiveproxy/

# hysteria 1.3.5
cp -rf $GITHUB_WORKSPACE/patchs/5.4/hysteria/* feeds/small/hysteria/
cp -rf $GITHUB_WORKSPACE/patchs/5.4/hysteria/* feeds/packages/net/hysteria/
cp -rf $GITHUB_WORKSPACE/patchs/5.4/hysteria/* feeds/helloworld/hysteria/

#升级golang
find . -type d -name "golang" -exec rm -r {} +
rm -rf feeds/packages/lang/golang
git clone https://github.com/sbwml/packages_lang_golang -b 20.x feeds/packages/lang/golang
# mkdir -p feeds/packages/lang/golang/golang/
# cp -rf $GITHUB_WORKSPACE/patchs/5.4/golang/* feeds/packages/lang/golang/golang/

#设置软件唯一性
find . -type d -name "gn" -exec rm -r {} +
mkdir -p feeds/small8/gn/
cp -rf $GITHUB_WORKSPACE/patchs/5.4/gn/* feeds/small8/gn/
rm -rf feeds/small/brook
rm -rf feeds/helloworld/shadowsocks-rust
rm -rf feeds/small/shadowsocks-rust
rm -rf feeds/helloworld/simple-obfs
rm -rf feeds/helloworld/v2ray-plugin
rm -rf feeds/small/v2ray-plugin
# find . -type d -name "sing-box" -exec rm -r {} +