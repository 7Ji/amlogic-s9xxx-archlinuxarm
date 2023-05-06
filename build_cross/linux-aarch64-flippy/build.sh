#!/bin/bash

# These variables could be overwritten by the caller with
#  e.g. export srcname=my_kernel_source.tar.gz

pkgrel="${pkgrel:-1}"
pkgname="${build_pkg:-linux-aarch64-flippy}"
builddir="${builddir:-builddir}"
outdir="${outdir:-outdir}"

should_build() {
  if [[ -f kernel.tar.gz && -f dtbs.tar.gz && -f headers.tar.gz ]]; then
    return 1
  else
    return 0
  fi
}

unpack() {
  rm -rf "${builddir}"
  mkdir "${builddir}"
  tar -C "${builddir}" -xvf "${dir_build_pkg}/linux-"*'.tar.gz' --strip-components=1
}

patch() {
  local patch_file
  local patch_files=()
  for patch_file in *.patch; do
    patch_files+=("$(readlink -f "${patch_file}")")
  done
  pushd "${builddir}"
  for patch_file in "${patch_files[@]}"; do
    echo "Applying patch ${patch_file}..."
    patch -p1 < "${patch_file}"
  done
  popd
}

prepare() {
  cp config "${builddir}/.config"
  pushd "${builddir}"
  scripts/setlocalversion --save-scmversion
  echo "-${pkgrel}" > localversion.10-pkgrel
  echo "${pkgname#linux}" > localversion.20-pkgname
  popd
}

build() {
  pushd "${builddir}"
  make prepare
  make -s kernelrelease > version
  unset LDFLAGS
  make ${MAKEFLAGS} DTC_FLAGS="-@" Image modules dtbs
  popd
}

package() {
  local oldpwd="${PWD}"
  pushd "${builddir}"
  local root=$(mktemp -d)
  local usr="${root}/usr"
  local dtbs="${root}/boot/dtbs/${pkgname}"
  mkdir -p "${usr}" "${dtbs}"
  make "INSTALL_MOD_PATH=${usr}" INSTALL_MOD_STRIP=1 modules_install
  make "INSTALL_DTBS_PATH=${dtbs}" dtbs_install
  local modules="${root}/usr/lib/modules/$(<version)"
  echo "${pkgname}" | install -D -m 644 /dev/stdin "${modules}/pkgbase"
  install -Dm644 'arch/arm64/boot/Image' "${modules}/vmlinuz"
  rm -f "${modules}/"{build,source}
  sed "s|%PKGBASE%|${pkgname}|g" ../linux.preset |
    install -Dm644 /dev/stdin "${root}/etc/mkinitcpio.d/${pkgname}.preset"
  rm -rf "${outdir}"
  mkdir "${outdir}"
  tar -C "${root}" -czf "${outdir}/kernel.tar.gz" 'usr' 'etc'
  tar -C "${root}" -czf "${outdir}/dtbs.tar.gz" 'boot'
  rm -rf "${root}"
  # Headers
  root=$(mktemp -d)
  local build="${root}/usr/lib/modules/$(<version)/build"

  echo "Installing build files..."
  install -Dt "${build}" -m644 .config Makefile Module.symvers System.map \
    localversion.* version vmlinux
  install -Dt "${build}/kernel" -m644 kernel/Makefile
  install -Dt "${build}/arch/arm64" -m644 arch/arm64/Makefile
  cp -t "${build}" -a scripts

  echo "Installing headers..."
  cp -t "${build}" -a include
  cp -t "${build}/arch/arm64" -a arch/arm64/include
  install -Dt "${build}/arch/arm64/kernel" -m644 arch/arm64/kernel/asm-offsets.s


  install -Dt "${build}/drivers/md" -m644 drivers/md/*.h
  install -Dt "${build}/net/mac80211" -m644 net/mac80211/*.h

  # https://bugs.archlinux.org/task/13146
  install -Dt "${build}/drivers/media/i2c" -m644 drivers/media/i2c/msp3400-driver.h

  # https://bugs.archlinux.org/task/20402
  install -Dt "${build}/drivers/media/usb/dvb-usb" -m644 drivers/media/usb/dvb-usb/*.h
  install -Dt "${build}/drivers/media/dvb-frontends" -m644 drivers/media/dvb-frontends/*.h
  install -Dt "${build}/drivers/media/tuners" -m644 drivers/media/tuners/*.h

  # https://bugs.archlinux.org/task/71392
  install -Dt "${build}/drivers/iio/common/hid-sensors" -m644 drivers/iio/common/hid-sensors/*.h

  echo "Installing KConfig files..."
  find . -name 'Kconfig*' -exec install -Dm644 {} "${build}/{}" \;

  echo "Removing unneeded architectures..."
  local arch
  for arch in "${build}"/arch/*/; do
    [[ "${arch}" == */arm64/ ]] && continue
    echo "Removing $(basename "${arch}")"
    rm -rf "${arch}"
  done

  echo "Removing documentation..."
  rm -rf "${build}/Documentation"

  echo "Removing broken symlinks..."
  find -L "${build}" -type l -printf 'Removing %P\n' -delete

  echo "Removing loose objects..."
  find "${build}" -type f -name '*.o' -printf 'Removing %P\n' -delete

  local STRIP_BINARIES="--strip-all"
  local STRIP_SHARED="--strip-unneeded"
  local STRIP_STATIC="--strip-debug"

  echo "Stripping build tools..."
  local file
  while read -rd '' file; do
    case "$(file -Sib "$file")" in
      application/x-sharedlib\;*)      # Libraries (.so)
        strip -v ${STRIP_SHARED} "$file" ;;
      application/x-archive\;*)        # Libraries (.a)
        strip -v ${STRIP_STATIC} "$file" ;;
      application/x-executable\;*)     # Binaries
        strip -v ${STRIP_BINARIES} "$file" ;;
      application/x-pie-executable\;*) # Relocatable binaries
        strip -v ${STRIP_SHARED} "$file" ;;
    esac
  done < <(find "${build}" -type f -perm -u+x ! -name vmlinux -print0)

  echo "Stripping vmlinux..."
  "${CROSS_COMPILE}strip" -v $STRIP_STATIC "${build}/vmlinux"

  echo "Adding symlink..."
  mkdir -p "${root}/usr/src"
  ln -sr "${build}" "${root}/usr/src/${pkgname}"
  tar -C "${root}" -czf "${outdir}/headers.tar.gz" usr
  rm -rf "${root}"
  rm -rf "${oldpwd}/"{kernel,dtbs,headers}'.tar.gz'
  mv "${outdir}/"* "${oldpwd}/"
  rm -rf "${outdir}"
  popd
  rm -rf "${builddir}"
}

all() {
  if should_build; then
    unpack
    prepare
    build
    package
  fi
}

all