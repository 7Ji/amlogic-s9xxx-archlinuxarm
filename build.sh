#!/bin/bash -e

# Common config
. common/scripts/config.sh
# Local config
name_distro+='-Amlogic'
dir_booting='booting'
dir_uboot='uboot'
release_note_packages+=(
  'ampart-git:[my AUR][AUR ampart-git]'
  'linux-aarch64-flippy:[my AUR][AUR linux-aarch64-flippy-bin]'
  'linux-firmware-amlogic-ophub:[my AUR][AUR linux-firmware-amlogic-ophub]'
  'uboot-legacy-initrd-hooks:[my AUR][AUR uboot-legacy-initrd-hooks]'
  'yay:[AUR][AUR yay]'
)
# Common functions
. common/functions/build.sh
# Overload common functions
prepare_blob() {
  prepare_uboot
}
populate_blob() {
  populate_boot
  populate_udev
}
remove_non_fallback() {
  echo " => Removing non-fallback non-legacy initramfs..."
  sudo rm -f ${dir_boot}/initramfs-linux-aarch64-flippy.{u,}img ${dir_boot}/initramfs-linux-aarch64-flippy-fallback.img
  echo " => Removed non-fallback non-legacy initramfs"
}
# Local functions
prepare_uboot() {
  echo " => Preparing u-boot..."
  local uboot_names=(
    'e900v22c'
    'gtking'
    'gtkingpro'
    'gtkingpro-rev-a'
    'n1'
    'odroid-n2'
    'p201'
    'p212'
    'r3300l'
    's905'
    's905x2-s922'
    's905x-s912'
    'sei510'
    'sei610'
    'skyworth-lb2004'
    'tx3-bz'
    'tx3-qz'
    'u200'
    'ugoos-x3'
    'x96max'
    'x96maxplus'
    'zyxq'
  )
  local uboot_sha256sums=(
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
  )
  local armbian_repo='https://github.com/ophub/amlogic-s9xxx-armbian'
  local armbian_commit='8d5f8a8ac2fb1a7b749a67274f44edd308ce7a6a'
  mkdir -p "${dir_uboot}"
  local uboot_name uboot_file uboot_sha256sum i=0
  local wget=${wget:-wget} # User can e.g. export wget='proxychains wget', so it can go through proxy
  for uboot_name in "${uboot_names[@]}"; do
    uboot_file="${dir_uboot}/${uboot_name}"
    if [[ -f "${uboot_file}" ]]; then
      sha256sum_log=$(sha256sum "${uboot_file}") # This is written as a single command without piping to cut because I want it to fail it sha256sum fails
      sha256sum_actual="${sha256sum_log::64}"
      sha256sum_expected="${uboot_sha256sums[$i]}"
      if [[ "${sha256sum_actual}" ==  "${sha256sum_expected}" ]]; then
        echo "  -> u-boot for ${uboot_name} already exists and sha256sum is correct, skip it"
        i=$(($i+1))
        continue
      else
        echo "  -> existing u-boot for ${uboot_name} has different sha256sum than expected, will re-downloadd"
        echo "   -> actual: ${sha256sum_actual}"
        echo "   -> expected: ${sha256sum_expected}"
        rm -f "${uboot_file}"
      fi
    fi
    # A URL should look like this: 
    # https://github.com/ophub/amlogic-s9xxx-armbian/blob/main/build-armbian/u-boot/amlogic/overload/u-boot-s905x-s912.bin
    ${wget} "${armbian_repo}/raw/${armbian_commit}/build-armbian/u-boot/amlogic/overload/u-boot-${uboot_name}.bin" -O "${uboot_file}"
    sha256sum_log=$(sha256sum "${uboot_file}") # This is written as a single command without piping to cut because I want it to fail it sha256sum fails
    sha256sum_actual="${sha256sum_log::64}"
    sha256sum_expected="${uboot_sha256sums[$i]}"
    if [[ "${sha256sum_actual}" !=  "${sha256sum_expected}" ]]; then
      echo "  -> Error: u-boot for ${uboot_name} has different sha256sum"
      echo "   -> actual: ${sha256sum_actual}"
      echo "   -> expected: ${sha256sum_expected}"
      exit 1
    fi
    i=$(($i+1))
    echo "  -> u-boot for ${uboot_name} downloaded and checked correct"
  done
}
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
  echo "  -> Dumping uboot..."
  sudo cp -rv "${dir_uboot}" "${dir_boot}/"
  echo " => Populated boot partition"
}
populate_udev() {
  git archive --remote "${dir_aur}/ampart-git/ampart" 'ampart' 'udev/ept-links-mainline.rules' |
    tar -xO |
    sudo install -DTm 644 '/dev/stdin' "${dir_root}/etc/udev/rules.d/50-amlogic-partition-links.rules"
}
# Actual build
build