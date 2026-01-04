#!/usr/bin/env bash
set -e

##################################################
# 是否自动修复缺失包
# true  : 自动写回 .config
# false : 只检测（失败即退出）
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
  nano
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
if [ ! -f ".config" ]; then
  echo "❌ .config not found, please run make defconfig first"
  exit 1
fi

if [ ! -x scripts/config/conf ]; then
  echo "❌ scripts/config/conf not found"
  echo "👉 run make defconfig / make menuconfig first"
  exit 1
fi

echo "================================================="
echo " Auto-fix missing packages in .config"
echo "================================================="

FIXED=0
FAILED=0

##################################################
# 检测 + 自动修复
##################################################
for pkg in "${CHECK_PKGS[@]}"; do
  CONF="CONFIG_PACKAGE_${pkg}"

  if grep -q "^${CONF}=y" .config; then
    echo "✅ ${pkg}: =y"

  elif grep -q "^# ${CONF} is not set" .config; then
    echo "⚠️ ${pkg}: is not set"
    if [ "$AUTO_FIX" = true ]; then
      echo "   🔧 enable ${pkg}"
      scripts/config/conf --enable "${CONF}"
      FIXED=1
    else
      FAILED=1
    fi

  else
    echo "❌ ${pkg}: not found in .config"
    if [ "$AUTO_FIX" = true ]; then
      echo "   🔧 enable ${pkg}"
      scripts/config/conf --enable "${CONF}"
      FIXED=1
    else
      FAILED=1
    fi
  fi
done

##################################################
# 如果有修改，重新整理 .config
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
  echo "👉 Some packages are unavailable for this target or feeds"
  exit 1
fi

echo
echo "================================================="
echo " ✅ All required packages present"
echo "================================================="
