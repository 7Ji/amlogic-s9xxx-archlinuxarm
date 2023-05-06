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