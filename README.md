# ArchLinux ARM for Amlogic s9xxx devices

## Installation / 安装
*Note only generic image is provided in this project, as there's no SoC-specific things. Everything is kept as simple and lightweight as possible, with most of details leaving to yourself to decide  
注意本项目只提供通用镜像，项目中没有对应各SoC专有的东西。所有的细节都被控制得尽可能简单和轻量化，大多数细节都留给你自己去做决定*

Two different kinds of releases are available  
有两种类型的发布可用
 - ``ArchLinuxARM-aarch64-Amlogic-*.img.xz`` is just like the normal image you would find in the Armbian and Openwrt projects, where you should just decompress and burn it to a SD card / USB drive. The layout is hard-coded but it's therefore easy to use because you do not need to worry about partitioning  
`ArchLinuxARM-aarch64-Amlogic-*.img.xz`就和你能在Armbian和Openwrt项目里找到的普通镜像一样，只要解压后写到SD卡或者是USB驱动器上就能用。布局是写死的，不过也因此很简单，因为你不需要担心分区的问题。
 - ``ArchLinuxARM-aarch64-Amlogic-*.tar.xz`` is a compressed archive of the rootfs, it can be decompressed to an already partitioned disk so you can freely decide the partition layout and size, but you need to update ``/etc/fstab``, ``/boot/uEnv.txt``, ``/boot/extlinux/extlinux.conf`` according to your actual partitions. Use the following command to extract the archive:  
``ArchLinuxARM-aarch64-Amlogic-*.tar.xz`` 是压缩过的根文件系统的归档，可以把它解压到已经分区过的盘里，这样你就可以自由地决定分区布局和大小了，不过你需要根据你的实际分区来更新``/etc/fstab``, ``/boot/uEnv.txt``, ``/boot/extlinux/extlinux.conf``。用下面这条命令来提取归档：
    ```
    bsdtar -C /your/root --acls --xattrs -xvpf /the/archive.tar.xz
    ```

After you flash the image, you should open the FAT32 first/boot partition with label ``ALARMBOOT``, and do the following adjustment:  
当你写入镜像以后，你应该打开FAT32的卷标是`ALARMBOOT`的第一个/启动分区分区，然后做以下调整
 - Find a corresponding u-boot in the folder ``uboot``, copy/move it as ``u-boot.ext`` in the root of the partition. You can then safely delete the ``uboot`` folder if you want to save space  
在`uboot`文件夹中找到对应的u-boot，把它复制或移动到这个分区的根目录。然后如果你想节约空间的话，你可以放心地把`uboot`文件夹删掉
 - Edit ``uEnv.txt``, change the line  
编辑``uEnv.txt``，把这行
    ```
    FDT=/dtbs/linux-aarch64-flippy/amlogic/PLEASE_SET_YOUR_DTB.dtb
    ```
    according to your actual device and the corresponding file under ``/dtbs/linux-aarch64-flippy/amlogic``, e.g. for HK1Box this should be changed to:  
    根据你实际的设备和``/dtbs/linux-aarch64-flippy/amlogic``下对应的文件修改。比如，HK1Box应该改成：
    ```
    FDT=/dtbs/linux-aarch64-flippy/amlogic/meson-sm1-hk1box-vontar-x3.dtb
    ```
 - Edit ``extlinux/extlinux.conf``, change the line  
 编辑``extlinux/extlinux.conf``，把这行
    ```
    FDT     /dtbs/linux-aarch64-flippy/amlogic/PLEASE_SET_YOUR_DTB.dtb
    ```
    to like this, with the same idea
    以相同的思路改成像这样
    ```
    FDT     /dtbs/linux-aarch64-flippy/amlogic/meson-sm1-hk1box-vontar-x3.dtb
    ```
Holding the reset button with the SD card / USB drive plugged in, and power on the box, just like how you would do with Armbian and Openwrt.  
按住重置键，保持SD卡/USB驱动器插入，给盒子上电，就和你在Armbian和Openwrt上那样做的一样

By default, `systemd-networkd.service` and `systemd-resolved.service` are enabled, and DHCP is enabled on ``eth*``, you can check your router to get the box's IP  
默认情况下`systemd-networkd.service`和`systemd-resolved.service`都已启用，DHCP在`eth*`上启动，你可以到你的路由器上去查询盒子的IP

By default, `sshd.service` is enabled, and root login is permitted, whose password `please_change_me`  
默认情况下`sshd.service`已启用，且允许root登录，root的密码是`alarm_please_change_me`

By default, there's a user ``alarm`` in the group ``wheel`` and can use `sudo` with password. The user has a password `please_change_me`.
默认情况下，有一个组为`wheel`的用户`alarm`，可以在输入密码后使用`sudo`。这个用户的密码是`alarm_please_change_me`

It's recommended to do a full upgrade right after you boot:  
建议你开机后立即进行一次全局升级：
```
pacman -Syu
```
And generate the initramfs, since only the u-boot legacy initrd fallback image is kept to save space, all other 3 initramfs were deleted before packing (standard default, standard fallback and legacy default):  
并立即生成初始化内存盘，因为为了节约空间，只有u-boot传统内存盘的回落镜像被保留，其他三个初始化内存盘都在打包前删掉了（标准默认配置。标准回落配置和传统默认配置）
```
mkinitcpio -P
```
Depending on your booting configuration you can choose whether to keep the u-boot legacy initrd or not: https://7ji.github.io/embedded/2022/11/11/amlogic-booting.html.  
根据你的启动配置，你可以选择是否保留u-boot传统初始化内存盘：https://7ji.github.io/embedded/2022/11/11/amlogic-booting.html. 
 - If you use standard initramfs, you can save space for two initramfs. You'll need to use ``/boot/extlinux/extlinux.conf`` as the configuration, and delete ``/boot/boot.scr``  
 如果你使用标准的初始化内存盘，你能省出两个初始化内存盘的空间，你需要用``/boot/extlinux/extlinux.conf``作为配置文件，并删除``boot.scr``  
    The following line in ``/boot/extlinux/extlinux.conf`` needs to be updated:  
    ``/boot/extlinux/extlinux.conf``里面的这一行需要更新
    ```
    INITRD  /initramfs-linux-aarch64-flippy-fallback.uimg
    ```
    to  
    成这样
    ```
    INITRD  /initramfs-linux-aarch64-flippy.img
    ```
    And the hooks for u-boot legacy initrd can be moved  
    生成传统内存镜像的钩子可以被移除
    ```
    pacman -R uboot-legacy-initrd-hooks
    ```
 - If you want to keep using the u-boot initrd, you need to take care of the extra space occupied by the legacy u-boot initrd  
 如果你想要继续用uboot传统内存盘的话，你需要注意传统内存盘额外占用的空间  
 The hooks provided by my AUR package [uboot-legacy-initrd-hooks](https://aur.archlinux.org/packages/uboot-legacy-initrd-hooks) will automatically convert initramfs to u-boot legacy initrd, which comes pre-installed by default  
 我的AUR包[uboot-legacy-initrd-hooks](https://aur.archlinux.org/packages/uboot-legacy-initrd-hooks)提供的钩子会自动把初始化内存盘转换为u-boot传统内存盘，默认已经预装  
 For cases where you update the initramfs by yourself without the hooks (e.g. manually running ``mkinitcpio -P``), remember to invoke the script to also update the legacy initrd  
 在你自己不经过钩子手动更新初始化内存盘的情况下（比如，手动运行``mkinitcpio -P``），记得调用脚本也把传统内存盘更新
    ```
    img2uimg
    ```

## Build / 构建
The script **must be run on an AArch64 device natively, with either ArchLinux ARM itself or derived distros like Manajaro**, as some AUR packages need to built natively, and the package manager Pacman should also be run natively. Your could just use the images here or follow [my guide on my blog](https://7ji.github.io/embedded/2022/11/08/alarm-install.html) to bootstrap a working ArchLinux ARM installation.  
构建脚本**必须在AArch64设备上原生运行，或者是ArchLinux ARM自己或者是衍生吗兴办比如Manjaro**，因为有的AUR包需要被原生构建，并且包管理器Pacman也应该被原生运行。你可以用这里的镜像或者照着[我博客上的文章](https://7ji.github.io/embedded/2022/11/08/alarm-install.html) 来自举一个可以工作的ArchLinux ARM安装

Before the first build, some packages might need to be installed if you haven't installed them yet:  
首次构建前，如果你没装的话，有的包必需被安装
```
sudo pacman -Syu base-devel git wget parted arch-install-scripts
```

When cloning the repo, remember to register all of the submodules and update them first. Otherwise the AUR packages would fail to build because of missing ``PKGBUILD``  
克隆仓库的时候，记得先注册所有的子模块并更新。不然的话AUR包会因为找不到``PKGBUILD``而构建失败
```
git clone https://github.com/7Ji/amlogic-s9xxx-alarm
git submodule init
git submodule update
```

After you get your local repo ready, all it needs is a simple ``./build.sh`` to build the image  
当你本地的仓库就绪后，只需要一条简单的``./build.sh``就能构建镜像了
```
./build.sh
```

There're some environment variables you could set to define the behaviours:  
你可以设置一些环境便利那个来决定行为
 - ``SKIP_XZ``
   - if set to yes, then the archive and image won't be compressed. So you could compress them on e.g. your more powerful x86-64 host
   - 如果设置为yes，归档和镜像不会被压缩。那样的话你就能在比如说你强大的x86-64主机上来压缩
 - ``SKIP_AUR``
   - if set to yes, then AUR packages won't be re-built. This is recommended for rebuilds when you already have built AUR packages under ``pkg``.
   - 如果设置为yes，那么AUR包不会被重新构建。对于你已经在`pkg`下有构建好的AUR包的情况下重新构建来说是建议的

So time spent on rebuilds can be set with a build command like this:  
那么重新构建的时候如果这么写命令，花的时间就会更少
```
SKIP_AUR=yes SKIP_XZ=yes ./build.sh
```
Or like this  
或者像这样
```
export SKIP_AUR=yes
export SKIP_XZ=yes
./build.sh
```