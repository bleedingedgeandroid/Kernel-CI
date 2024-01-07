#!/bin/bash
cd kernel
BUILD_SUFFIX=""
KVERSION=$(cat Makefile | grep -Pe "VERSION|LEVEL" | head -3 | awk '{print $3}' | paste -sd ".")


if [ $1 == "MIUI" ]; 
then
  echo "Reverting LMK"
  git revert 379824bb737dd658bc69cd8edb773eb3405c77a7..1ab230774f638f0fa732bed4a005493638e15cb8
  BUILD_SUFFIX="${BUILD_SUFFIX}-MIUI"
else
  BUILD_SUFFIX="${BUILD_SUFFIX}-AOSP"
fi
if [ $2 == "KSU" ]; then
  echo "Enabling KSU"
  BUILD_SUFFIX="${BUILD_SUFFIX}-KSU"
  curl -LSs "https://raw.githubusercontent.com/tiann/KernelSU/main/kernel/setup.sh" | bash -
else
  BUILD_SUFFIX="${BUILD_SUFFIX}-NOSU"
fi

TARGET_CLANG="clang-r450784e"
TOOLCHAIN_PATHS="/home/jenkins-compile/tools/linux-x86/${TARGET_CLANG}/bin:/home/jenkins-compile/tools/aarch64-linux-android-4.9/bin:/home/jenkins-compile/tools/arm-linux-androideabi-4.9/bin"

export PATH=${TOOLCHAIN_PATHS}:${PATH}

echo "making defconfig"
make O=out ARCH=arm64 vendor/spes-perf_defconfig
echo "making kernel"
make -j$(nproc --all) O=out \
                      ARCH=arm64 \
                      CC=clang \
                      CLANG_TRIPLE=aarch64-linux-gnu- \
                      CROSS_COMPILE=aarch64-linux-android- \
                      CROSS_COMPILE_ARM32=arm-linux-androideabi-

cd ..
cp kernel/out/arch/arm64/boot/Image.gz AnyKernel3-spes/
cp kernel/out/arch/arm64/boot/dtbo.img AnyKernel3-spes/

echo "Zipping"

cd AnyKernel3-spes/
sed -i 's/INTERNAL_KVERSION/'"${KVERSION}"'/' anykernel.sh
sed -i 's/CIBUILD/'"${BUILD_NUMBER}${BUILD_SUFFIX}/" anykernel.sh

zip -r9 ../Murali680-${BUILD_NUMBER}-$KVERSION${BUILD_SUFFIX}-PugzAreCuteCI.zip * -x .git README.md *placeholder 
echo "Done"

cd ..

chmod +x notify.sh
./notify.sh