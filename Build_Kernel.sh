#!/bin/bash
info() {
  tput setaf 3  
  echo "[INFO] $1"
  tput sgr0
}
BUILD_DIR="$HOME/build_oneplus_sm8750"
while true; do
  info "请选择需要编译的机型："
  info "1) oneplus_ace5_pro"
  info "2) oneplus_13"
  read -p "请输入对应数字: " choice
  case "$choice" in
    1)
      export XML_FEIL="oneplus_ace5_pro"
      info "选择的机型：$XML_FEIL"
      export BUILD_TIME="Wed Dec 4 02:11:46 UTC 2024"
      break
      ;;
    2)
      export XML_FEIL="oneplus_13"
      info "选择的机型：$XML_FEIL"
      export BUILD_TIME="Wed Dec 17 23:36:49 UTC 2024"
      break
      ;;
    *)
      info "❌ 无效选择，请输入对应数字。"
      ;;
  esac
done

# 原始内核名称
export KERNEL_NAME="-android15-8-g013ec21bba94-abogki383916444"

# 是否开启 KPM
while true; do
  read -p "是否开启 KPM？(1=开启, 0=关闭): " kpm
  if [[ "$kpm" == "0" || "$kpm" == "1" ]]; then
    export KERNEL_KPM="$kpm"
    break
  else
    info "❌ 请输入有效的选项：0 或 1。"
  fi
done

# 是否开启 风驰内核
while true; do
  read -p "是否开启 风驰内核？(1=开启, 0=关闭): " scx
  if [[ "$scx" == "0" || "$scx" == "1" ]]; then
    export KERNEL_SCX="$scx"
    break
  else
    info "❌ 请输入有效的选项：0 或 1。"
  fi
done

# 是否开启 LZ4KD
while true; do
  read -p "是否开启 LZ4KD？(1=开启, 0=关闭): " lz4
  if [[ "$lz4" == "0" || "$lz4" == "1" ]]; then
    export KERNEL_LZ4="$lz4"
    break
  else
    info "❌ 请输入有效的选项：0 或 1。"
  fi
done

info "请确认您要编译的参数，如不符合请按下Ctrl+C取消运行："
info "选择机型：${XML_FEIL}"
info "内核名称：${KERNEL_NAME}"

#设置Git用户名与邮箱
git config --global user.name "Q1udaoyu"
git config --global user.email "sucisama2888@gmail.com"

#安装环境依赖
info "安装环境依赖"
sudo apt update && sudo apt upgrade -y
sudo apt install -y python3 git curl
sudo apt install -y python3 git curl ccache
sudo apt install  -y zip

#!/bin/bash

# 更新系统并安装依赖
info "更新系统并安装依赖..."
sudo apt update && sudo apt upgrade -y
sudo apt install -y python3 git curl ccache

# 恢复 ccache
info "显示 ccache 状态..."
mkdir -p $HOME/.ccache
ccache -s
info "清除ccache缓存..."
# 清空缓存
ccache -C

# 安装 repo 工具
info "安装 repo 工具..."
curl -o /usr/local/bin/repo https://storage.googleapis.com/git-repo-downloads/repo
sudo chmod a+x /usr/local/bin/repo

# 初始化 repo 并同步
info "初始化 repo 并同步..."
mkdir -p build_kernel
cd build_kernel
repo init -u https://github.com/JiuGeFaCai/kernel_manifest.git -b refs/heads/oneplus/sm8750 -m ${XML_FEIL}.xml --depth=1
repo --trace sync -c -j$(nproc --all) --no-tags

# 删除不需要的导出文件
info "删除非必要的导出文件..."
rm -f kernel_platform/common/android/abi_gki_protected_exports_* || echo "No protected exports!"
rm -f kernel_platform/msm-kernel/android/abi_gki_protected_exports_* || echo "No protected exports!"

#拉取SukiSU源码并设置版本号
info "开始拉取SukiSU并写入版本"
cd kernel_platform
curl -LSs "https://raw.githubusercontent.com/ShirkNeko/SukiSU-Ultra/main/kernel/setup.sh" | bash -s susfs-dev

cd ./KernelSU
KSU_VERSION=$(expr $(/usr/bin/git rev-list --count main) "+" 10606)
echo "KSUVER=$KSU_VERSION" >> .env
source .env

export KSU_VERSION=$KSU_VERSION

sed -i "s/DKSU_VERSION=12800/DKSU_VERSION=${KSU_VERSION}/" kernel/Makefile

#写入SUSFS补丁
info "开始修补SUSFS补丁"
cd $BUILD_DIR/build_kernel
git clone https://gitlab.com/simonpunk/susfs4ksu.git -b gki-android15-6.6
git clone https://github.com/ShirkNeko/SukiSU_patch.git
cd $BUILD_DIR/build_kernel/kernel_platform
cp ../susfs4ksu/kernel_patches/50_add_susfs_in_gki-android15-6.6.patch ./common/
cp ../susfs4ksu/kernel_patches/fs/* ./common/fs/
cp ../susfs4ksu/kernel_patches/include/linux/* ./common/include/linux/

# 复制lz4k
cp -r ../SukiSU_patch/other/zram/lz4k/include/linux/* ./common/include/linux
cp -r ../SukiSU_patch/other/zram/lz4k/lib/* ./common/lib
cp -r ../SukiSU_patch/other/zram/lz4k/crypto/* ./common/crypto
cp -r ../SukiSU_patch/other/zram/lz4k_oplus ./common/lib/
cd ./common
sed -i 's/-32,12 +32,38/-32,11 +32,37/g' 50_add_susfs_in_gki-android15-6.6.patch
sed -i '/#include <trace\/hooks\/fs.h>/d' 50_add_susfs_in_gki-android15-6.6.patch

# 应用补丁
patch -p1 < 50_add_susfs_in_gki-android15-6.6.patch || true
# 复制补丁文件
cp ../../SukiSU_patch/hooks/syscall_hooks.patch ./

# 应用补丁
patch -p1 -F 3 < syscall_hooks.patch

# 输出完成信息
info "SUSFS补丁修补完成"



if [ "${KERNEL_LZ4}" = "1" ]; then
    info "开始修补LZ4补丁"
    cd $BUILD_DIR/build_kernel/kernel_platform/common
    
    # 复制补丁文件
    cp ../../SukiSU_patch/other/zram/zram_patch/6.6/lz4kd.patch ./
    
    # 应用补丁
    patch -p1 -F 3 < lz4kd.patch || true
    info "LZ4补丁修补完成"

else
    info "未启用LZ4，跳过修补LZ4"
fi

#!/bin/bash

# 进入内核源码的 drivers 目录
cd $BUILD_DIR/build_kernel//kernel_platform/common/drivers

# 创建 hmbird_patch.c 文件
cat << 'EOF' > hmbird_patch.c
#include <linux/init.h>
#include <linux/module.h>
#include <linux/of.h>
#include <linux/slab.h>
#include <linux/string.h>

static int __init hmbird_patch_init(void)
{
    struct device_node *ver_np;
    const char *type;
    int ret;

    ver_np = of_find_node_by_path("/soc/oplus,hmbird/version_type");
    if (!ver_np) {
         pr_info("hmbird_patch: version_type node not found\n");
         return 0;
    }

    ret = of_property_read_string(ver_np, "type", &type);
    if (ret) {
         pr_info("hmbird_patch: type property not found\n");
         of_node_put(ver_np);
         return 0;
    }

    if (strcmp(type, "HMBIRD_OGKI")) {
         of_node_put(ver_np);
         return 0;
    }

    struct property *prop = of_find_property(ver_np, "type", NULL);
    if (prop) {
         struct property *new_prop = kmalloc(sizeof(*prop), GFP_KERNEL);
         if (!new_prop) {
              pr_info("hmbird_patch: kmalloc for new_prop failed\n");
              of_node_put(ver_np);
              return 0;
         }
         memcpy(new_prop, prop, sizeof(*prop));
         new_prop->value = kmalloc(strlen("HMBIRD_GKI") + 1, GFP_KERNEL);
         if (!new_prop->value) {
              pr_info("hmbird_patch: kmalloc for new_prop->value failed\n");
              kfree(new_prop);
              of_node_put(ver_np);
              return 0;
         }
         strcpy(new_prop->value, "HMBIRD_GKI");
         new_prop->length = strlen("HMBIRD_GKI") + 1;

         if (of_remove_property(ver_np, prop) != 0) {
              pr_info("hmbird_patch: of_remove_property failed\n");
              return 0;
         }
         if (of_add_property(ver_np, new_prop) != 0) {
              pr_info("hmbird_patch: of_add_property failed\n");
              return 0;
         }
         pr_info("hmbird_patch: success from HMBIRD_OGKI to HMBIRD_GKI\n");
    }
    else {
         pr_info("hmbird_patch: type property structure not found\n");
    }
    of_node_put(ver_np);
    return 0;
}

early_initcall(hmbird_patch_init);

MODULE_LICENSE("GPL");
MODULE_AUTHOR("reigadegr");
MODULE_DESCRIPTION("Forcefully convert HMBIRD_OGKI to HMBIRD_GKI.");
EOF

# 如果 Makefile 中没有添加该模块，则追加 obj-y += hmbird_patch.o
if ! grep -q "hmbird_patch.o" Makefile; then
    echo "obj-y += hmbird_patch.o" >> Makefile
fi

# 返回上一层目录
cd $BUILD_DIR/build_kernel

# 提交更改
git add -A
git commit -m "Add HMBird GKI patch" || true


# 进入工作目录
cd $BUILD_DIR/build_kernel/kernel_platform

# 配置项数组
CONFIGS=(
  "CONFIG_KSU=y"
  "CONFIG_KSU_SUSFS_SUS_SU=n"
  "CONFIG_KSU_MANUAL_HOOK=y"
  "CONFIG_KSU_SUSFS=y"
  "CONFIG_KSU_SUSFS_HAS_MAGIC_MOUNT=y"
  "CONFIG_KSU_SUSFS_SUS_PATH=y"
  "CONFIG_KSU_SUSFS_SUS_MOUNT=y"
  "CONFIG_KSU_SUSFS_AUTO_ADD_SUS_KSU_DEFAULT_MOUNT=y"
  "CONFIG_KSU_SUSFS_AUTO_ADD_SUS_BIND_MOUNT=y"
  "CONFIG_KSU_SUSFS_SUS_KSTAT=y"
  "CONFIG_KSU_SUSFS_SUS_OVERLAYFS=n"
  "CONFIG_KSU_SUSFS_TRY_UMOUNT=y"
  "CONFIG_KSU_SUSFS_AUTO_ADD_TRY_UMOUNT_FOR_BIND_MOUNT=y"
  "CONFIG_KSU_SUSFS_SPOOF_UNAME=y"
  "CONFIG_KSU_SUSFS_ENABLE_LOG=y"
  "CONFIG_KSU_SUSFS_HIDE_KSU_SUSFS_SYMBOLS=y"
  "CONFIG_KSU_SUSFS_SPOOF_CMDLINE_OR_BOOTCONFIG=y"
  "CONFIG_KSU_SUSFS_OPEN_REDIRECT=y"
  "CONFIG_CRYPTO_LZ4HC=y"
  "CONFIG_CRYPTO_LZ4K=y"
  "CONFIG_CRYPTO_LZ4KD=y"
  "CONFIG_CRYPTO_842=y"
)

# 将配置项添加到 gki_defconfig
info "开始写入GKI配置"
for CONFIG in "${CONFIGS[@]}"; do
  echo "$CONFIG" >> ./common/arch/arm64/configs/gki_defconfig
done
info "GKI配置写入完成"
# 删除 check_defconfig
sudo sed -i 's/check_defconfig//' ./common/build.config.gki

# 提交更改到 Git
cd common
git add -A && git commit -a -m "BUILD Kernel"

# 检查 是否开启KPM
if [ "$KERNEL_KPM" = "1" ]; then
  # 进入工作目录
  info "开始配置KPM"
  cd $BUILD_DIR/build_kernel/kernel_platform
  
  # 添加 KPM 配置项
  echo "CONFIG_KPM=y" >> ./common/arch/arm64/configs/gki_defconfig
  
  # 删除 check_defconfig
  sudo sed -i 's/check_defconfig//' ./common/build.config.gki
  
  # 提交更改到 Git
  cd common
  git add -A && git commit -a -m "BUILD Kernel"
  info "KPM配置完成"
else
  info "KPM 配置未启用，跳过配置"
fi

# 修改内核名称
cd $BUILD_DIR/build_kernel/kernel_platform/ || exit

# 删除 setlocalversion 中的 ${scm_version} 字符串
sed -i 's/${scm_version}//' ./common/scripts/setlocalversion

# 将 gki_defconfig 中的 -4k 替换
sudo sed -i "s/-4k/${KERNEL_NAME}/g" ./common/arch/arm64/configs/gki_defconfig

#备用修改name
#sudo sed -i "s/\(.*\)-4k$/\1-${KERNEL_NAME}-4k/" ./common/arch/arm64/configs/gki_defconfig

# 检查是否启用 风驰
if [ "$KERNEL_SCX" == "1" ]; then
    info "开启风驰内核"
    # 进入目标目录
    cd $BUILD_DIR/build_kernel/kernel_platform/ || exit

    # 克隆 sched_ext 仓库
    git clone https://github.com/showdo/sched_ext.git

    # 复制文件到风驰目录
    cp -r ./sched_ext/* ./common/kernel/sched

    # 删除 .git 目录
    rm -rf ./sched_ext/.git

    # 进入风驰目录以确保风驰替换成功
    cd common/kernel/sched || exit
    info "风驰内核开启完成"
else
    info "未启用 风驰内核，跳过修补"
fi

# 使用 date 命令将日期转换为 Unix 时间戳
info "还原官方构建时间"
SOURCE_DATE_EPOCH=$(date -d "$BUILD_TIME" +%s)

#将时间戳设为环境变量
export KBUILD_BUILD_TIMESTAMP="${BUILD_TIME}"

info "构建时间写入$KBUILD_BUILD_TIMESTAMP"

# 设置工具链路径
export PATH="$BUILD_DIR/build_kernel/kernel_platform/prebuilts/clang/host/linux-x86/clang-r510928/bin:$PATH"
export PATH="/usr/lib/ccache:$PATH"

# 安装依赖
sudo apt update
sudo apt install -y libelf-dev

# 切换到内核源码目录
cd $BUILD_DIR/build_kernel/kernel_platform/common

# 执行内核构建
make -j$(nproc --all) LLVM=1 ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- CC=clang \
     RUSTC=../../prebuilts/rust/linux-x86/1.73.0b/bin/rustc PAHOLE=../../prebuilts/kernel-build-tools/linux-x86/bin/pahole \
     LD=ld.lld HOSTLD=ld.lld O=out KCFLAGS+=-Wno-error gki_defconfig all


# 进入构建输出目录
info "打包内核中..."
cd $BUILD_DIR/build_kernel/kernel_platform/dist/ || exit

# 下载并设置补丁工具
curl -LO https://github.com/ShirkNeko/SukiSU_KernelPatch_patch/releases/download/0.11-beta/patch_linux
chmod +x patch_linux

# 执行补丁工具
./patch_linux

# 删除旧的 Image 文件
rm -f Image

# 将 oImage 重命名为 Image
mv oImage Image

# 检查 AnyKernel3 文件夹是否存在，如果不存在则创建
if [ ! -d "./AnyKernel3" ]; then
  info "编译AnyKernel3刷入包"
  mkdir ./AnyKernel3
fi

# 克隆 AnyKernel3 仓库
git clone https://github.com/HanKuCha/AnyKernel3.git --depth=1

# 删除 AnyKernel3 中的 .git 目录和 push.sh 文件
rm -rf ./AnyKernel3/.git
rm -rf ./AnyKernel3/push.sh

# 将生成的内核镜像文件拷贝到 AnyKernel3 目录
cp $BUILD_DIR/build_kernel/kernel_platform/dist/Image ./AnyKernel3/

cd $BUILD_DIR/build_kernel/kernel_platform/dist/AnyKernel3

rm -rf README.md

zip -r $BUILD_DIR/build_kernel/kernel_platform/dist/AnyKernel3_${KSUVER}_${XML_FEIL}_SuKiSu.zip .


export DEST_PATH="/mnt/c/kernel"
if [ -d "$DEST_PATH" ]; then
  rm -rf "$DEST_PATH"
  info "kernel文件夹已存在 正在覆盖"
fi

mkdir -p "$DEST_PATH"

cp $BUILD_DIR/build_kernel/kernel_platform/dist/AnyKernel3_${KSUVER}_${XML_FEIL}_SuKiSu.zip $DEST_PATH

find $BUILD_DIR/build_kernel/kernel_platform/dist/ -type f \( -iname "*img*" -o -iname "Image" -o -iname "*.img" -o -iname "*.tar" -o -iname "*.gz" \) -exec cp {} "$DEST_PATH" \;


info "关于本次编译后的所有文件已导出至 C盘 kernel 文件夹"
