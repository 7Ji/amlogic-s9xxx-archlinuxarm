#!/bin/bash -e

# Read config
. config.sh
# Common functions
. common/functions/relative_source.sh
relative_source common/functions/build.sh
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