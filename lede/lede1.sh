#!/bin/bash
#===============================================




# Add a feed source
echo 'src-git helloworld https://github.com/fw876/helloworld' >>feeds.conf.default
#echo 'src-git passwall https://github.com/xiaorouji/openwrt-passwall' >>feeds.conf.default




#OpenAppFilter    
#git clone https://github.com/destan19/OpenAppFilter.git package/OpenAppFilter

#add nano
git clone --depth=1 \
  https://github.com/openwrt/packages.git \
  -b master \
  /tmp/packages

mkdir -p package/custom
cp -r /tmp/packages/utils/nano package/custom/
rm -rf /tmp/packages
