AutoBuild OpenWrt / ImmortalWrt / LEDE

GitHub Actions CI 的 OpenWrt / ImmortalWrt / LEDE 自动化编译仓库，
重点解决以下问题：

🧱 GitHub Actions 磁盘空间不足

⚠️ make defconfig 静默取消已选包

🔧 自动检测 / 修复 .config 中丢失的包（默认调用check-packages-status.sh只检测，默认不连接ssh，修改脚本可以连接ssh）


1️⃣ 解决 GitHub Actions 空间不足问题

GitHub Actions 默认只有约 14GB 可用空间，直接编译 OpenWrt 极易失败。

本仓库采用以下策略稳定释放空间：

使用 /mnt 作为编译工作目录

显式清理无用软件与缓存


2️⃣ 检测 make defconfig 后被取消的包

make defconfig 的一个特点是：

feeds 中不存在 / 条件不满足 / 架构不匹配的包会被直接移除，但不会报错

本仓库提供脚本，在 make defconfig 后：

判断包是否：

=y

is not set

完全不存在于 .config

输出清晰状态，避免“以为选了，其实没进固件”


3️⃣ 自动修复被 defconfig 取消的包（可选）默认只检测不修复（lede专用脚本auto-fix-packages.sh）（immortalwrt、openwrt专用脚本check-packages-status.sh）默认在yml中注释

针对 确认存在于 feeds 中，但被 defconfig 取消的包，
提供自动修复脚本：

自动写回 .config

再次执行 make defconfig 规范化

若仍失败 → CI 直接中断（gating）


🚨 为什么一定要做 defconfig 校验？（提前知道插件有没有少）

如果你曾遇到：

固件里没 LuCI

插件没进固件却没报错

CI 成功但功能缺失

99% 是 defconfig 静默丢包






📂 目录结构说明https://github.com/B-blaow/AutoBuild-OpenWrt/blob/main/DirectoryStructure


