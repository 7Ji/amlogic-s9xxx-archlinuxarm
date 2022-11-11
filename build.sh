#!/bin/bash -e

dir_aur='aur'
dir_pkg='pkg'
dir_uboot='uboot'
dir_booting='booting'
dir_out='out'

kernel='linux-aarch64-flippy'

aur_names=(
  'ampart-git'
  "${kernel}-bin"
  'linux-firmware-amlogic-ophub'
  'uboot-legacy-initrd-hooks'
)


no_makepkg_conf() {
  local makepkg_conf='/etc/makepkg.conf'
  echo " => Checking ${makepkg_conf}..."
  local conf=$(
    . ${makepkg_conf}
    echo "${PKGDEST}${SRCDEST}${SRCPKGDEST}"
  )
  if [[ "${conf}" ]]; then
    echo "  -> Error: either PKGDEST, SRCDEST or SRCPKGDEST is set in ${makepkg_conf}"
    return 1
  fi
  echo " => ${makepkg_conf} check pass"
}

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
    's905'
    's905x2-s922'
    's905x-s912'
    'sei510'
    'sei610'
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
    'f69f6241224f72e6942119dae0d026154089cdff8442d5a4c93de4d8bc3e69b9'
    'c3a3662453cbbfcd7a11e2c829017b667e601708f2f5c85543f1727249787a74'
    '3becd7d97afaa7fbcb683eb4c28221f282bf73b74d71138ac6be768611f8e11f'
    '5ff0be52537bd01ab6aa772e0ee284ab1e1f47f43cbc08da2a6c9982ef1df379'
    'ddf6ff930c13c03528b64a738de1126f811f6802c5096495ef83f6c07c4986d1'
    '3e89947c31bacc31574213f86ab03339291dcde928872dc6ae957fce58e76ac9'
    'aba80167498ef01482118c210636f14306ccaea80d09dce9e4358b993c0b3d88'
    '065370807a82019677cff7adaea917f1a08c5cc4baca4c5d9e19b117b66e5ce6'
    '74eb7d04eb743b5e512dcf3af42061a5b90306afcd46f64bdea427e18812b2a1'
    'e23bc57cefb1b99ecfb7a4192e8960c9b2a44f75d902ad6ff007108f9e01cc7b'
    '2bc15470d83f9e4e748f62897a0b3f71f896da51bf41591a03eebc289ee703dc'
    '3df7343e56116244b2d2d2fa8bcdbf411c088667bfc850f163d3b0b8caca29aa'
  )
  local armbian_repo='https://github.com/ophub/amlogic-s9xxx-armbian'
  local armbian_commit='4da175261a44e179c1416902b1f7bcc9f502cd8f'
  mkdir -p "${dir_uboot}"
  local uboot_name uboot_file uboot_sha256sum i=0
  for uboot_name in "${uboot_names[@]}"; do
    uboot_file="${dir_uboot}/${uboot_name}"
    if [[ -f "${uboot_file}" ]]; then
      uboot_sha256sum=$(sha256sum "${uboot_file}") # This is written as a single command without piping to cut because I want it to fail it sha256sum fails
      if [[ "${uboot_sha256sum::64}" == "${uboot_sha256sums[$i]}" ]]; then
        echo "  -> u-boot for ${uboot_name} already exists and sha256sum is correct, skip it"
        i=$(($i+1))
        continue
      else
        rm -f "${uboot_file}"
      fi
    fi
    # A URL should look like this: 
    # https://github.com/ophub/amlogic-s9xxx-armbian/raw/main/build-armbian/amlogic-u-boot/overload/u-boot-e900v22c.bin
    wget "${armbian_repo}/raw/${armbian_commit}/build-armbian/amlogic-u-boot/overload/u-boot-${uboot_name}.bin" -O "${uboot_file}"
    uboot_sha256sum=$(sha256sum "${uboot_file}") # This is written as a single command without piping to cut because I want it to fail it sha256sum fails
    if [[ "${uboot_sha256sum::64}" != "${uboot_sha256sums[$i]}" ]]; then
      echo "  -> Error: u-boot for ${uboot_name} has different sha256sum"
      exit 1
    fi
    i=$(($i+1))
    echo "  -> u-boot for ${uboot_name} downloaded and checked correct"
  done
}

prepare_name() {
  echo " => Preparing name"
  local name_distro='ArchLinuxARM-aarch64-Amlogic'
  local name_date=$(date +%Y%m%d_%H%M%S)
  name_base="${name_distro}-${name_date}"
  echo "  -> Basename ${name_base}"
  name_disk="${name_base}.img"
  name_disk_compressed="${name_disk}.xz"
  name_archive="${name_base}.tar"
  name_archive_compressed="${name_archive}.xz"
  echo " => Name prepared"
}

prepare_aur() {
  echo " => Preparing AUR packages..."
  if [[ ${SKIP_AUR} == 'yes' ]]; then
    echo "  -> Skipped AUR building as SKIP_AUR=yes"
  else
    git submodule update --remote
    find "${dir_aur}" -maxdepth 2 -name '*-aarch64.pkg.tar.*' -exec rm -rf {} \;
    mkdir -p "${dir_pkg}"
    rm -rf "${dir_pkg}/"*
    local dir_pkg_absolute=$(readlink -f "${dir_pkg}")
    pushd "${dir_aur}"
    for aur_pkg in *; do
        echo "  -> Building AUR package ${aur_pkg}..."
        pushd "${aur_pkg}"
        makepkg -cfsAC
        mv -v "${aur_pkg}"-*-aarch64.pkg.tar.* "${dir_pkg_absolute}/"
        popd
    done
    popd
  fi
  echo " => AUR packages prepared"
}

prepare_uuid() {
  echo " => Preparing UUID..."
  uuid_root=$(uuidgen)
  uuid_boot_mkfs=$(uuidgen)
  uuid_boot_mkfs=${uuid_boot_mkfs::8}
  uuid_boot_mkfs=${uuid_boot_mkfs^^}
  uuid_boot_specifier="${uuid_boot_mkfs::4}-${uuid_boot_mkfs:4}"
  echo "  -> UUID for root partition is ${uuid_root}"
  echo "  -> UUID for boot partition is ${uuid_boot_mkfs} / ${uuid_boot_specifier}"
  echo " => UUID prepared"
}

create_disk() {
  echo " => Creating disk..."
  local size_split=256M
  local size_disk=2G
  mkdir -p "${dir_out}"
  path_disk="${dir_out}/${name_disk}"
  echo "  -> Disk path is ${path_disk}"
  rm -f "${path_disk}"
  echo "  -> Allocating disk space..."
  truncate -s "${size_disk}" "${path_disk}"
  echo "  -> Creating partition table..."
  parted -s "${path_disk}" \
    mklabel msdos \
    mkpart primary fat32 1MiB "${size_split}iB" \
    mkpart primary "${size_split}iB" 100%
  echo ' => Disk created'
}

setup_loop() {
  echo " => Setting up loop device..."
  loop_disk=$(sudo losetup -fP --show "${path_disk}")
  echo "  -> Using loop device ${loop_disk}"
  loop_boot="${loop_disk}p1"
  loop_root="${loop_disk}p2"
  echo " => Set up loop device"
}

create_fs() {
  echo " => Creating FS..."
  echo "  -> Creating FAT32 FS with UUID ${uuid_boot_mkfs} on ${loop_boot}"
  sudo mkfs.vfat -n 'ALARMBOOT' -F 32 -i "${uuid_boot_mkfs}" "${loop_boot}"
  echo "  -> Creating ext4 FS with UUID ${uuid_root} on ${loop_root}"
  sudo mkfs.ext4 -L 'ALARMROOT' -m 0 -U "${uuid_root}" "${loop_root}"
  echo " => Created FS"
}

create_mountpoint() {
  echo " => Creating mountpoint..."
  dir_root=$(sudo mktemp -d)
  echo "  -> Using ${dir_root} as mountpoint"
  dir_boot="${dir_root}/boot"
  echo " => Created mountpoint"
}

mount_tree() {
  echo " => Mounting root tree"
  echo "  -> Mounting ${loop_root} to ${dir_root}"
  sudo mount -o noatime "${loop_root}" "${dir_root}"
  sudo mkdir -p "${dir_boot}"
  echo "  -> Mounting ${loop_boot} to ${dir_boot}"
  sudo mount -o noatime "${loop_boot}" "${dir_boot}"
  echo " => Root tree mounted"
}

pacstrap_base() {
  echo " => Pacstrapping the base package group into ${dir_root}..."
  sudo pacstrap "${dir_root}" base
  echo " => Pacstrap base done"
}

pacstrap_aur() {
  echo " => Pacstrapping the AUR packages into ${dir_root}..."
  local pkg_suffix='aarch64.pkg.tar.'
  local pkg_names=(
    'ampart-git'
    'linux-aarch64-flippy-bin-dtb-amlogic'
    'linux-firmware-amlogic-ophub'
    'uboot-legacy-initrd-hooks'
  )
  local pkg_name pkg_match
  local pkgs=()
  for pkg_name in "${pkg_names[@]}"; do
    pkg_match=("${dir_pkg}/${pkg_name}-"*"-${pkg_suffix}"*)
    if [[ "${#pkg_match[@]}" != 1 ]]; then
      echo "  -> Error: not exact one match for package ${pkg_name}, matches: ${pkg_match[@]}"
      return 1
    fi
    pkgs+=(${pkg_match[0]})
  done
  if [[ ${#pkgs[@]} != 4 ]]; then
    echo "  -> Error: Not all 4 of ${pkg_names[@]} are found"
    return 2
  fi
  local pkg
  for pkg in "${dir_pkg}/linux-aarch64-flippy-bin-"*"-${pkg_suffix}"*; do
    if [[ "$(basename "${pkg}")" != linux-aarch64-flippy-bin-dtb-* ]]; then
      pkgs+=("${pkg}")
      break
    fi
  done
  if [[ ${#pkgs[@]} != 5 ]]; then
    echo "  -> Error: Package linux-aarch64-flippy-bin was not found"
    return 3
  fi
  sudo pacstrap -U "${dir_root}" "${pkgs[@]}"
  echo " => Pacstrap AUR done"
}

remove_non_fallback() {
  echo " => Removing non-fallback non-legacy initramfs..."
  sudo rm -f ${dir_boot}/initramfs-linux-aarch64-flippy.{u,}img ${dir_boot}/initramfs-linux-aarch64-flippy-fallback.img
  echo " => Removed non-fallback non-legacy initramfs"
}

genfstab_root() {
  echo " => Generating fstab..."
  local fstab_file="${dir_root}/etc/fstab"
  local fstab_content=$(
    printf '# root partition with ext4 on SDcard / USB drive\nUUID=%s\t/\text4\trw,noatime,data=writeback\t0 1\n# boot partition with vfat on SDcard / USB drive\nUUID=%s\t/boot\tvfat\trw,noatime,fmask=0022,dmask=0022,codepage=437,iocharset=ascii,shortname=mixed,utf8,errors=remount-ro\t0 2\n' "${uuid_root}" "${uuid_boot_specifier}"
  )
  echo "${fstab_content}" > "${fstab_file}"
  echo " => Generated fstab"
}

populate_boot() {
  echo " => Populating boot partition..."
  echo "  -> Writing booting scripts..."
  local script
  for script in booting/*.sh; do
    name=$(basename "$script")
    sudo mkimage -A arm64 -O linux -T script -C none -d "${script}" "${dir_boot}/${name%.sh}.scr" > /dev/null
  done
  echo "  -> Writing booting configuration..."
  local kernel='linux-aarch64-flippy'
  local conf_linux="vmlinuz-${kernel}"
  local conf_initrd="initramfs-${kernel}-fallback.uimg"
  local conf_fdt="dtbs/${kernel}/amlogic/PLEASE_SET_YOUR_DTB.dtb"
  local conf_append="root=UUID=${uuid_root} rootflags=data=writeback rw rootfstype=ext4 console=ttyAML0,115200n8 console=tty0 no_console_suspend consoleblank=0 fsck.fix=yes fsck.repair=yes net.ifnames=0 cgroup_enable=cpuset cgroup_memory=1 cgroup_enable=memory swapaccount=1"
  local subst="
    s|%LINUX%|${conf_linux}|g
    s|%INITRD%|${conf_initrd}|g
    s|%FDT%|${conf_fdt}|g
    s|%APPEND%|${conf_append}|g
  "
  local temp_uenv=$(mktemp)
  local temp_extlinux=$(mktemp)
  sed "${subst}" "${dir_booting}/uEnv.txt" > "${temp_uenv}"
  sed "${subst}" "${dir_booting}/extlinux.conf" > "${temp_extlinux}"
  sudo cp "${temp_uenv}" "${dir_boot}/uEnv.txt"
  sudo mkdir -p "${dir_boot}/extlinux"
  sudo cp "${temp_extlinux}" "${dir_boot}/extlinux/extlinux.conf"
  rm -f "${temp_uenv}" "${temp_extlinux}"
  echo "  -> Dumping uboot..."
  sudo cp -rv "${dir_uboot}" "${dir_boot}/"
  echo " => Populated boot partition"
}

sanity_check() {
  echo "=> Sanity checking..."
  no_makepkg_conf
  echo "=> Sanity check end"
}

prepare() {
  echo "=> Preparing..."
  prepare_uboot
  prepare_aur
  prepare_name
  prepare_uuid
  echo "=> Preparation end"
}

deploy() {
  echo "=> Deploying..."
  create_disk
  setup_loop
  create_fs
  create_mountpoint
  mount_tree
  pacstrap_base
  pacstrap_aur
  remove_non_fallback
  populate_boot
  echo "=> Deploy end"
}

run_inside() {
  echo "=> Getting into the target root"
  local script_name='inroot.sh'
  local script_in_path="/root/${script_name}"
  local script_actual_path="${dir_root}${script_in_path}"
  sudo install -Dm755 'inroot.sh' "${script_actual_path}"
  sudo arch-chroot "${dir_root}" "${script_in_path}"
  sudo rm -f "${script_actual_path}"
  echo "=> Getting out from the target root"
}

make_archive() {
  echo "=> Creating rootfs archive..."
  local path_archive="${dir_out}/${name_archive}"
  echo " -> Creating archive ${path_archive} without compression..."
  (
    cd "${dir_root}"
    sudo bsdtar --acls --xattrs -cvpf - *
  ) > "${path_archive}"
  local path_archive_compressed="${dir_out}/${name_archive_compressed}"
  echo " -> Compressing archive to ${path_archive_compressed} ..."
  if [[ "${SKIP_XZ}" == 'yes' ]]; then
    echo " -> Compressing skipped since SKIP_XZ=yes"
  else
    xz -9ecvT0 "${path_archive}" > "${path_archive_compressed}"
  fi
  echo "=> Rootfs archive created"
}

zero_fill() {
  echo "=> Filling zeroes to target root and boot fs to maximum compression"
  echo " => Filling boot partition..."
  sudo dd if=/dev/zero of="${dir_boot}/.zerofill" || true
  echo " => Filling root partition..."
  sudo dd if=/dev/zero of="${dir_root}/.zerofill" || true
  rm -f "${dir_boot}/.zerofill" "${dir_root}/.zerofill"
  echo "=> Zero fill successful"
}

release_resource() {
  echo "=> Releasing resources..."
  echo " => Umouting partitions..."
  umount -R "${dir_root}" 
  echo " => Detaching loopback device ${loop_disk}"
  losetup -d "${loop_disk}"
  echo "=> Released resources"
}

compress_image() {
  echo "=> Compressing disk image..."
  local path_disk="${dir_out}/${name_disk}"
  local path_disk_compressed="${dir_out}/${name_disk_compressed}"
  echo " => Compressing into ${path_disk_compressed}..."
  if [[ "${SKIP_XZ}" == 'yes' ]]; then
    echo " -> Compressing skipped since SKIP_XZ=yes"
  else
    xz -9ecvT0 "${path_disk}" > "${path_disk_compressed}"
  fi
  echo "=> Compressing success"
}

build() {
  echo "=> Build starts at $(date) <="
  sanity_check
  prepare
  deploy
  run_inside
  make_archive
  zero_fill
  release_resource
  compress_image
  echo "=> Build ends at $(date) <="
}

build