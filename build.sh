#!/bin/bash
DEFCONFIG="vendor/spes-perf_defconfig"
KERNEL="https://github.com/muralivijay/kernel_xiaomi_sm6225.git"
ANYKERNEL="https://github.com/osm0sis/AnyKernel3.git"

source utils.sh

echo "Weclome to kernel builder! Currently building ${KERNEL} ${DEFCONFIG} $1 $2 EROFS: $3"

clone_or_pull $KERNEL "kernel" "Kernel"
cd kernel

BUILD_SUFFIX=""
KERNEL_VERSION=$(cat Makefile | grep -Pe "VERSION|LEVEL" | head -3 | awk '{print $3}' | paste -sd ".")

# The following patches are kernel-dependant. The following are for the  Murali680 kernel for spes(Redmi Note 11/NFC).

# Check if SLMK is enabled. MIUI wont boot witk SLMK enabled.
LMK_TEST=$(cat arch/arm64/configs/$DEFCONFIG | grep CONFIG_ANDROID_SIMPLE_LMK -q) # 0=SLMK, 1=CLO LMK

if [ $1 == "MIUI" ]; 
then
  echo "Reverting SLMK for MIUI Builds"
  if [ $LMK_TEST ];
  then
  echo "SLMK was not reverted previously. Reverting now."
  git revert 379824bb737dd658bc69cd8edb773eb3405c77a7..1ab230774f638f0fa732bed4a005493638e15cb8
  echo "SLMK reverted."
  fi
  BUILD_SUFFIX="${BUILD_SUFFIX}-MIUI"
else
  if [ $LMK_TEST ];
  then
  echo "Something went wrong! SLMK has been reverted on an AOSP build."
  exit -1
  fi
  BUILD_SUFFIX="${BUILD_SUFFIX}-AOSP"
fi

if [ $2 == "KSU" ]; then
  echo "Enabling KSU"
  if ! [ -d KernelSU ];
  then
  echo "KSU was not previously enabled. Enabling"
  echo 'CONFIG_KPROBES=y
CONFIG_HAVE_KPROBES=y
CONFIG_KPROBE_EVENTS=y' >> arch/arm64/configs/$DEFCONFIG
  curl -LSs "https://raw.githubusercontent.com/tiann/KernelSU/main/kernel/setup.sh" | bash -
  echo "KSU enabled."
  fi
  BUILD_SUFFIX="${BUILD_SUFFIX}-KSU"
else
  if [ -d KernelSU ];
  then
  echo "Something went wrong! KSU is existing on Non-KSU build."
  exit -1
  fi
  BUILD_SUFFIX="${BUILD_SUFFIX}-NOSU"
fi

if [ $3 == "YES" ]; then
  echo "Enabling EROFS"
  if ! [ $(grep "CONFIG_EROFS_FS" arch/arm64/configs/${DEFCONFIG} | echo $?) -eq "0" ];
  then
  echo "EROFS was not previously enabled. Enabling"
  echo 'CONFIG_EROFS_FS=y' >> arch/arm64/configs/$DEFCONFIG
  echo "EROFS enabled."
  fi
  BUILD_SUFFIX="${BUILD_SUFFIX}-EROFS"
else
  if [ $(grep "CONFIG_EROFS_FS" arch/arm64/configs/${DEFCONFIG} | echo $?) -eq "0" ];
  then
  echo "Something went wrong! EROFS is existing on Non-EROFS build."
  exit -1
  fi
  BUILD_SUFFIX="${BUILD_SUFFIX}-NORMALFS"
fi


clone_or_pull "https://gitlab.com/ThankYouMario/android_prebuilts_clang-standalone.git" "aosp_clang" "Toolchain"

TOOLCHAIN_PATHS="$(pwd)/aosp_clang/bin/"
export PATH=${TOOLCHAIN_PATHS}:${PATH}

echo "Making config for ${DEFCONFIG}"
make O=out ARCH=arm64 $DEFCONFIG
echo "Building kernel for ${DEFCONFIG}"
make -j$(nproc --all) O=out \
                      ARCH=arm64 \
                      CC=clang \
                      LD=ld.lld \
                      AS=llvm-as \
                      AR=llvm-ar \
                      NM=llvm-nm \
                      OBJCOPY=llvm-objcopy \
                      OBJDUMP=llvm-objdump \
                      STRIP=llvm-strip \
                      LLVM=1 \
                      LLVM_IAS=1 \
                      CLANG_TRIPLE=aarch64-linux-gnu- \
                      CROSS_COMPILE=aarch64-linux-gnu- \
                      CROSS_COMPILE_ARM32=arm-linux-gnueabi-
cd ..
echo "Kernel built. Copying Image.gz and DTBO"

clone_or_pull $ANYKERNEL "AnyKernel3" "AnyKernel"

cp kernel/out/arch/arm64/boot/Image.gz AnyKernel3/
cp kernel/out/arch/arm64/boot/dtbo.img AnyKernel3/
cp patches/anykernel.sh AnyKernel3/

echo "Creating flashable zip."

rm *.zip
cd AnyKernel3/

sed -i 's/CI_KERNEL_VERSION/'"${KERNEL_VERSION}"'/' anykernel.sh
sed -i 's/CI_BUILD_NUMBER/'"${BUILD_NUMBER}${BUILD_SUFFIX}/" anykernel.sh

zip -r9 ../Murali680-${BUILD_NUMBER}-${KERNEL_VERSION}${BUILD_SUFFIX}-PugzAreCuteCI.zip * -x .git README.md *placeholder 
echo "Done"

cd ..