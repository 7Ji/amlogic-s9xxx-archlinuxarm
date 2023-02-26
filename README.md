# ArchLinux ARM for Amlogic s9xxx devices
[中文文档](README_cn.md)

**This is not an official release of ArchLinuxARM, but only a pre-built flash-and-boot image of it for Amlogic platform for generirc s9xxx boxes due to some kernel quirks needed to make it bootable on these devices not merged in mainline kernel**

## Information

**Please only use the image provided in this project as live environment to install another ArchLinuxARM with pacstrap, not as your daily driver. A pre-defined ArchLinux is never an ArchLinux experience intended. I've made some decisions on configuration and packages to make the image bootable, these are probably not what you really want for your system. Refer to the [installation guide on my blog][alarm guide on blog] for how to install in Arch way.**

[alarm guide on blog]: https://7ji.github.io/embedded/2022/11/08/alarm-install.html

## Installation

### Drive
Installing on USB drive is more recommended, and then [alarm-install][alarm guide on blog] can be referred to to install to eMMC or to another USB drive/SD card **in the ArchLinux way**

### Releases & Images
All Amlogic s9xxx devices **share the same generic image**, i.e. there is **no default u-boot.ext and dtb** set, and you must set them according to your device. And take care dtb should be set both in ``uEnv.txt`` and ``extlinux/extlinux.conf``

Three different kinds of releases are available
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
        生成传统内存镜像的钩子可以被移除
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
The script **must be run on an AArch64 device natively, and on either ArchLinux ARM itself or derived distros like Manjaro ARM**, as our AUR packages need to built natively, and the package manager Pacman should also be run natively to install them and other essential packages. Unless you want to leave a lot of binaries not tracked by the package manager (**very dangerous, and not the Arch way**), this is the way to go.

Your could just use the images here or follow [my guide on my blog](https://7ji.github.io/embedded/2022/11/08/alarm-install.html) to bootstrap a working ArchLinux ARM installation from ground up to be used as the build environment.

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

After you get your local repo ready, all it needs is a simple ``./build.sh`` to build the image
```
./build.sh
```
Or if you prefer to prefix it with the corresponding shell (**`-e`** flash must be set):
```
bash -e build.sh
```
*The script should be run as a user that can use `sudo`, as it will run some high risk commands with `sudo` instead of always running as `root`. It will refuse to work if being run as `root` or with `sudo`. You might need to to set the following option in `sudoers` if you want to keep it in background to cancel the timeout:*
```
Defaults passwd_timeout=0
```

There're some environment variables you could set to define the behaviours:
 - ``compressor``
   - A combination of compressor executable and optional argument (e.g. `gzip` for compressing with gzip with default options, `xz -9e` for compressing with xz with maximum compression)
   - If set to no, then the archive and image won't be compressed.

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
