#!/usr/bin/env bash
set -e

echo "================================================="
echo " Auto-fix missing packages in .config (LEDE)"
echo "================================================="

# 必须存在 .config
if [ ! -f ".config" ]; then
  echo "❌ .config not found"
  exit 1
fi

##################################################
# 要检查的包（不带 CONFIG_PACKAGE_）
##################################################
CHECK_PKGS=(
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
  kmod-wireguard
  luci-app-mwan3
  mwan3
  luci-i18n-mwan3-zh-cn
)

FIXED=0

##################################################
# 检查并写入 .config
##################################################
for pkg in "${CHECK_PKGS[@]}"; do
  CONF="CONFIG_PACKAGE_${pkg}"

  if grep -q "^${CONF}=y" .config; then
    echo "✅ ${pkg}: =y"

  elif grep -q "^# ${CONF} is not set" .config; then
    echo "⚠️ ${pkg}: is not set"
    echo "   🔧 enable ${pkg}"
    sed -i "s/^# ${CONF} is not set/${CONF}=y/" .config
    FIXED=1

  else
    echo "❌ ${pkg}: not found in .config"
    echo "   🔧 add ${pkg}"
    echo "${CONF}=y" >> .config
    FIXED=1
  fi
done

##################################################
# 让 Kconfig 修正依赖
##################################################
if [ "$FIXED" = 1 ]; then
  echo
  echo "🔄 Running make defconfig to normalize .config"
  make defconfig >/dev/null
fi

##################################################
# 二次校验
##################################################
echo
echo "================================================="
echo " Re-check after auto-fix"
echo "================================================="

FAILED=0
for pkg in "${CHECK_PKGS[@]}"; do
  CONF="CONFIG_PACKAGE_${pkg}"
  if grep -q "^${CONF}=y" .config; then
    echo "✅ ${pkg}: =y"
  else
    echo "❌ ${pkg}: still missing after auto-fix"
    FAILED=1
  fi
done

if [ "$FAILED" = 1 ]; then
  echo
  echo "❌ Package check failed"
  exit 1
fi

echo
echo "================================================="
echo " ✅ All required packages present"
echo "================================================="
