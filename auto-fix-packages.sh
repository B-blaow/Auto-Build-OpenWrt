#!/usr/bin/env bash
set -e

##################################################
# 自动修复缺失包
##################################################
AUTO_FIX=true

##################################################
# 要检查的包名（不带 CONFIG_PACKAGE_）
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
  ddns-scripts-cloudflare
  cloudflared
  luci-app-cloudflared
  wireguard-tools
  kmod-wireguard
  luci-app-mwan3
  mwan3
  luci-i18n-mwan3-zh-cn
)

##################################################
# 前置检查
##################################################
[ -f ".config" ] || { echo "❌ .config not found"; exit 1; }

# 选择正确的 config 工具
if [ -x "./scripts/config.sh" ]; then
  CONFIG_TOOL="./scripts/config.sh"
elif [ -x "./scripts/config" ]; then
  CONFIG_TOOL="./scripts/config"
else
  echo "❌ No usable scripts/config found"
  exit 1
fi

echo "ℹ️ Using config tool: ${CONFIG_TOOL}"
echo "================================================="
echo " Auto-fix missing packages in .config"
echo "================================================="

FIXED=0
FAILED=0

##################################################
# 检测 + 修复
##################################################
for pkg in "${CHECK_PKGS[@]}"; do
  CONF="CONFIG_PACKAGE_${pkg}"
  SYMBOL="PACKAGE_${pkg}"

  if grep -q "^${CONF}=y" .config; then
    echo "✅ ${pkg}: =y"

  elif grep -q "^# ${CONF} is not set" .config; then
    echo "⚠️ ${pkg}: is not set"
    if [ "$AUTO_FIX" = true ]; then
      echo "   🔧 enable ${pkg}"
      ${CONFIG_TOOL} set "${SYMBOL}" y || true
      FIXED=1
    else
      FAILED=1
    fi

  else
    echo "❌ ${pkg}: not found in .config"
    if [ "$AUTO_FIX" = true ]; then
      echo "   🔧 enable ${pkg}"
      ${CONFIG_TOOL} set "${SYMBOL}" y || true
      FIXED=1
    else
      FAILED=1
    fi
  fi
done

##################################################
# 重新整理 .config
##################################################
if [ "$FIXED" = 1 ]; then
  echo
  echo "🔄 Running make defconfig to normalize .config"
  make defconfig >/dev/null
fi

##################################################
# 二次校验（CI gating）
##################################################
echo
echo "================================================="
echo " Re-check after auto-fix"
echo "================================================="

for pkg in "${CHECK_PKGS[@]}"; do
  CONF="CONFIG_PACKAGE_${pkg}"

  if grep -q "^${CONF}=y" .config; then
    echo "✅ ${pkg}: =y"
  else
    echo "❌ ${pkg}: still missing after auto-fix"
    FAILED=1
  fi
done

##################################################
# CI 结果
##################################################
if [ "$FAILED" = 1 ]; then
  echo
  echo "❌ Package check failed"
  exit 1
fi

echo
echo "================================================="
echo " ✅ All required packages present"
echo "================================================="
