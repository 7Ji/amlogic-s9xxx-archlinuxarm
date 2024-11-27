# ArchLinux ARM for Amlogic s9xxx devices

**This is not an official release of ArchLinuxARM, but only a pre-built flash-and-boot image of it for Amlogic platform for generic s9xxx boxes due to some kernel quirks needed to make it bootable on these devices not merged in mainline kernel**

## Information

**Please only use the image provided in this project as live environment to install another ArchLinuxARM with pacstrap, not as your daily driver. A pre-defined ArchLinux is never an ArchLinux experience intended. I've made some decisions on configuration and packages to make the image bootable, these are probably not what you really want for your system.**

## Installation

### Drive
Installing on USB drive is more recommended, and then [alarm-install](https://7ji.github.io/embedded/2022/11/08/alarm-install.html) can be referred to to install to eMMC or to another USB drive/SD card **in the ArchLinux way**

### Releases & Images
All Amlogic s9xxx devices **share the same generic image**, i.e. there is **no default u-boot.ext and dtb** set, and you must set them according to your device. And take care dtb should be set both in ``uEnv.txt`` and ``extlinux/extlinux.conf``

Three different kinds of releases are available, which you can download either from [releases](../../releases) directly, or from [actions](../../actions) where all three of them are zipped into one artifact:
 - `*.img` is just like the normal image you would find in the Armbian and Openwrt projects, where you should just decompress and burn it to a SD card / USB drive. The layout is hard-coded but it's therefore easy to use because you do not need to worry about partitioning
 - `*-root.tar` is a compressed archive of the rootfs, it can be decompressed to an already partitioned disk so you can freely decide the partition layout and size, but you need to update ``/etc/fstab``, ``/boot/uEnv.txt``, ``/boot/extlinux/extlinux.conf`` according to your actual partitions. Use the following command to extract the archive:
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
