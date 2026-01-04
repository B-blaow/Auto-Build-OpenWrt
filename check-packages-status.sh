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
  A
  B
  C
  D
  E
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
# 可选 SSH（完全手动）
##################################################
if [ "$ENABLE_SSH" = true ]; then
  echo "🔐 ENABLE_SSH=true → starting SSH session"
  echo

  if ! command -v tmate >/dev/null 2>&1; then
    sudo apt update
    sudo apt install -y tmate
  fi

  tmate new-session -d
  tmate wait tmate-ready

  SSH_CMD=$(tmate display -p '#{tmate_ssh}')
  WEB_CMD=$(tmate display -p '#{tmate_web}')

  echo "==============================================="
  echo " SSH session ready (valid for ${SSH_WAIT_TIMEOUT}s)"
  echo
  echo " SSH : $SSH_CMD"
  echo " WEB : $WEB_CMD"
  echo
  echo " No connection within ${SSH_WAIT_TIMEOUT}s → auto close"
  echo "==============================================="

  ################################################
  # 等待 SSH 连接 or 超时
  ################################################
  SECONDS=0
  while [ $SECONDS -lt $SSH_WAIT_TIMEOUT ]; do
    # 是否已有客户端连接
    if tmate display -p '#{tmate_num_clients}' | grep -vq '^0$'; then
      echo "🔓 SSH client connected"
      echo "   Exit SSH session to continue CI"
      tmate wait tmate-exit
      echo "🔒 SSH session closed by user"
      exit 0
    fi
    sleep 2
  done

  echo "⏱ No SSH connection, timeout reached"
  echo "🔒 Closing SSH session automatically"
  tmate kill-session
else
  echo "ℹ️ ENABLE_SSH=false → SSH skipped"
fi

echo
echo "================================================="
echo " Package status check finished"
echo "================================================="
