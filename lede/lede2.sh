#!/bin/bash
#===============================================
# Modify default IP
sed -i 's/192.168.1.1/192.168.5.1/g' $(pwd)/package/base-files/files/bin/config_generate

#Clear the login password
sed -i 's/$1$V4UetPzk$CYXluq4wUazHjmCDBCqXF.//g' $(pwd)/package/lean/default-settings/files/zzz-default-settings

# ==== 加入nano ====
#sed -i 's/^# CONFIG_PACKAGE_nano is not set/CONFIG_PACKAGE_nano=y/' .config
#grep -q '^CONFIG_PACKAGE_nano=y' .config || echo 'CONFIG_PACKAGE_nano=y' >> .config


cat >> .config <<EOF
CONFIG_PACKAGE_open-app-filter=y
CONFIG_PACKAGE_oaf=y
CONFIG_PACKAGE_luci-app-oaf=y
CONFIG_PACKAGE_nano=y
CONFIG_PACKAGE_htop=y
EOF
