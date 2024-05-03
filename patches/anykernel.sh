### AnyKernel3 Ramdisk Mod Script
## osm0sis @ xda-developers

### AnyKernel setup
# begin properties

properties() { '
kernel.string=WhoeverYouWant fog/wind/rain Kernel. Version CI_KERNEL_VERSION. CI build: CI_BUILD_NUMBER | Source by @AlterNoegraha, @Teleg3_7, @muralivijay9845, @CHRISL7 and @AkiraNoSushi | Compiled by @PugzAreCute
do.devicecheck=1
do.modules=0
do.systemless=0
do.cleanup=1
do.cleanuponabort=0
device.name1=fog
device.name2=rain
device.name3=wind
supported.versions=
supported.patchlevels=
'; } # end properties

### AnyKernel install

## boot shell variables
block=boot;
is_slot_device=1;
ramdisk_compression=auto;
patch_vbmeta_flag=auto;

# import functions/variables and setup patching - see for reference (DO NOT REMOVE)
. tools/ak3-core.sh;

# boot install
dump_boot; # use split_boot to skip ramdisk unpack, e.g. for devices with init_boot ramdisk
write_boot; # use flash_boot to skip ramdisk repack, e.g. for devices with init_boot ramdisk
## end boot install

