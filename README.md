# ArchLinux ARM for Amlogic s9xxx devices
[中文文档](README_cn.md)

**This is not an official release of ArchLinuxARM, but only a pre-built flash-and-boot image of it for Amlogic platform for generic s9xxx boxes due to some kernel quirks needed to make it bootable on these devices not merged in mainline kernel**

## Information

**Please only use the image provided in this project as live environment to install another ArchLinuxARM with pacstrap, not as your daily driver. A pre-defined ArchLinux is never an ArchLinux experience intended. I've made some decisions on configuration and packages to make the image bootable, these are probably not what you really want for your system.**

## Installation

### Drive
Installing on USB drive is more recommended, and then [alarm-install][alarm guide on blog] can be referred to to install to eMMC or to another USB drive/SD card **in the ArchLinux way**

### Releases & Images
All Amlogic s9xxx devices **share the same generic image**, i.e. there is **no default u-boot.ext and dtb** set, and you must set them according to your device. And take care dtb should be set both in ``uEnv.txt`` and ``extlinux/extlinux.conf``

Three different kinds of releases are available, which you can download either from [releases](../../releases) directly, or from [actions](../../actions) where all three of them are zipped into one artifact:
 - ``ArchLinuxARM-aarch64-Amlogic-*.img.xz`` is just like the normal image you would find in the Armbian and Openwrt projects, where you should just decompress and burn it to a SD card / USB drive. The layout is hard-coded but it's therefore easy to use because you do not need to worry about partitioning
 - ``ArchLinuxARM-aarch64-Amlogic-*-root.tar.xz`` is a compressed archive of the rootfs, it can be decompressed to an already partitioned disk so you can freely decide the partition layout and size, but you need to update ``/etc/fstab``, ``/boot/uEnv.txt``, ``/boot/extlinux/extlinux.conf`` according to your actual partitions. Use the following command to extract the archive:
    ```
    bsdtar -C /your/root --acls --xattrs -xvpf /the/archive.tar.xz
    ```
 - `ArchLinuxARM-aarch64-Amlogic-*-pkgs.tar.xz` is a compressed archive of the AUR packages built and installed into the above image. You can download it and upgrade your packages with the files in it with `pacman -U`, if you don't want to built them by yourself when upgrading. It could also be used to `pacstrap` an installation by yourself.

### Bootup setup
After you flash the image, you should open the FAT32 first/boot partition with label ``ALARMBOOT``, and do the following adjustment:
 - Find a corresponding u-boot in the folder ``uboot``, copy/move it as ``u-boot.ext`` in the root of the partition. You can then safely delete the ``uboot`` folder if you want to save space
 - Edit ``uEnv.txt``, change the line
    ```
    FDT=/dtbs/linux-aarch64-flippy/amlogic/PLEASE_SET_YOUR_DTB.dtb
    ```
    according to your actual device and the corresponding file under ``/dtbs/linux-aarch64-flippy/amlogic``, e.g. for HK1Box this should be changed to:
    ```
    FDT=/dtbs/linux-aarch64-flippy/amlogic/meson-sm1-hk1box-vontar-x3.dtb
    ```
 - Similarly, edit ``extlinux/extlinux.conf``, change the line
    ```
    FDT     /dtbs/linux-aarch64-flippy/amlogic/PLEASE_SET_YOUR_DTB.dtb
    ```
    to like this
    ```
    FDT     /dtbs/linux-aarch64-flippy/amlogic/meson-sm1-hk1box-vontar-x3.dtb
    ```

### Alternative kernel
There're two kernels pre-installed in the image, `linux-aarch64-flippy` and `linux-aarch64-7ji`, both maintained by myself. Unlike official `linux-aarch64` from ArchLinux ARM, multiple kernels can exist side-by-side in my images.

Between them `-flippy` is the default one, currently using https://github.com/unifreq/linux-6.1.y as upstream, as the name suggests it's based on the `LTS` 6.1 kernel. It's verified by the long-passed time as stable enough for Amlogic platforms, but it's also lagged behind in versioning.

A seperate kernel `linux-aarch64-7ji` , upstream https://github.com/7ji/linux branch `amlogic`, is added using my own kernel tree with minimum diffrences from the actual mainline tree (stable at kernel.org), starting at version `6.4.3`. As a result of minimum diffrences this lack a lot of non-mainstream dts not maintained upstream but only in flippy tree.

You can modify `/boot/extlinux/extlinux.conf` or `/boot/uEnv.txt` depending on your bootup scheme to change `-flippy` to `-7ji` to use the sort-of mainline kernel, and can change back at any time. An example `extlinux.conf`:

```
LABEL   Arch Linux ARM
LINUX   /vmlinuz-linux-aarch64-7ji
INITRD  /initramfs-linux-aarch64-7ji-fallback.uimg
FDT     /dtbs/linux-aarch64-7ji/amlogic/meson-gxbb-p201.dtb
APPEND  root=UUID=c0655cfd-5797-4606-8a8e-7220e04e6170 rw audit=0
```

Sicne the two kernels can exist side-by-side, you can also use dtbs from the flippy kernel, so you get both the latest kernel and rich dtb library.

Please read or report at the following places:
 - https://github.com/7Ji/amlogic-s9xxx-archlinuxarm/issues/19 for issues regarding alternative kernels in this image
 - https://github.com/7ji/linux-aarch64-7ji for issues regarding the package itself
 - https://github.com/7ji/linux for issues regarding kernel itself


### Booting
Holding the reset button with the SD card / USB drive plugged in, and power on the box, just like how you would do with Armbian and Openwrt.

### Connection

#### Network
By default, `systemd-networkd.service` and `systemd-resolved.service` are enabled, and DHCP is enabled on `en*` and ``eth*``, you can check your router to get the box's IP

#### SSH
By default, `sshd.service` is enabled, and root login is permitted, whose password is `alarm_please_change_me`

#### Users
By default, there's a user ``alarm`` in the group ``wheel`` and can use `sudo` with password. The user has a password `alarm_please_change_me`

### Upgrade
#### Packages
It's recommended to do a full upgrade right after you boot:
```
sudo pacman -Syu
```
or (``yay`` without argument calls ``sudo pacman -Syu`` implicitly)
```
yay
```
**Note: some packages including the kernel package `linux-aarch64-flippy` are installed as local packages, as they are not available from the official repos, this means if you want to upgrade them, you'll have to do it one of the following ways:**
 1. Use AUR helpers like `yay`, they will build and install the packages for you. **You will have to spend a lot of time on building if your device or distcc network is not powerful enough**
 2. Download the build artifacts of the newest github action CI, unzip it and you'll get `*-pkgs.tar.xz`, you can extract all pre-built packages in the image, then use `pacman -U` to install them as local packages. **You do not need to build the packages**
 3. Add [my repo](https://github.com/7Ji/archrepo) as an additional pacman repo, read instructions on that repo on how to add it. You can then use `pacman -Syu` to update these packages. **You do not need to build the packages**

#### Initramfs
And generate the initramfs, since only the u-boot legacy initrd fallback image is kept to save space, all other 3 initramfs were deleted before packing (standard default, standard fallback and legacy default):
```
mkinitcpio -P
```
Depending on your booting configuration you can choose whether to keep the u-boot legacy initrd or not: https://7ji.github.io/embedded/2022/11/11/amlogic-booting.html.
 - If you use standard initramfs, you can save space for two initramfs. You'll need to use ``/boot/extlinux/extlinux.conf`` as the configuration.
     - ``/boot/boot.scr`` and `/boot/uEnv.txt` could be deleted
     - The following line in ``/boot/extlinux/extlinux.conf`` needs to be updated:
        ```
        INITRD  /initramfs-linux-aarch64-flippy-fallback.uimg
        ```
        to
        ```
        INITRD  /initramfs-linux-aarch64-flippy.img
        ```
        And the hooks for u-boot legacy initrd can be moved  
        ```
        pacman -R uboot-legacy-initrd-hooks
        ```
 - If you want to keep using the u-boot initrd, you need to take care of the extra space occupied by the legacy u-boot initrd
    - The hooks provided by my AUR package [uboot-legacy-initrd-hooks](https://aur.archlinux.org/packages/uboot-legacy-initrd-hooks) will automatically convert initramfs to u-boot legacy initrd, which comes pre-installed by default
    - For cases where you update the initramfs by yourself without the hooks (e.g. manually running ``mkinitcpio -P``), remember to invoke the script to also update the legacy initrd
      ```
      img2uimg
      ```

## Build
### Common
When cloning the repo, remember to register all of the submodules and update them first. Otherwise the AUR packages would fail to build because of missing ``PKGBUILD``. The option `--recursive` is enough for managing them during the clone.
```
git clone --recursive https://github.com/7Ji/amlogic-s9xxx-archlinuxarm.git
```

_When pulling the update, you need to run `git submodule update` to also update the submodules_
```
git pull
git submodule init
git submodule update
```

*All of the build scripts should be run as a user that can use `sudo` and **never as root**. They will refuse to work if being run as `root` or with `sudo`. You might need to to set the following option in `sudoers` if you want to keep it in background to cancel the timeout:*
```
Defaults passwd_timeout=0
```

There're some environment variables you could set to define the behaviours:
 - ``compressor``
   - A combination of compressor executable and optional argument (e.g. `gzip` for compressing with gzip with default options, `xz -9e` for compressing with xz with maximum compression)
   - If set to no, then the archive and image won't be compressed.

### Native (Recommended)
For native build on ARM platform, the script **must be run on an AArch64 device, with either ArchLinux ARM itself or derived distros like Manjaro ARM**, as our AUR packages need to built natively, and the package manager Pacman should also be run natively to install them and other essential packages. Unless you want to leave a lot of binaries not tracked by the package manager (**very dangerous, and not the Arch way**), this is the way to go.

Be sure to setup distcc with other more powerful machines (e.g. your x86-64 server) as voluenteers beforehand, following [the documentation on ArchWiki][Arch Wiki distcc]. The AArch64 devices themselves are too weak and slow to build just by themselves.

Before the first build, make sure these build dependencies are installed:
```
sudo pacman -Syu arch-install-scripts \
                 base-devel \
                 dosfstools \
                 git \
                 go \
                 parted \
                 uboot-tools \
                 xz \
                 wget 
```

After you get your local repo ready, all it needs is a simple ``./build.sh`` to build the image
```
./build.sh
```
### Cross
The build could also be done on a Debian-derived x86-64 platform, which is the case for the Github Actions configured on this repo (which is set to build on each push).

You could still do that on your own hardware though, but note there're more overheads since the script will need to deploy a whole ArchLinuxARM rootfs and an x86-64 hosted ArchLinux toolchain for AArch64 ArchLinuxARM target, and run distcc and a QEMU ALARM container side by side.

_It's also possible on ArchLinux, but since the script is written for Debian-derived and we deploy a whole ArchLinux toolchain, you probably would want to optimize by yourself_

Check [the CI file](.github/workflows/main.yml) to get an idea of how to set up the environment, basically you need to:

1. Install all of the dependencies:
   ```
   sudo apt update
   sudo apt install \
      arch-install-scripts \
      bc \
      bison \
      distcc \
      flex \
      libarchive-tools \
      libssl-dev \
      qemu-user-static \
      u-boot-tools
   ```
2. Setup symlinks for distcc
   ```
   for binary in c++ cc cpp g++ gcc; do
      sudo ln -sf ../../bin/distcc /usr/lib/distcc/aarch64-unknown-linux-gnu-${binary}
   done
   ```
   **Make sure there's no process using port 3632! At this point, distcc is hardcoded to use 3632 in the scripts**
3. Run the cross build script
   ```
   compressor=no ./cross.sh
   ```
   _If you do not set `compressor`, then the QEMU aarch64 machine will do the compression, which is very in-efficient_


## Sources

U-boot unpacked to ``/boot/uboot`` are downloaded during building from [ophub's Armbian repo][Armbian u-boot overload]

Scripts and configuration under ``/boot`` are also adapted from [ophub's Armbian repo][Armbian boot common] but directly maintained here

Packages [ampart-git][AUR ampart-git], [linux-aarch64-flippy-bin][AUR linux-aarch64-flippy-bin], [linux-firmware-amlogic-ophub][AUR linux-firmware-amlogic-ophub] and [uboot-legacy-initrd-hooks][AUR uboot-legacy-initrd-hooks] are AUR packages maintained by myself.

Package [yay][AUR yay] is from an AUR package maintained by its author

[Arch Wiki distcc]: https://wiki.archlinux.org/title/Distcc#Arch_Linux_ARM_as_clients_(x86_64_as_volunteers)

[Armbian u-boot overload]: https://github.com/ophub/amlogic-s9xxx-armbian/tree/main/build-armbian/amlogic-u-boot/overload
[Armbian boot common]: https://github.com/ophub/amlogic-s9xxx-armbian/blob/main/build-armbian/amlogic-armbian/boot-common.tar.xz


[AUR ampart-git]: https://aur.archlinux.org/packages/ampart-git
[AUR linux-aarch64-flippy-bin]: https://aur.archlinux.org/packages/linux-aarch64-flippy-bin
[AUR linux-firmware-amlogic-ophub]: https://aur.archlinux.org/packages/linux-firmware-amlogic-ophub
[AUR uboot-legacy-initrd-hooks]: https://aur.archlinux.org/packages/uboot-legacy-initrd-hooks
[AUR yay]: https://aur.archlinux.org/packages/yay
