#!/bin/bash
cd kernel
BUILD_SUFFIX=""

if [ $1 == "MIUI" ]; 
then
  echo "Reverting LMK"
  git revert 379824bb737dd658bc69cd8edb773eb3405c77a7..1ab230774f638f0fa732bed4a005493638e15cb8
  BUILD_SUFFIX="${BUILD_SUFFIX}-MIUI"
else
  BUILD_SUFFIX="${BUILD_SUFFIX}-AOSP"
fi
if [ $2 == "KSU" ]; then
  BUILD_SUFFIX="${BUILD_SUFFIX}-KSU"
  curl -LSs "https://raw.githubusercontent.com/tiann/KernelSU/main/kernel/setup.sh" | bash -
else
  BUILD_SUFFIX="${BUILD_SUFFIX}-NOSU"
fi

TARGET_CLANG="clang-r450784e"
TOOLCHAIN_PATHS="/home/jenkins-compile/tools/linux-x86/${TARGET_CLANG}/bin:/home/jenkins-compile/tools/aarch64-linux-android-4.9/bin:/home/jenkins-compile/tools/arm-linux-androideabi-4.9/bin"

export PATH=${TOOLCHAIN_PATHS}:${PATH}

make O=out ARCH=arm64 vendor/spes-perf_defconfig
make -j$(nproc --all) O=out \
                      ARCH=arm64 \
                      CC=clang \
                      CLANG_TRIPLE=aarch64-linux-gnu- \
                      CROSS_COMPILE=aarch64-linux-android- \
                      CROSS_COMPILE_ARM32=arm-linux-androideabi-

