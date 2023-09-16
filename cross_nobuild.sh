#!/bin/bash -e
# Experimental new cross-building script, to replace cross.sh
# Instead of calling build.sh in a QEMU AArch64 ALARM environment, this does everything purely on host
# The expected running environment is Ubuntu 22.04, i.e. the main distro used in Github Actions
# If you're running ALARM, then you should look at build.sh
# If you're running Arch, then you should expect breakage due to Ubuntu FHS being expected

# The following envs could be set to change the behaviour:
# pkg_from_local_mirror: when not empty, chainload pacoloco from another local mirror, useful for local only

if [[ "${pkg_from_local_mirror}" ]]; then
    mirror_archlinux=${mirror_archlinux:-http://repo.lan:9129/repo/archlinux}
    mirror_archlinuxarm=${mirror_alarm:-http://repo.lan:9129/repo/archlinuxarm}
    mirror_archlinuxcn=${mirror_archlinuxcn:-http://repo.lan:9129/repo/archlinuxcn_x86_64}
    mirror_7Ji=${mirror_7Ji:-http://repo.lan/github-mirror}
else
    mirror_archlinux=${mirror_archlinux:-https://geo.mirror.pkgbuild.com}
    mirror_archlinuxarm=${mirror_alarm:-http://mirror.archlinuxarm.org}
    mirror_archlinuxcn=${mirror_archlinuxcn:-https://opentuna.cn/archlinuxcn}
    mirror_7Ji=${mirror_7Ji:-https://github.com/7Ji/archrepo/releases/download}
fi

# Everything will be done in a subfolder
mkdir -p cross_nobuild/{bin,cache,out,src/pkg}
pushd cross_nobuild

# functions
dl() { # 1: url 2: output
    echo "Downloading '$2' <= '$1'" >&2
    if [[ "$2" ]]; then
        curl -qgb "" -fL --retry 3 --retry-delay 3 -o "$2" "$1"
    else
        curl -qgb "" -fL --retry 3 --retry-delay 3 "$1"
    fi
    echo "Downloaded '$2' <= '$1'" >&2
}

init_repo() { # 1: dir, 2: url, 3: branch
    if [[  -z "$1$2" ]]; then
        echo "Dir and URL not set"
        return 1
    fi
    rm -rf "$1"
    mkdir "$1"
    mkdir "$1"/{objects,refs}
    echo 'ref: refs/heads/'"$3" > "$1"/HEAD
    echo "[core]
	repositoryformatversion = 0
	filemode = true
	bare = true
[remote "origin"]
	url = $2
	fetch = +refs/heads/$3:refs/heads/$3" > "$1"/config
}

dump_binary_from_repo() { # 1: repo url, 2: repo name, 3: pkgname, 4: local bin, 5: source bin
    dl "$1/$2".db cache/repo.db
    local desc=$(tar -xOf cache/repo.db --wildcards "$3"'-*/desc')
    local names=($(sed -n '/%NAME%/{n;p;}' <<< "${desc}"))
    case ${#names[@]} in
    0)
        echo "Failed to find package '$3' in repo '$1"
        return 1
    ;;
    1)
        local ver=$(sed -n '/%VERSION%/{n;p;}' <<< "${desc}")
        local pkg=$(sed -n '/%FILENAME%/{n;p;}' <<< "${desc}")
    ;;
    *)
        local vers=($(sed -n '/%VERSION%/{n;p;}' <<< "${desc}"))
        local pkgs=($(sed -n '/%FILENAME%/{n;p;}' <<< "${desc}"))
        local id=0
        local name
        for name in "${names[@]}"; do
            if [[ "${name}" == "$3" ]]; then
                break
            fi
            local id=$(( id + 1 ))
        done
        local ver="${vers[${id}]}"
        local pkg="${pkgs[${id}]}"
    ;;
    esac
    if [[ ! -f bin/"$4-${ver}" ]]; then
        rm bin/"$4"-* || true
        dl "$1/${pkg}" cache/"${pkg}"
        tar -xOf cache/"${pkg}" "$5" > bin/"$4-${ver}".temp
        mv bin/"$4-${ver}"{.temp,}
    fi
    chmod +x bin/"$4-${ver}"
    ln -sf "$4-${ver}" bin/"$4"
}


run_in_chroot() {
   sudo chroot "${root}" "$@" 
}

cleanup() {
    echo "=> Cleaning up before exiting..."
    if [[ "${pid_pacoloco}" ]]; then
        kill -s TERM ${pid_pacoloco} || true
    fi
    if [[ "${root}" ]]; then
        run_in_chroot killall -s KILL gpg-agent dirmngr || true
        if sudo umount -fR "${root}"; then
            rm -rf "${root}"
        fi
    fi
    if [[ "${boot}" ]]; then
      if sudo umount -f "${boot}"; then
        rm -rf "${boot}"
      fi
    fi
    if [[ "${lodev}" ]]; then
        sudo losetup --detach "${lodev}" || true
    fi
}

trap "cleanup" INT TERM EXIT

# Deploy pacoloco
dump_binary_from_repo "${mirror_archlinux}"/extra/os/x86_64 extra pacoloco pacoloco usr/bin/pacoloco

# Prepare to run pacoloco
# prefer mirrors provided by companies than universities, save their budget
echo "cache_dir: src/pkg
download_timeout: 3600
purge_files_after: 2592000
repos:
  archlinuxarm:
    urls:
      - ${mirror_archlinuxarm}
      - https://opentuna.cn/archlinuxarm
      - http://mirrors.cloud.tencent.com.cn/archlinuxarm
  archlinuxcn_x86_64:
    urls:
      - ${mirror_archlinuxcn}
      - https://mirrors.cloud.tencent.com/archlinuxcn
      - https://mirrors.163.com/archlinux-cn
      - https://mirrors.aliyun.com/archlinuxcn
  7Ji:
    url: ${mirror_7Ji}" > cache/pacoloco.conf
# Run pacoloco in background
bin/pacoloco -config cache/pacoloco.conf &
pid_pacoloco=$!
sleep 1

# Mainly for pacman-static
repo_url_archlinuxcn_x86_64=http://127.0.0.1:9129/repo/archlinuxcn_x86_64/x86_64
# For base system packages
repo_url_alarm_aarch64=http://127.0.0.1:9129/repo/archlinuxarm/aarch64/'$repo'
# For kernels and other stuffs
repo_url_7Ji_aarch64=http://127.0.0.1:9129/repo/7Ji/aarch64

# Deploy pacman-static
dump_binary_from_repo "${repo_url_archlinuxcn_x86_64}" archlinuxcn pacman-static pacman usr/bin/pacman-static 

# Basic image layout
build_id=ArchLinuxARM-aarch64-Amlogic-s9xxx-$(date +%Y%m%d_%H%M%S)
rm -f out/"${build_id}"-base.img
truncate -s 2G out/"${build_id}"-base.img
echo 'label: dos
start=8192, size=524288, type=ef
start=532480, size=3661824, type=83' |
    sfdisk out/"${build_id}"-base.img

# Partition
lodev=$(sudo losetup --find --partscan --show out/${build_id}-base.img)
uuid_root=$(uuidgen)
uuid_boot_mkfs=$(uuidgen)
uuid_boot_mkfs=${uuid_boot_mkfs::8}
uuid_boot_mkfs=${uuid_boot_mkfs^^}
uuid_boot_specifier="${uuid_boot_mkfs::4}-${uuid_boot_mkfs:4}"
sudo mkfs.vfat -n 'ALARMBOOT' -F 32 -i "${uuid_boot_mkfs}" "${lodev}"p1
sudo mkfs.ext4 -L 'ALARMROOT' -m 0 -U "${uuid_root}" "${lodev}"p2

# Mount
root=$(mktemp -d)
sudo mount -o noatime "${lodev}"p2 "${root}"
sudo mkdir -p "${root}"/{boot,dev/{pts,shm},etc/pacman.d,proc,run,sys,tmp,var/{cache/pacman/pkg,lib/pacman,log}}
sudo mount -o noatime "${lodev}"p1 "${root}"/boot
sudo mount proc "${root}"/proc -t proc -o nosuid,noexec,nodev
sudo mount sys "${root}"/sys -t sysfs -o nosuid,noexec,nodev,ro
sudo mount udev "${root}"/dev -t devtmpfs -o mode=0755,nosuid
sudo mount devpts "${root}"/dev/pts -t devpts -o mode=0620,gid=5,nosuid,noexec
sudo mount shm "${root}"/dev/shm -t tmpfs -o mode=1777,nosuid,nodev
sudo mount run "${root}"/run -t tmpfs -o nosuid,nodev,mode=0755
sudo mount tmp "${root}"/tmp -t tmpfs -o mode=1777,strictatime,nodev,nosuid

# Create temporary pacman config
pacman_config="
RootDir      = ${root}
DBPath       = ${root}/var/lib/pacman/
CacheDir     = ${root}/var/cache/pacman/pkg/
LogFile      = ${root}/var/log/pacman.log
GPGDir       = ${root}/etc/pacman.d/gnupg/
HookDir      = ${root}/etc/pacman.d/hooks/
Architecture = aarch64"
pacman_mirrors="
[core]
Server = ${repo_url_alarm_aarch64}
[extra]
Server = ${repo_url_alarm_aarch64}
[alarm]
Server = ${repo_url_alarm_aarch64}
[aur]
Server = ${repo_url_alarm_aarch64}"

echo "[options]${pacman_config}
SigLevel = Never${pacman_mirrors}" > cache/pacman-loose.conf

echo "[options]${pacman_config}
SigLevel = DatabaseOptional${pacman_mirrors}
[7Ji]
Server = ${repo_url_7Ji_aarch64}" > cache/pacman-strict.conf

# Base system
sudo bin/pacman -Sy --config cache/pacman-loose.conf --noconfirm base archlinuxarm-keyring
# Add my repo
sudo tee -a "${root}"/etc/pacman.conf << _EOF_
[7Ji]
Server = https://github.com/7Ji/archrepo/releases/download/\$arch
_EOF_
# Temporary network
sudo mount --bind /etc/resolv.conf "${root}"/etc/resolv.conf
# Keyring
run_in_chroot pacman-key --init
run_in_chroot pacman-key --populate archlinuxarm
run_in_chroot pacman-key --recv-keys BA27F219383BB875
run_in_chroot pacman-key --lsign BA27F219383BB875

# Non-base packages
kernel='linux-aarch64-flippy'
kernel_alt='linux-aarch64-7ji'
sudo bin/pacman -Syu --config cache/pacman-strict.conf --noconfirm \
    vim nano sudo openssh \
    "${kernel}"{,-dtb-amlogic} "${kernel_alt}" \
    linux-firmware-amlogic-ophub \
    uboot-legacy-initrd-hooks \
    uboot-amlogic-ophub \
    ampart yaopenvfd

# Pacman-key expects to run in an actual system, it pulled up gpg-agent and it kept running
run_in_chroot killall -s KILL gpg-agent dirmngr

# /etc/fstab
sudo tee -a "${root}"/etc/fstab << _EOF_
# root partition with ext4 on SDcard / USB drive
UUID=${uuid_root}	/	ext4	rw,noatime	0 1
# boot partition with vfat on SDcard / USB drive
UUID=${uuid_boot_specifier}	/boot	vfat	rw,noatime	0 2
_EOF_

# Time
sudo ln -sf "/usr/share/zoneinfo/UTC" "${root}"/etc/localtime

# Locale
sudo sed -i 's/^#\(en_US.UTF-8  \)$/\1/g' "${root}"/etc/locale.gen
sudo tee "${root}"/etc/locale.conf <<< LANG=en_US.UTF-8
run_in_chroot locale-gen

# Network
sudo tee "${root}"/etc/hostname <<< alarm
printf '127.0.0.1\tlocalhost\n::1\t\tlocalhost\n' | sudo tee -a "${root}"/etc/hosts
printf '[Match]\nName=eth* en*\n\n[Network]\nDHCP=yes\nDNSSEC=no\n' | 
    sudo tee "${root}"/etc/systemd/network/20-wired.network

# Units
run_in_chroot systemctl enable systemd-{network,resolve,timesync}d sshd

# Users
run_in_chroot useradd -g wheel -m alarm
run_in_chroot /bin/sh -c 'printf "%s\n" alarm_please_change_me alarm_please_change_me | passwd alarm'
sudoers="${root}"/etc/sudoers
sudo chmod o+w "${sudoers}"
sudo sed -i 's|^# %wheel ALL=(ALL:ALL) ALL$|%wheel ALL=(ALL:ALL) ALL|g' "${sudoers}"
sudo chmod o-w "${sudoers}"

# QoL: vim link
sudo ln -sf 'vim' "${root}"/usr/bin/vi

# Actual resolv
sudo umount "${root}"/etc/resolv.conf
sudo ln -sf /run/systemd/resolve/resolv.conf "${root}"/etc/resolv.conf

# Booting configuration
boot="${root}"/boot
for script in ../booting/*.sh; do
    name=$(basename "$script")
    if [ "${name}" == 'boot.sh' ]; then
        name="${name%.sh}.scr"
    else
        name="${name%.sh}"
    fi
    sudo mkimage -A arm64 -O linux -T script -C none -d "${script}" "${boot}/${name}" > /dev/null
done
sudo mkdir "${root}"/boot/extlinux
conf_linux="vmlinuz-${kernel}"
conf_initrd="initramfs-${kernel}-fallback.uimg"
conf_fdt="dtbs/${kernel}/amlogic/PLEASE_SET_YOUR_DTB.dtb"
conf_append="root=UUID=${uuid_root} rw audit=0 apt_blkdevs=mmcblk2"
printf \
    "LABEL\t%s\nLINUX\t/%s\nINITRD\t/%s\nFDT\t/%s\nAPPEND\t%s\n"\
    'Arch Linux for Amlogic S9XXX TV Boxes'\
    "${conf_linux}"\
    "${conf_initrd}"\
    "${conf_fdt}"\
    "${conf_append}" | 
    sudo tee "${root}"/boot/extlinux/extlinux.conf
printf \
    "LINUX=/%s\nINITRD=/%s\nFDT=/%s\nAPPEND=%s\n"\
    "${conf_linux}"\
    "${conf_initrd}"\
    "${conf_fdt}"\
    "${conf_append}" | 
    sudo tee "${root}"/boot/uEnv.txt

# Clean up
sudo rm -rf "${root}"/var/cache/pacman/pkg/*
sudo rm -f "${root}"/boot/initramfs-{"${kernel}","${kernel_alt}"}{.{u,}img,-fallback.img}
sudo dd if=/dev/zero of="${root}"/.zerofill bs=16M || true
sudo dd if=/dev/zero of="${root}"/boot/.zerofill bs=16M || true
sudo rm -f "${root}"/{,boot/}.zerofill
# Partially release resources
sudo umount -R "${root}"/{proc,sys,dev,run,tmp}

# Root archive
(
    cd ${root}
    sudo bsdtar --acls --xattrs -cpf - *
) > out/"${build_id}"-root.tar
# Release resources
sudo umount -R "${root}"
root=
sudo losetup --detach "${lodev}"
lodev=
suffixes=(
    'root.tar'
    'base.img'
)

kill -s TERM ${pid_pacoloco} || true
pid_pacoloco=
pids_gzip=()
rm -rf out/latest
mkdir out/latest
for suffix in "${suffixes[@]}"; do
    gzip -9 out/"${build_id}-${suffix}" &
    pids_gzip+=($!)
    ln -s ../"${build_id}-${suffix}".gz out/latest/
done
echo "Waiting for gzip processes to end..."
wait ${pids_gzip[@]}
popd