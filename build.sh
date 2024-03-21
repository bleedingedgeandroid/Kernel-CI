#!/bin/bash
echo "Weclome to kernel builder! Currently building ${DEFCONFIG} $1 $2"
DEFCONFIG="vendor/spes-perf_defconfig"

if ! [ -d kernel ];
then
  echo "Kernel has not been cloned. Cloning into kernel."
  git clone https://github.com/muralivijay/kernel_xiaomi_sm6225.git kernel
  echo "Kernel cloned successfully."
else
  echo "Kernel was cloned before. Pulling remote changes"
  cd kernel
  git pull
  cd ..
  echo "Pulled remote changes."
fi
cd kernel

BUILD_SUFFIX=""
KVERSION=$(cat Makefile | grep -Pe "VERSION|LEVEL" | head -3 | awk '{print $3}' | paste -sd ".")

# NOT NEEDED FOR ALL KERNELS!
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
CONFIG_KPROBE_EVENTS=y' >> arch/arm64/configs/vendor/spes-perf_defconfig
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

if ! [ -d aosp_clang ];
then
  echo "Clang not cloned, cloning."
  git clone https://gitlab.com/ThankYouMario/android_prebuilts_clang-standalone.git aosp_clang
  echo "Clang cloned successfully"
else
  echo "Clang was cloned before. Pulling remote changes."
  cd aosp_clang
  git pull
  cd ..
  echo "Pulled remote changes for clang."
fi

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

cp kernel/out/arch/arm64/boot/Image.gz AnyKernel3/
cp kernel/out/arch/arm64/boot/dtbo.img AnyKernel3/

echo "Creating flashable zip."

if ! [ -d AnyKernel3 ];
then
  echo "AnyKernel was not cloned, cloning."
  git clone https://github.com/bleedingedgeandroid/Anykernel3-spes.git AnyKernel3
  echo "AnyKernel cloned into AnyKernel3."
else
  echo "AnyKernel was cloned brfore. Pulling remote changes."
  cd AnyKernel3
  git pull
  cd ..
  echo "Pulled remote changes for AnyKernel."
fi

rm *.zip
cd AnyKernel3/

sed -i 's/INTERNAL_KVERSION/'"${KVERSION}"'/' anykernel.sh
sed -i 's/CIBUILD/'"${BUILD_NUMBER}${BUILD_SUFFIX}/" anykernel.sh

zip -r9 ../Murali680-${BUILD_NUMBER}-${KVERSION}${BUILD_SUFFIX}-PugzAreCuteCI.zip * -x .git README.md *placeholder 
echo "Done"

cd ..