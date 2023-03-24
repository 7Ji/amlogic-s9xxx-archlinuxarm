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
  '/etc/udev/rules.d/50-amlogic-partition-links.rules'
)
blob_modes+=(
  '644'
)
blob_urls+=(
  'https://github.com/7Ji/ampart/raw/84953ee27c79b23c17ad7962f2da34c77f7824cb/udev/ept-links-mainline.rules'
)
blob_sha256sums+=(
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