#!/bin/bash
#===============================================
# Modify default IP
sed -i 's/192.168.1.1/192.168.5.1/g' $(pwd)/package/base-files/files/bin/config_generate
#
#
#
#
#加入nano
sed -i 's/^# CONFIG_PACKAGE_nano is not set/CONFIG_PACKAGE_nano=y/' .config
grep -q '^CONFIG_PACKAGE_nano=y' .config || echo 'CONFIG_PACKAGE_nano=y' >> .config
