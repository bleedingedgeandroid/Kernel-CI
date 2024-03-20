#!/bin/bash
if ! [ -d kernel ];
then
  echo "Kernel not cloned, cloning."
  git clone https://github.com/muralivijay/kernel_xiaomi_sm6225.git kernel
else
  echo "Kernel cloned. Pulling"
  cd kernel
  git pull
  cd ..
fi
cd kernel
echo $(pwd)

BUILD_SUFFIX=""
KVERSION=$(cat Makefile | grep -Pe "VERSION|LEVEL" | head -3 | awk '{print $3}' | paste -sd ".")

LMK_TEST=$(cat arch/arm64/configs/vendor/spes-perf_defconfig | grep CONFIG_ANDROID_SIMPLE_LMK -q) # 0=SLMK, 1=CLO LMK

if [ $1 == "MIUI "]; 
then
  if [ $LMK_TEST ];
  then
  echo "Reverting LMK"
  git revert 379824bb737dd658bc69cd8edb773eb3405c77a7..1ab230774f638f0fa732bed4a005493638e15cb8
  BUILD_SUFFIX="${BUILD_SUFFIX}-MIUI"
  fi
else
  if [ $LMK_TEST ];
  then
  echo "BUILD CRITICAL FAIL! LMK REVERT ON AOSP!"
  exit -1
  BUILD_SUFFIX="${BUILD_SUFFIX}-AOSP"
  fi
fi

if [ $2 == "KSU" ]; then
  echo "Enabling KSU"
  if ! [ -d KernelSU ];
  then
  BUILD_SUFFIX="${BUILD_SUFFIX}-KSU"
  echo 'CONFIG_KPROBES=y
CONFIG_HAVE_KPROBES=y
CONFIG_KPROBE_EVENTS=y' >> arch/arm64/configs/vendor/spes-perf_defconfig
  curl -LSs "https://raw.githubusercontent.com/tiann/KernelSU/main/kernel/setup.sh" | bash -
  fi
else
  if [ -d KernelSU ];
  then
  echo "BUILD CRITICAL FAIL! KSU ON NOSU!"
  exit -1
  fi
  BUILD_SUFFIX="${BUILD_SUFFIX}-NOSU"
fi

if ! [ -d aosp_clang ];
then
  echo "CLANG not cloned, cloning."
  git clone https://gitlab.com/ThankYouMario/android_prebuilts_clang-standalone.git aosp_clang
else
  echo "CLANG cloned. Pulling"
  cd aosp_clang
  git pull
  cd ..
fi
TOOLCHAIN_PATHS="$(pwd)/aosp_clang/bin/"

export PATH=${TOOLCHAIN_PATHS}:${PATH}

echo "making defconfig"
make O=out ARCH=arm64 vendor/spes-perf_defconfig
echo "making kernel"
make -j$(nproc --all) O=out \
                      ARCH=arm64 \
                      CC=clang

cd ..
cp kernel/out/arch/arm64/boot/Image.gz AnyKernel3-spes/
cp kernel/out/arch/arm64/boot/dtbo.img AnyKernel3-spes/

echo "Zipping"

if ! [ -d AnyKernel3 ];
then
  echo "AnyKernel not cloned, cloning."
  git clone https://github.com/bleedingedgeandroid/Anykernel3-spes.git AnyKernel3
else
  echo "AnyKernel cloned. Pulling"
  cd AnyKernel3
  git pull
  cd ..
fi

cd AnyKernel3/
sed -i 's/INTERNAL_KVERSION/'"${KVERSION}"'/' anykernel.sh
sed -i 's/CIBUILD/'"${BUILD_NUMBER}${BUILD_SUFFIX}/" anykernel.sh

zip -r9 ../Murali680-${BUILD_NUMBER}-$KVERSION${BUILD_SUFFIX}-PugzAreCuteCI.zip * -x .git README.md *placeholder 
echo "Done"

cd ..