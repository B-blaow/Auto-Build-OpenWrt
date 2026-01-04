#!/usr/bin/env bash
set -e

##################################################
# 要确保启用的包（不带 CONFIG_PACKAGE_ 前缀）
##################################################
REQUIRED_PKGS=(
  luci-app-ttyd
  mosdns
  luci-app-mosdns
  luci-i18n-mosdns-zh-cn
  luci-app-homeproxy
  luci-i18n-homeproxy-zh-cn
  luci-i18n-adguardhome-zh-cn
  luci-app-adguardhome
  nikki
  luci-app-nikki
  luci-i18n-nikki-zh-cn
  nano
  cloudflared
  luci-app-cloudflared
  wireguard-tools
  SING_BOX_BUILD_WIREGUARD
  kmod-wireguard
  luci-app-mwan3
  mwan3
  luci-i18n-mwan3-zh-cn  
)

echo "================================================="
echo " Auto-fix missing packages in .config"
echo "================================================="

##################################################
# 检查环境
##################################################
if [ ! -f ".config" ]; then
  echo "❌ .config not found"
  exit 1
fi

if [ ! -x "scripts/config" ]; then
  echo "❌ scripts/config not found or not executable"
  exit 1
fi

##################################################
# 自动修复
##################################################
FIXED=0

for pkg in "${REQUIRED_PKGS[@]}"; do
  CONF="CONFIG_PACKAGE_${pkg}"

  if grep -q "^${CONF}=y" .config; then
    echo "✅ ${pkg}: already enabled"

  else
    echo "🔧 ${pkg}: enable"
    scripts/config --enable "${CONF}"
    FIXED=1
  fi
done

##################################################
# 如果有修改，重新整理 config
##################################################
if [ "$FIXED" -eq 1 ]; then
  echo
  echo "♻️ Running make defconfig to normalize .config"
  make defconfig
else
  echo
  echo "ℹ️ No changes needed"
fi

echo
echo "================================================="
echo " Auto-fix completed"
echo "================================================="
