#!/bin/bash -e

# Common config
. common/scripts/config.sh
# Local config
name_distro+='-Amlogic'
dir_booting='booting'
release_note_packages+=(
  'ampart:[my AUR][AUR ampart]'
  'linux-aarch64-flippy:[my AUR][AUR linux-aarch64-flippy-bin]'
  'linux-firmware-amlogic-ophub:[my AUR][AUR linux-firmware-amlogic-ophub]'
  'yaopenvfd:[my AUR][AUR yaopenvfd]'
  'uboot-legacy-initrd-hooks:[my AUR][AUR uboot-legacy-initrd-hooks]'
  'yay:[AUR][AUR yay]'
)
blob_paths+=(
  '/boot/uboot/e900v22c'
  '/boot/uboot/gtking'
  '/boot/uboot/gtkingpro'
  '/boot/uboot/gtkingpro-rev-a'
  '/boot/uboot/n1'
  '/boot/uboot/odroid-n2'
  '/boot/uboot/p201'
  '/boot/uboot/p212'
  '/boot/uboot/r3300l'
  '/boot/uboot/s905'
  '/boot/uboot/s905x2-s922'
  '/boot/uboot/s905x-s912'
  '/boot/uboot/sei510'
  '/boot/uboot/sei610'
  '/boot/uboot/skyworth-lb2004'
  '/boot/uboot/tx3-bz'
  '/boot/uboot/tx3-qz'
  '/boot/uboot/u200'
  '/boot/uboot/ugoos-x3'
  '/boot/uboot/x96max'
  '/boot/uboot/x96maxplus'
  '/boot/uboot/zyxq'
  '/etc/udev/rules.d/50-amlogic-partition-links.rules'
)
blob_modes+=(
  '644'
  '644'
  '644'
  '644'
  '644'
  '644'
  '644'
  '644'
  '644'
  '644'
  '644'
  '644'
  '644'
  '644'
  '644'
  '644'
  '644'
  '644'
  '644'
  '644'
  '644'
  '644'
  '644'
)
blob_urls+=(
  'https://github.com/ophub/amlogic-s9xxx-armbian/raw/2f600cbc59c992e560e62c2cadae57d00096b1c7/build-armbian/u-boot/amlogic/overload/u-boot-e900v22c.bin'
  'https://github.com/ophub/amlogic-s9xxx-armbian/raw/2f600cbc59c992e560e62c2cadae57d00096b1c7/build-armbian/u-boot/amlogic/overload/u-boot-gtking.bin'
  'https://github.com/ophub/amlogic-s9xxx-armbian/raw/2f600cbc59c992e560e62c2cadae57d00096b1c7/build-armbian/u-boot/amlogic/overload/u-boot-gtkingpro.bin'
  'https://github.com/ophub/amlogic-s9xxx-armbian/raw/2f600cbc59c992e560e62c2cadae57d00096b1c7/build-armbian/u-boot/amlogic/overload/u-boot-gtkingpro-rev-a.bin'
  'https://github.com/ophub/amlogic-s9xxx-armbian/raw/2f600cbc59c992e560e62c2cadae57d00096b1c7/build-armbian/u-boot/amlogic/overload/u-boot-n1.bin'
  'https://github.com/ophub/amlogic-s9xxx-armbian/raw/2f600cbc59c992e560e62c2cadae57d00096b1c7/build-armbian/u-boot/amlogic/overload/u-boot-odroid-n2.bin'
  'https://github.com/ophub/amlogic-s9xxx-armbian/raw/2f600cbc59c992e560e62c2cadae57d00096b1c7/build-armbian/u-boot/amlogic/overload/u-boot-p201.bin'
  'https://github.com/ophub/amlogic-s9xxx-armbian/raw/2f600cbc59c992e560e62c2cadae57d00096b1c7/build-armbian/u-boot/amlogic/overload/u-boot-p212.bin'
  'https://github.com/ophub/amlogic-s9xxx-armbian/raw/2f600cbc59c992e560e62c2cadae57d00096b1c7/build-armbian/u-boot/amlogic/overload/u-boot-r3300l.bin'
  'https://github.com/ophub/amlogic-s9xxx-armbian/raw/2f600cbc59c992e560e62c2cadae57d00096b1c7/build-armbian/u-boot/amlogic/overload/u-boot-s905.bin'
  'https://github.com/ophub/amlogic-s9xxx-armbian/raw/2f600cbc59c992e560e62c2cadae57d00096b1c7/build-armbian/u-boot/amlogic/overload/u-boot-s905x2-s922.bin'
  'https://github.com/ophub/amlogic-s9xxx-armbian/raw/2f600cbc59c992e560e62c2cadae57d00096b1c7/build-armbian/u-boot/amlogic/overload/u-boot-s905x-s912.bin'
  'https://github.com/ophub/amlogic-s9xxx-armbian/raw/2f600cbc59c992e560e62c2cadae57d00096b1c7/build-armbian/u-boot/amlogic/overload/u-boot-sei510.bin'
  'https://github.com/ophub/amlogic-s9xxx-armbian/raw/2f600cbc59c992e560e62c2cadae57d00096b1c7/build-armbian/u-boot/amlogic/overload/u-boot-sei610.bin'
  'https://github.com/ophub/amlogic-s9xxx-armbian/raw/2f600cbc59c992e560e62c2cadae57d00096b1c7/build-armbian/u-boot/amlogic/overload/u-boot-skyworth-lb2004.bin'
  'https://github.com/ophub/amlogic-s9xxx-armbian/raw/2f600cbc59c992e560e62c2cadae57d00096b1c7/build-armbian/u-boot/amlogic/overload/u-boot-tx3-bz.bin'
  'https://github.com/ophub/amlogic-s9xxx-armbian/raw/2f600cbc59c992e560e62c2cadae57d00096b1c7/build-armbian/u-boot/amlogic/overload/u-boot-tx3-qz.bin'
  'https://github.com/ophub/amlogic-s9xxx-armbian/raw/2f600cbc59c992e560e62c2cadae57d00096b1c7/build-armbian/u-boot/amlogic/overload/u-boot-u200.bin'
  'https://github.com/ophub/amlogic-s9xxx-armbian/raw/2f600cbc59c992e560e62c2cadae57d00096b1c7/build-armbian/u-boot/amlogic/overload/u-boot-ugoos-x3.bin'
  'https://github.com/ophub/amlogic-s9xxx-armbian/raw/2f600cbc59c992e560e62c2cadae57d00096b1c7/build-armbian/u-boot/amlogic/overload/u-boot-x96max.bin'
  'https://github.com/ophub/amlogic-s9xxx-armbian/raw/2f600cbc59c992e560e62c2cadae57d00096b1c7/build-armbian/u-boot/amlogic/overload/u-boot-x96maxplus.bin'
  'https://github.com/ophub/amlogic-s9xxx-armbian/raw/2f600cbc59c992e560e62c2cadae57d00096b1c7/build-armbian/u-boot/amlogic/overload/u-boot-zyxq.bin'
  'https://github.com/7Ji/ampart/raw/84953ee27c79b23c17ad7962f2da34c77f7824cb/udev/ept-links-mainline.rules'
)
blob_sha256sums+=(
  'fb0d8e321828642bf2c930dae96fd0048933f87e4d4228a77270a4d1aa7e7b41'
  '7c0c91e60d107c61de03798fcb04e462c7e5616b400ee6abc096b94e97a2cee0'
  '215f2f3abbd03f19a7b304f5dd7824914a16d9bdecb0711845a8c2fa7e292483'
  'b8fc82e1a4a72ce15ee6fee8776ef26f9ae4834b641a2e4b6a912a3e89efdff6'
  '5094d8144688c5fc20424497afb11b04187c9efdf8adf95cd2a9fbbd951b8cfc'
  'e0e7a258e024aa8e825a6c46c68fdf0e6da2dfa54d379115b91fae25176e748f'
  '3a76dc9b2d80988ffbaade9555700b6d9121498eef6f75000ebd11e9f991ed3f'
  'c3b2065356e61cec05320e68010135a315e7d89d0e6d6dd212a55a28cf90f7e8'
  '27874155c05d4c8252cf443a78c84867d071960dff0d66dbee5c8f19a3d30737'
  'f69f6241224f72e6942119dae0d026154089cdff8442d5a4c93de4d8bc3e69b9'
  'c3a3662453cbbfcd7a11e2c829017b667e601708f2f5c85543f1727249787a74'
  '3becd7d97afaa7fbcb683eb4c28221f282bf73b74d71138ac6be768611f8e11f'
  '5ff0be52537bd01ab6aa772e0ee284ab1e1f47f43cbc08da2a6c9982ef1df379'
  'ddf6ff930c13c03528b64a738de1126f811f6802c5096495ef83f6c07c4986d1'
  'c2984db61bebf94c13a9d458cb77fdfb6b2a017516862fbbad159f8a480880d0'
  '3e89947c31bacc31574213f86ab03339291dcde928872dc6ae957fce58e76ac9'
  'aba80167498ef01482118c210636f14306ccaea80d09dce9e4358b993c0b3d88'
  '065370807a82019677cff7adaea917f1a08c5cc4baca4c5d9e19b117b66e5ce6'
  '4a33c8dc3acedd646f0676bb5c9a5b2718450fca6c5871949cb85fa244321bc1'
  'e23bc57cefb1b99ecfb7a4192e8960c9b2a44f75d902ad6ff007108f9e01cc7b'
  '2bc15470d83f9e4e748f62897a0b3f71f896da51bf41591a03eebc289ee703dc'
  '3df7343e56116244b2d2d2fa8bcdbf411c088667bfc850f163d3b0b8caca29aa'
  '08da0b3fb56dcbc39943bed52cb1931ab71923e83c32c8f5073ee081b3807ee3'
)
# Common functions
. common/functions/build.sh
# Overload common functions
populate_boot() {
  echo " => Populating boot partition..."
  echo "  -> Writing booting scripts..."
  local script name
  for script in booting/*.sh; do
    name=$(basename "$script")
    if [ "${name}" == 'boot.sh' ]; then
      name="${name%.sh}.scr"
    else
      name="${name%.sh}"
    fi
    sudo mkimage -A arm64 -O linux -T script -C none -d "${script}" "${dir_boot}/${name}" > /dev/null
  done
  echo "  -> Writing booting configuration..."
  local kernel='linux-aarch64-flippy'
  local conf_linux="vmlinuz-${kernel}"
  local conf_initrd="initramfs-${kernel}-fallback.uimg"
  local conf_fdt="dtbs/${kernel}/amlogic/PLEASE_SET_YOUR_DTB.dtb"
  local conf_append="root=UUID=${uuid_root} rw audit=0 apt_blkdevs=mmcblk2"
  local subst="
    s|%LINUX%|${conf_linux}|g
    s|%INITRD%|${conf_initrd}|g
    s|%FDT%|${conf_fdt}|g
    s|%APPEND%|${conf_append}|g
  "
  sed "${subst}" "${dir_booting}/uEnv.txt" |
    sudo install -DTm 644 '/dev/stdin' "${dir_boot}/uEnv.txt"
  sed "${subst}" "${dir_booting}/extlinux.conf" |
    sudo install -DTm 644 '/dev/stdin' "${dir_boot}/extlinux/extlinux.conf"
  echo " => Populated boot partition"
}
remove_non_fallback() {
  echo " => Removing non-fallback non-legacy initramfs..."
  sudo rm -f ${dir_boot}/initramfs-linux-aarch64-flippy.{u,}img ${dir_boot}/initramfs-linux-aarch64-flippy-fallback.img
  echo " => Removed non-fallback non-legacy initramfs"
}
# Actual build
build