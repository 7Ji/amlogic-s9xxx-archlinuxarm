# ArchLinux ARM for Amlogic s9xxx devices
**This is not an official release of ArchLinuxARM, but only a pre-built flash-and-boot image of it for Amlogic platform for generirc s9xxx boxes due to some kernel quirks needed to make it bootable on these devices not merged in mainline kernel  
本项目不是ArchLinuxARM的官方发行，而是预构建的可刷写并启动的用于晶晨平台的普通s9xxx盒子的镜像，项目存在的原因是有很多需要对内核作出的没有合并到官方仓库用的主线内核的修改**

## Information / 信息

**Please only use the image provided in this project as live environment to install another ArchLinuxARM with pacstrap, not as your daily driver. A pre-defined ArchLinux is never an ArchLinux experience intended. I've made some decisions on configuration and packages to make the image bootable, these are probably not what you really want for your system. Refer to the [installation guide on my blog][alarm guide on blog] for how to install in Arch way.  
请仅使用本项目提供的镜像作为用pacstrap安装另一个ArchLinuxARM的live环境，而不是日常系统。预定义的ArchLinux带来的不是真正的ArchLinux的体验。为了让镜像能启动，我替你做了不少配置和包上的决定，而这些决定恐怕不是你真的想在你的系统上所要的。参考[我博客上的安装指南][alarm guide on blog]来了解怎么在晶晨平台上以Arch的方式安装**

[alarm guide on blog]: https://7ji.github.io/embedded/2022/11/08/alarm-install.html

## Installation / 安装

### Drive / 驱动器
Installing on USB drive is more recommended, and then [alarm-install][alarm guide on blog] can be referred to to install to eMMC or to another USB drive/SD card **in the ArchLinux way**  
建议安装在USB驱动器上，然后可以参考[alarm-install][alarm guide on blog]使用**ArchLinux的方式**来安装到eMMC或者另一个USB驱动器/SD卡上

### Releases & Images / 发行与镜像

All Amlogic s9xxx devices **share the same generic image**, i.e. there is **no default u-boot.ext and dtb** set, and you must set them according to your device. And take care dtb should be set both in ``uEnv.txt`` and ``extlinux/extlinux.conf``  
所有的Amlogic s9xxx设备**共用同一个通用镜像**，也就是说镜像里**没有设置默认的u-boot.ext和dtb**，你必须根据你的设备设置。并请注意dtb需要在``uEnv.txt``和``extlinux/extlinux.conf``里一并设置

Two different kinds of releases are available  
有两种类型的发布可用
 - ``ArchLinuxARM-aarch64-Amlogic-*.img.xz`` is just like the normal image you would find in the Armbian and Openwrt projects, where you should just decompress and burn it to a SD card / USB drive. The layout is hard-coded but it's therefore easy to use because you do not need to worry about partitioning  
`ArchLinuxARM-aarch64-Amlogic-*.img.xz`就和你能在Armbian和Openwrt项目里找到的普通镜像一样，只要解压后写到SD卡或者是USB驱动器上就能用。布局是写死的，不过也因此很简单，因为你不需要担心分区的问题。
 - ``ArchLinuxARM-aarch64-Amlogic-*-root.tar.xz`` is a compressed archive of the rootfs, it can be decompressed to an already partitioned disk so you can freely decide the partition layout and size, but you need to update ``/etc/fstab``, ``/boot/uEnv.txt``, ``/boot/extlinux/extlinux.conf`` according to your actual partitions. Use the following command to extract the archive:  
``ArchLinuxARM-aarch64-Amlogic-*-root.tar.xz`` 是压缩过的根文件系统的归档，可以把它解压到已经分区过的盘里，这样你就可以自由地决定分区布局和大小了，不过你需要根据你的实际分区来更新``/etc/fstab``, ``/boot/uEnv.txt``, ``/boot/extlinux/extlinux.conf``。用下面这条命令来提取归档：
    ```
    bsdtar -C /your/root --acls --xattrs -xvpf /the/archive.tar.xz
    ```

There's also an addtional artifact that's available on the release page:  
发布页还有另外一种资源
 - `ArchLinuxARM-aarch64-Amlogic-*-pkgs.tar.xz` is a compressed archive of the AUR packages built and installed into the above image. You can download it and upgrade your packages with the files in it with `pacman -U`, if you don't want to built them by yourself when upgrading.  
`ArchLinuxARM-aarch64-Amlogic-*-pkgs.tar.xz`是压缩过的构建并安装到上面镜像里的AUR包。如果你升级的时候不想自己构建，你可以下载、解压，再用`pacman -U`安装里面现成的包。

### Bootup setup / 启动配置
After you flash the image, you should open the FAT32 first/boot partition with label ``ALARMBOOT``, and do the following adjustment:  
当你写入镜像以后，你应该打开FAT32的卷标是`ALARMBOOT`的第一个/启动分区分区，然后做以下调整
 - Find a corresponding u-boot in the folder ``uboot``, copy/move it as ``u-boot.ext`` in the root of the partition. You can then safely delete the ``uboot`` folder if you want to save space  
在`uboot`文件夹中找到对应的u-boot，把它改名为``u-boot.ext``复制或移动到这个分区的根目录。然后如果你想节约空间的话，你可以放心地把`uboot`文件夹删掉
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
### Booting / 启动
Holding the reset button with the SD card / USB drive plugged in, and power on the box, just like how you would do with Armbian and Openwrt.  
按住重置键，保持SD卡/USB驱动器插入，给盒子上电，就和你在Armbian和Openwrt上那样做的一样

### Connection / 连接

#### Network / 网络
By default, `systemd-networkd.service` and `systemd-resolved.service` are enabled, and DHCP is enabled on ``eth*``, you can check your router to get the box's IP  
默认情况下`systemd-networkd.service`和`systemd-resolved.service`都已启用，DHCP在`eth*`上启动，你可以到你的路由器上去查询盒子的IP

#### SSH
By default, `sshd.service` is enabled, and root login is permitted, whose password `alarm_please_change_me`  
默认情况下`sshd.service`已启用，且允许root登录，root的密码是`alarm_please_change_me`

#### Users / 用户
By default, there's a user ``alarm`` in the group ``wheel`` and can use `sudo` with password. The user has a password `alarm_please_change_me`.  
默认情况下，有一个组为`wheel`的用户`alarm`，可以在输入密码后使用`sudo`。这个用户的密码是`alarm_please_change_me`


### Upgrade / 升级
#### Packages / 包
It's recommended to do a full upgrade right after you boot:  
建议你开机后立即进行一次全局升级：
```
sudo pacman -Syu
```
or (``yay`` without argument calls ``sudo pacman -Syu`` implicitly)  
或者（不带任何参数的``yay``隐式调用``sudo pacman -Syu``）
```
yay
```
#### Initramfs / 初始化内存盘
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
The script **must be run on an AArch64 device natively, and on either ArchLinux ARM itself or derived distros like Manjaro ARM**, as our AUR packages need to built natively, and the package manager Pacman should also be run natively to install them and other essential packages. Unless you want to leave a lot of binaries not tracked by the package manager (**very dangerous, and not the Arch way**), this is the way to go.  
构建脚本**必须在装有ArchLinux ARM自己或者是Manjaro ARM等衍生发行版的AArch64设备上原生运行**，因为有的AUR包需要被原生构建，并且包管理器Pacman也应且仅应当该被原生运行来安装它们还有其他的必要包。除非你想整一堆包管理器追踪不到的文件（**非常危险，而且根本不是Arch的风格**），不然这就是正确的唯一路子。

Your could just use the images here or follow [my guide on my blog](https://7ji.github.io/embedded/2022/11/08/alarm-install.html) to bootstrap a working ArchLinux ARM installation from ground up to be used as the build environment.  
你可以用这里的镜像或者照着[我博客上的文章](https://7ji.github.io/embedded/2022/11/08/alarm-install.html) 来从头自举一个可以工作的ArchLinux ARM安装来当作构建环境

Be sure to setup distcc with other more powerful machines (e.g. your x86-64 server) as voluenteers beforehand, following [the documentation on ArchWiki][Arch Wiki distcc]. The AArch64 devices themselves are too weak and slow to build just by themselves.  
记得提前根据[ArchWiki上的文档][Arch Wiki distcc]设置好distcc，用其他更强大的机子（比如说你的x86-64的服务器）作为构建志愿者。AArch64设备本身太弱了，单纯用它们构建很慢。

Before the first build, make sure these build dependencies are installed:  
首次构建前，确保这些构建依赖已经安装
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
克隆仓库的时候，记得先注册所有的子模块并更新。不然的话AUR包会因为找不到``PKGBUILD``而构建失败。选项`--recursive`可以自动在克隆期间处理这些琐事
```
git clone --recursive https://github.com/7Ji/amlogic-s9xxx-archlinuxarm.git
```

_When pulling the update, you need to run `git submodule update` to also update the submodules  
拉取更新时，也需要用`git submodule update`来更新子模块_
```
git pull
git submodule update
```

After you get your local repo ready, all it needs is a simple ``./build.sh`` to build the image  
当你本地的仓库就绪后，只需要一条简单的``./build.sh``就能构建镜像了
```
./build.sh
```
Or if you prefer to prefix it with the corresponding shell (**`-e`** flash must be set):  
或者你更喜欢在前面加上对应的shell的话（必须设置 **`-e`** 标志）
```
bash -e build.sh
```
*The script should be run as a user that can use `sudo`, as it will run some high risk commands with `sudo` instead of always running as `root`. It will refuse to work if being run as `root` or with `sudo`. You might need to to set the following option in `sudoers` if you want to keep it in background to cancel the timeout:  
这个脚本应当以一个能用`sudo`的用户的身份运行，因为它会通过`sudo`运行一些高风险的命令，而不是一直作为`root`运行，如果以`root`身份或者是通过`sudo`，脚本会拒绝工作。如果你要让脚本在后台运行的话，你可能需要在`sudoers`里添加以下选项来取消超时：*
```
Defaults passwd_timeout=0
```

There're some environment variables you could set to define the behaviours:  
你可以设置一些环境变量来决定行为
 - ``compressor``
   - A combination of compressor executable and optional argument (e.g. `gzip` for compressing with gzip with default options, `xz -9e` for compressing with xz with maximum compression)  
   压缩程序的执行文件名以及可选的参数（比如，`gzip`就是用gzip以默认选项压缩，`xz -9e`就是用xz以最大压缩率压缩）
   - If set to no, then the archive and image won't be compressed.  
   如果设置为no，归档和镜像不会被压缩。那样的话你就能在比如说你强大的x86-64主机上来压缩

## Sources / 来源

U-boot unpacked to ``/boot/uboot`` are downloaded during building from [ophub's Armbian repo][Armbian u-boot overload]  
释放到``/boot/uboot``的u-boot是在构建过程中自[ophub的 Armbian仓库][Armbian u-boot overload]下载的

Scripts and configuration under ``/boot`` are also adapted from [ophub's Armbian repo][Armbian boot common] but directly maintained here  
``/boot``下的脚本和配置也是从[ophub的Armbian仓库][Armbian boot common]修改适配而来，不过直接在这里维护


AUR package [ampart-git][AUR ampart-git], [linux-aarch64-flippy-bin][AUR linux-aarch64-flippy-bin], [linux-firmware-amlogic-ophub][AUR linux-firmware-amlogic-ophub] and [uboot-legacy-initrd-hooks][AUR uboot-legacy-initrd-hooks] are from my AUR.  
AUR包[ampart-git][AUR ampart-git], [linux-aarch64-flippy-bin][AUR linux-aarch64-flippy-bin], [linux-firmware-amlogic-ophub][AUR linux-firmware-amlogic-ophub]和 [uboot-legacy-initrd-hooks][AUR uboot-legacy-initrd-hooks]都来自我的AUR.

AUR package [yay][AUR yay] is from its author's AUR  
AUR包[yay][AUR yay]来自于其作者的AUR

[Arch Wiki distcc]: https://wiki.archlinux.org/title/Distcc#Arch_Linux_ARM_as_clients_(x86_64_as_volunteers)

[Armbian u-boot overload]: https://github.com/ophub/amlogic-s9xxx-armbian/tree/main/build-armbian/amlogic-u-boot/overload
[Armbian boot common]: https://github.com/ophub/amlogic-s9xxx-armbian/blob/main/build-armbian/amlogic-armbian/boot-common.tar.xz


[AUR ampart-git]: https://aur.archlinux.org/packages/ampart-git
[AUR linux-aarch64-flippy-bin]: https://aur.archlinux.org/packages/linux-aarch64-flippy-bin
[AUR linux-firmware-amlogic-ophub]: https://aur.archlinux.org/packages/linux-firmware-amlogic-ophub
[AUR uboot-legacy-initrd-hooks]: https://aur.archlinux.org/packages/uboot-legacy-initrd-hooks
[AUR yay]: https://aur.archlinux.org/packages/yay
