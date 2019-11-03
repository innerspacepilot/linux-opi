#!/bin/bash

OUTPUT=output/usr
WORKDIR=`pwd`
export CROSS_COMPILE=arm-none-eabi-
export ARCH=arm

msgexit()
{
	echo "Command failed!!!"
	exit 1
}

git submodule update -f

# avoid + in kernel version
touch .scmversion

rm -fr output

if [ ! -f .config ]; then cp orange-5.3.config .config; fi

make -j32 oldconfig
make -j32 dtbs zImage modules headers_check || msgexit

mkdir -p output/boot || msgexit
mkdir -p output/usr || msgexit

make -j32 INSTALL_MOD_PATH=$OUTPUT modules_install || msgexit
make -j32 INSTALL_HDR_PATH=$OUTPUT headers_install || msgexit

EXTRA_DIR="$OUTPUT/lib/modules/`ls -1 $OUTPUT/lib/modules`/extra"

mkdir $EXTRA_DIR || msgexit

( cd extra/mali/driver/src/devicedrv/mali; make -j32 KDIR=$WORKDIR MALI_PLATFORM_FILES=platform/sunxi/sunxi.c GIT_REV="" EXTRA_CFLAGS="-DMALI_FAKE_PLATFORM_DEVICE=1 -DCONFIG_MALI_DMA_BUF_MAP_ON_ATTACH -DCONFIG_MALI400=1 -DCONFIG_MALI450=1 -DCONFIG_MALI470=1" CONFIG_MALI400=m CONFIG_MALI450=m CONFIG_MALI470=m CONFIG_MALI_DMA_BUF_MAP_ON_ATTACH=y ) || msgexit
cp extra/mali/driver/src/devicedrv/mali/mali.ko $EXTRA_DIR || msgexit

( cd extra/rtl8189; make -j32 KSRC=$WORKDIR ) || msgexit
cp extra/rtl8189/8189fs.ko $EXTRA_DIR || msgexit

cp arch/arm/boot/zImage output/boot || msgexit
cp arch/arm/boot/dts/sun8i-h3-orangepi-pc-plus.dtb output/boot/pc-plus.dtb || msgexit

( cd output; fakeroot tar czvf ../kernel-package.tar.gz . ) || msgexit

