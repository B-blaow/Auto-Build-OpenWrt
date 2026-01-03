#!/usr/bin/env bash
set -e

echo "================================================="
echo " Defconfig Post-Check Script"
echo "================================================="

WORKDIR="$(pwd)"
CONFIG_BEFORE=".config.before"
CONFIG_AFTER=".config"

# -------------------------------------------------
# 1. 保存 defconfig 前的配置
# -------------------------------------------------
if [ -f .config ]; then
  cp .config "$CONFIG_BEFORE"
else
  echo "❌ .config not found"
  exit 1
fi

# -------------------------------------------------
# 2. 统计被吃掉的 CONFIG
# -------------------------------------------------
echo
echo "🔍 Checking removed or changed configs..."

REMOVED=$(comm -23 \
  <(grep '^CONFIG_' "$CONFIG_BEFORE" | sort) \
  <(grep '^CONFIG_' "$CONFIG_AFTER" | sort) || true)

if [ -n "$REMOVED" ]; then
  echo "⚠️ 以下配置在 defconfig 后被移除："
  echo "$REMOVED"
else
  echo "✅ 没有配置被移除"
fi

# -------------------------------------------------
# 3. 检测被取消的包（=n）
# -------------------------------------------------
echo
echo "🔍 Checking disabled packages..."

DISABLED=$(grep '=n' "$CONFIG_AFTER" | grep '^CONFIG_PACKAGE_' || true)

if [ -n "$DISABLED" ]; then
  echo "⚠️ 以下软件包被禁用："
  echo "$DISABLED"
else
  echo "✅ 没有发现被禁用的包"
fi

# -------------------------------------------------
# 4. 强制恢复关键软件包（示例）
#    👉 你可以按需添加###
# -------------------------------------------------
#删去#号恢复运行
#echo
#echo "🛠 Forcing critical packages..."

#CRITICAL_PKGS=(
 # CONFIG_PACKAGE_luci
  #CONFIG_PACKAGE_luci-base
  #CONFIG_PACKAGE_luci-app-opkg
#)

#for pkg in "${CRITICAL_PKGS[@]}"; do
 # if grep -q "^# $pkg is not set" .config; then
  #  sed -i "s/^# $pkg is not set/$pkg=y/" .config
   # echo "✔ restored $pkg"
  #fi
#done

# -------------------------------------------------
# 5. 再次 defconfig 校验
# -------------------------------------------------
echo
echo "🔁 Re-running make defconfig..."
make defconfig > /dev/null

# -------------------------------------------------
# 6. 检测 feeds 中不存在的包
# -------------------------------------------------
echo
echo "🔍 Checking missing feed packages..."

MISSING=""
while read -r line; do
  pkg=$(echo "$line" | sed 's/CONFIG_PACKAGE_//' | sed 's/=y//')
  if ! grep -R "Package/$pkg" -n package feeds >/dev/null 2>&1; then
    MISSING+="$pkg"$'\n'
  fi
done < <(grep '^CONFIG_PACKAGE_.*=y' .config)

if [ -n "$MISSING" ]; then
  echo "⚠️ 以下包在 feeds 中不存在："
  echo "$MISSING"
else
  echo "✅ 所有已选包在 feeds 中存在"
fi

# -------------------------------------------------
# 7. 总结
# -------------------------------------------------
echo
echo "================================================="
echo " Defconfig check finished"
echo "================================================="
