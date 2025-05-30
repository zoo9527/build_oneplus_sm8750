#!/bin/bash
info() {
  tput setaf 3  
  echo "[INFO] $1"
  tput sgr0
}
while true; do
  info "请选择需要编译的机型："
  info "1) oneplus_ace5_pro"
  info "2) oneplus_13"
  read -p "请输入对应数字: " choice
  case "$choice" in
    1)
      export XML_FEIL="oneplus_ace5_pro"
      info "选择的机型：$XML_FEIL"
      export BUILD_TIME="2024-12-04 02:11:16 UTC"
      break
      ;;
    2)
      export XML_FEIL="oneplus_13"
      info "选择的机型：$XML_FEIL"
      export BUILD_TIME="2024-12-17 23:36:49 UTC"
      break
      ;;
    *)
      info "❌ 无效选择，请输入对应数字。"
      ;;
  esac
done

# 原始内核名称
export KERNEL_NAME="-android15-8-g013ec21bba94-abogki383916444"

# 提示用户输入后缀（最多11个字符），可为空
read -p "请输入内核名称后缀 限11个字符（回车默认使用原始内核名）: " kernel_suffix
kernel_suffix=${kernel_suffix:0:11}  # 限制最多11个字符

# 如果用户有输入，则加上 -，否则保留原值
if [[ -n "$kernel_suffix" ]]; then
  export KERNEL_NAME="${KERNEL_NAME}-${kernel_suffix}"
fi

echo "最终的内核名称为：6.6.30-$KERNEL_NAME"
echo "构建时间为：$BUILD_TIME"
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
sudo apt install  -y zip

#下载repo并移动至bin目录给予权限
info "下载repo并给予权限"
curl https://storage.googleapis.com/git-repo-downloads/repo > $HOME/build_oneplus_sm8750/repo
chmod a+x $HOME/build_oneplus_sm8750/repo
sudo mv $HOME/build_oneplus_sm8750/repo /usr/local/bin/repo

#创建内核工作目录并克隆源码
info "正在创建工作目录并拉取源码"
mkdir build_kernel && cd build_kernel
repo init -u https://github.com/showdo/kernel_manifest.git -b refs/heads/oneplus/sm8750 -m ${XML_FEIL}.xml --depth=1
#同步内核源码
repo --trace sync -c -j$(nproc --all) --no-tags
#删除ABI保护符
rm kernel_platform/common/android/abi_gki_protected_exports_* || info "No File"
rm kernel_platform/msm-kernel/android/abi_gki_protected_exports_* || info "No File"

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
cd $HOME/build_oneplus_sm8750/build_kernel
git clone https://gitlab.com/simonpunk/susfs4ksu.git -b gki-android15-6.6
git clone https://github.com/ShirkNeko/SukiSU_patch.git
cd $HOME/build_oneplus_sm8750/build_kernel/kernel_platform
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
    cd $HOME/build_oneplus_sm8750/build_kernel/kernel_platform/common
    
    # 复制补丁文件
    cp ../../SukiSU_patch/other/zram/zram_patch/6.6/lz4kd.patch ./
    
    # 应用补丁
    patch -p1 -F 3 < lz4kd.patch || true
    info "LZ4补丁修补完成"

else
    info "未启用LZ4，跳过修补LZ4"
fi

echo "开始编译设备树节点"

# 设置路径变量
KERNEL_DIR="$HOME/build_oneplus_sm8750/build_kernel/kernel_platform/common/drivers"
PATCH_FILE="${KERNEL_DIR}/hmbird_patch.c"
MAKEFILE="${KERNEL_DIR}/Makefile"

# 创建补丁文件
mkdir -p "$KERNEL_DIR"
cat << 'EOF' > "$PATCH_FILE"
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
            kfree(new_prop->value);
            kfree(new_prop);
            of_node_put(ver_np);
            return 0;
        }

        if (of_add_property(ver_np, new_prop) != 0) {
            pr_info("hmbird_patch: of_add_property failed\n");
            kfree(new_prop->value);
            kfree(new_prop);
            of_node_put(ver_np);
            return 0;
        }

        pr_info("hmbird_patch: success from HMBIRD_OGKI to HMBIRD_GKI\n");
    } else {
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

# 确保 Makefile 包含编译目标
if ! grep -q "hmbird_patch.o" "$MAKEFILE"; then
    echo "obj-y += hmbird_patch.o" >> "$MAKEFILE"
    info "已添加 hmbird_patch.o 到 Makefile"
else
    info "Makefile 中已包含 hmbird_patch.o"
fi

# 返回根目录提交修改
cd $HOME/build_oneplus_sm8750/build_kernel/kernel_platform || exit 1
git add -A
git commit -m "Add HMBird GKI patch" || info "没有变化需要提交"

info "[完成] 提交设备数节点结束"


# 进入工作目录
cd $HOME/build_oneplus_sm8750/build_kernel/kernel_platform

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
  cd $HOME/build_oneplus_sm8750/build_kernel/kernel_platform
  
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
cd $HOME/build_oneplus_sm8750/build_kernel/kernel_platform/ || exit
sed -i 's/res="\$res\$(cat "\$file")"/res="-android15-8-g013ec21bba94-abogki383916444"/g' ./common/scripts/setlocalversion
sudo sed -i "s/-android15-8-g013ec21bba94-abogki383916444/$KERNEL_NAME/g" ./common/scripts/setlocalversion


# 检查是否启用 风驰
if [ "$KERNEL_SCX" == "1" ]; then
    info "开启风驰内核"
    # 进入目标目录
    cd $HOME/build_oneplus_sm8750/build_kernel/kernel_platform/ || exit

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
info "开始修改构建时间"
SOURCE_DATE_EPOCH=$(date -d "$KERNEL_TIME" +%s)

#将时间戳设为环境变量
export SOURCE_DATE_EPOCH=${SOURCE_DATE_EPOCH}
info "已设置构建时间为${BUILD_TIME}" 
# 进入工作目录
cd $HOME/build_oneplus_sm8750/build_kernel/kernel_platform || exit

# 执行构建命令
info "开始构建编译内核"
tools/bazel run --config=fast --config=stamp --lto=thin //common:kernel_aarch64_dist -- --dist_dir=dist

info "内核编译成功"


# 进入构建输出目录
info "打包内核中..."
cd $HOME/build_oneplus_sm8750/build_kernel/kernel_platform/dist/ || exit

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
cp $HOME/build_oneplus_sm8750/build_kernel/kernel_platform/dist/Image ./AnyKernel3/

cd $HOME/build_oneplus_sm8750/build_kernel/kernel_platform/dist/AnyKernel3

rm -rf README.md

zip -r $HOME/build_oneplus_sm8750/build_kernel/kernel_platform/dist/AnyKernel3_${KSUVER}_${XML_FEIL}_SuKiSu.zip .


export DEST_PATH="/mnt/c/kernel"
if [ -d "$DEST_PATH" ]; then
  rm -rf "$DEST_PATH"
  info "kernel文件夹已存在 正在覆盖"
fi

mkdir -p "$DEST_PATH"

cp $HOME/build_oneplus_sm8750/build_kernel/kernel_platform/dist/AnyKernel3_${KSUVER}_${XML_FEIL}_SuKiSu.zip $DEST_PATH

find $HOME/build_oneplus_sm8750/build_kernel/kernel_platform/dist/ -type f \( -iname "*img*" -o -iname "Image" -o -iname "*.img" -o -iname "*.tar" -o -iname "*.gz" \) -exec cp {} "$DEST_PATH" \;


info "关于本次编译后的所有文件已导出至 C盘 kernel 文件夹"
