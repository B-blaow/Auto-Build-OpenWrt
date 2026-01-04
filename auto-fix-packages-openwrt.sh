#!/usr/bin/env bash
set -e

echo "================================================="
echo " Auto-fix missing packages in .config (OpenWrt / ImmortalWrt)"
echo "================================================="

# 必须存在 .config
if [ ! -f ".config" ]; then
  echo "❌ .config not found"
  exit 1
fi

# 判断正确的 config 工具
if [ -f "./scripts/config" ]; then
  CONFIG_TOOL="./scripts/config"
else
  echo "❌ No usable config tool found!"
  exit 1
fi

echo "ℹ️ Using config tool: ${CONFIG_TOOL}"
echo "================================================="
echo " Auto-fix missing packages in .config"
echo "================================================="

FIXED=0
FAILED=0

##################################################
# 检查并修复缺失包
##################################################
CHECK_PKGS=(
  luci-app-ttyd
  nano
  cloudflared
  luci-app-cloudflared
  wireguard-tools
  kmod-wireguard
  luci-app-mwan3
  mwan3
  luci-i18n-mwan3-zh-cn
)

for pkg in "${CHECK_PKGS[@]}"; do
  CONF="CONFIG_PACKAGE_${pkg}"
  SYMBOL="PACKAGE_${pkg}"

  if grep -q "^${CONF}=y" .config; then
    echo "✅ ${pkg}: =y"

  elif grep -q "^# ${CONF} is not set" .config; then
    echo "⚠️ ${pkg}: is not set"
    echo "   🔧 enable ${pkg}"
    ${CONFIG_TOOL} set "${SYMBOL}" y || true
    FIXED=1

  else
    echo "❌ ${pkg}: not found in .config"
    echo "   🔧 enable ${pkg}"
    ${CONFIG_TOOL} set "${SYMBOL}" y || true
    FIXED=1
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
