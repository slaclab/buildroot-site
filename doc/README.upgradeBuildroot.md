# How to upgrade the Buildroot version

## Expected development time

If you need a basis to estimate how much time you need to bring a new version of Buildroot:
- Patch, configure, build Buildroot: 86 hours
- Configure and Build ATCA-related packages, including EPICS base: 42 hours
- Configure and build all ATCA-related modules: 

## First step
Download and untar the new Buildroot. It will be used by the files in this repository.

Below there is a description of where to make changes in this repository so the new untared Buildroot can be used.

## br-patches directory
This directory contains SLAC patches to files that are part the Buildroot tar gz. The script `scripts/br-installconf.sh` is responsible for applying these patches, not Buildroot. Their names *must* start with `buildroot-` so the script can find them. Try to use the naming convention `buildroot-<file name>-<description>.diff` when creating new diff files, so we understand its goal just by looking to its name. <description> can be something like enbl-symlinks or install-ldconfig.
The method to update the existent diff files is manual:
- Find the file referenced by the patch in the Buildroot directory (from the downloaded tar gz).
- Make a copy adding a .orig at the end of the file name, like `cp <file name> <file name>.orig`.
- Open the file (not the one ending with .orig) and search for the code snippet that the patch is modifying. You need to understand the context of the changes so you can decide if the current source code modification makes sense or if you need to adapt it to the new version. Check if what the patch proves is not already available in the new source code. There are moments when the patch is not needed in a new version of Buildroot and you can delete it.
- Save the changes.
- While in the Buildroot top directory (starting from this directory is important!), use `diff -Naur <file name>.orig <file name> > buildroot-<file name>-<description>.diff`. This will create your updated patch in the buildroot top directory. Move it to the br-patches directory, replacing the old one.
- Delete <file name> and `mv <file name>.orig <file name>` to return the file to its original state. Otherwise the patch will be applied on top of your manual changes.

Repeat this for all diff files in `br-patches`.

## br2-external directory
This directory is used to configure packages that are not included with Buildroot. Configuring it properly will make Buildroot download, build, and install these packages. Before 2025, this was used to bring eudev and usbip, but Buildroot 2025 already ships both, so the directory has no use at the moment. The files `Config.in`, `external.desc` and `external.mk`, and the directory packages/package-template contains only examples and commented lines if, in the future, this is needed again. [This chapter](https://buildroot.org/downloads/manual/manual.html#customize-packages) of the Buildroot manual explains how these files work. You can also checkout the `br-2019.08` branch to check how this was done for uedev and usbip.

### br2-external/configs
The `*.config` files in this directory are also used by the script `scripts/br-installconf.sh`, not directly by Buildroot. The script uses these files to generate a `<arch>_defconfig` file in the same directory. This new file is the one that will be used by the Buildroot machinery. To achieve this, the script calls `make BR2_EXTERNAL=site/br2-external ${ARCH}_defconfig`.

We will detail br-common.config on the next section. The architecture specific config files usually don't need changes if you are just upgrading Buildroot.

#### br-common.config
These are config customizations that affect all architectures. You may need to change it several times while iterating through Buildroot several times. `README.buildroot.modify_config` explains the process of using menuconfig to help with editing this file, but as a first start, you can manually edit these parameters:
- Go to the root of the Buildroot files that you untared earlier. Open the file linux/linux.hash and take note of the newest kernel supported by Buildroot.
- Copy the version number to the parameter `BR2_LINUX_KERNEL_VERSION` in the file `br2-external/configs/br-common.config`.
- In the file above, change the parameter `BR2_PACKAGE_HOST_LINUX_HEADERS_CUSTOM_6_12=y` to reflect the kernel version. For example, if the kernel version is 7.10.3, replace 6_12 with 7_10.
- For the URL with the RT_PREEMPT patch, go to the [Linux Foundation website](https://wiki.linuxfoundation.org/realtime/preempt_rt_versions) and search for the URL corresponding to your kernel version. Kernel version and PREEMPT_RT patch versions must match for all 3 numbers of the version. Add this URL to the parameter `BR2_LINUX_KERNEL_PATCH`. Keep the syntax of the parameter because it has more things than the URL.
    - Starting from kernel 6.12, the PREEMPT_RT patch was fully integrated and is now part of the official kernel mainline. The team that maintained the PREEMPT_RT patch is still providing patches with additional features not added to the mainline. We decided to keep using their patches to benefit from all features.
- Go back to the untared Buildroot directory and open the file `package/busybox/busybox.mk`. Take note of the parameter `BUSYBOX_VERSION`. On the present repository (buildroot-site) change the parameter `BR2_PACKAGE_BUSYBOX_CONFIG` in `br2-external/configs/br-common.config`. Note that this will be the filename that you will need to change later, using the Busybox version as part of the name.
- Later on, when you are building an image, Buildroot may complain that the image file is greater than the space configured for it. If this is the case, you will need to change the parameter `BR2_TARGET_ROOTFS_EXT2_SIZE`.
