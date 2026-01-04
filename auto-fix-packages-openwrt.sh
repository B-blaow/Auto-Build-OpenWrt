#!/usr/bin/env bash
set -e

echo "================================================="
echo " Auto-fix missing packages in .config (OpenWrt / ImmortalWrt)"
echo "================================================="

if [ ! -f ".config" ]; then
  echo "❌ .config not found"
  exit 1
fi

# 需要确保开启的包
PACKAGES=(
  nano
  iperf3
  htop
)

FIXED=0

enable_pkg() {
  local pkg="$1"
  local cfg="CONFIG_PACKAGE_${pkg}"

  # 已启用
  if grep -q "^${cfg}=y" .config; then
    echo "✅ ${pkg}: =y"
    return
  fi

  # 已存在但未启用
  if grep -q "^# ${cfg} is not set" .config; then
    echo "⚠️ ${pkg}: is not set"
    sed -i "s/^# ${cfg} is not set/${cfg}=y/" .config
    FIXED=1
    return
  fi

  # 完全不存在
  echo "❌ ${pkg}: not found in .config"
  echo "${cfg}=y" >> .config
  FIXED=1
}

echo "================================================="
echo " Auto-fix missing packages in .config"
echo "================================================="

for pkg in "${PACKAGES[@]}"; do
  enable_pkg "$pkg"
done

# 统一整理配置
if [ "$FIXED" = 1 ]; then
  echo
  echo "🔄 Running make defconfig to normalize .config"
  make defconfig >/dev/null
fi

echo
echo "================================================="
echo " Re-check after auto-fix"
echo "================================================="

FAILED=0
for pkg in "${PACKAGES[@]}"; do
  if grep -q "^CONFIG_PACKAGE_${pkg}=y" .config; then
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
