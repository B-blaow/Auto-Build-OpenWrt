#!/usr/bin/env bash
set -e

##################################################
# 是否开启 SSH（true / false）
# 默认 false，不会自动触发
##################################################
ENABLE_SSH=false

##################################################
# SSH 最大等待时间（秒）
# 120 = 2 分钟
##################################################
SSH_WAIT_TIMEOUT=120

##################################################
# 要检查的包名（示例）
# 填 CONFIG_PACKAGE_ 后面的名字
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
echo " Package Status Check After defconfig"
echo "================================================="

for pkg in "${CHECK_PKGS[@]}"; do
  CONF="CONFIG_PACKAGE_${pkg}"

  if grep -q "^${CONF}=y" .config; then
    echo "✅ ${pkg}: =y"

  elif grep -q "^# ${CONF} is not set" .config; then
    echo "⚠️ ${pkg}: is not set"

  else
    echo "❌ ${pkg}: not found in .config"
  fi
done

echo "-------------------------------------------------"

##################################################
# 可选 SSH（完全手动，不自动触发）
##################################################
if [ "$ENABLE_SSH" = true ]; then
  echo "🔐 ENABLE_SSH=true → starting SSH session"
  echo

  if ! command -v tmate >/dev/null 2>&1; then
    sudo apt update
    sudo apt install -y tmate
  fi

  # 🔑 必须使用 socket（CI 环境必需）
  SOCK="/tmp/tmate.sock"

  tmate -S "$SOCK" new-session -d
  tmate -S "$SOCK" wait tmate-ready

  SSH_CMD=$(tmate -S "$SOCK" display -p '#{tmate_ssh}')
  WEB_CMD=$(tmate -S "$SOCK" display -p '#{tmate_web}')

  echo "==============================================="
  #echo   #echo " SSH session ready (max ${SSH_WAIT_TIM
  SSH_CMD=$(tmate -S "$SOCK" display -p '#{tmate_ssh}')
  echo
  echo " SSH : $SSH_CMD"
  echo " WEB : $WEB_CMD"
  echo
  echo " No connection within ${SSH_WAIT_TIMEOUT}s → auto close"
  echo "==============================================="

  ################################################
  # 等待 SSH 连接 or 超时
  ################################################
  START=$(date +%s)

  while true; do
    CLIENTS=$(tmate -S "$SOCK" display -p '#{tmate_num_clients}')

    if [ "$CLIENTS" -gt 0 ]; then
      echo "🔓 SSH client connected"
      echo "   Exit SSH session to continue CI"
      tmate -S "$SOCK" wait tmate-session-closed
      echo "🔒 SSH session closed by user"
      break
    fi

    NOW=$(date +%s)
    if [ $((NOW - START)) -ge $SSH_WAIT_TIMEOUT ]; then
      echo "⏱ No SSH connection, timeout reached"
      echo "🔒 Closing SSH session automatically"
      tmate -S "$SOCK" kill-session
      break
    fi

    sleep 5
  done
else
  echo "ℹ️ ENABLE_SSH=false → SSH skipped"
fi

echo
echo "================================================="
echo " Package status check finished"
echo "================================================="
