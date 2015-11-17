#!/bin/bash

export ARCH=arm
export CROSS_COMPILE=/opt/toolchains/arm-eabi-4.7/bin/arm-eabi-

mkdir output

make -C $(pwd) O=output apq8084_sec_defconfig VARIANT_DEFCONFIG=apq8084_sec_trlte_tmo_defconfig SELINUX_DEFCONFIG=selinux_defconfig
make -C $(pwd) O=output

cp output/arch/arm/boot/Image $(pwd)/arch/arm/boot/zImage