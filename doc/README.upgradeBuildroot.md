# How to upgrade the Buildroot version

## Expected development time

If you need a basis to estimate how much time you need to bring a new version of Buildroot:
- Patch, configure, build Buildroot: 86 hours
- Configure and Build ATCA-related packages, including EPICS base: 42 hours
- Configure and build all ATCA-related modules: 

## First steps
Download and untar the new Buildroot. It will be used by the files in this repository.

Start from the most recent branch of the present repository and create a new branch following the same naming convention: br-\<Buildroot version\>, replacing \<Buildroot version\> with the version number of the new Buildroot. As this is a new development made on top of the previous one, there's no need for pull requests until the first release is ready.

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
- Later on, when you are building an image, Buildroot may complain that the image file is greater than the space configured for it. If this is the case, you will need to change the parameter `BR2_TARGET_ROOTFS_EXT2_SIZE`

## config directory
This directory holds config files for packages, with parameters that we want to be different from the default used by Buildroot. The difference from the directory `br2-external/configs` is that the former configures Buildroot itself and the latter configures individual packages.

For the linux kernel, there are 4 separate files that will be managed by the script `scripts/br-installconf.sh`, which will produce a final linux-<kernel version>.config file. This is the real config file used when building the Kernel.

Get the kernel version of the previous Buildroot used by SLAC. For example, for Buildroot 2025, the kernel version is 6.12.19. Copy all 4 files called `linux-<kernel version>-*.config`, renaming them with the kernel version you are working on. These are configuration files applied when building the Linux kernel. You won't probably need to modify these files.

Besides the Linux kernel, the other package currently available in this directory is BusyBox (file bb-<version>.x.config). Now it is time to use the `BR2_PACKAGE_BUSYBOX_CONFIG` parameter that you modified in the previous section. Rename the BusyBox config file to be identical to what you set in it. This file is used directly by Buildroot when building BusyBox and is not touched by the script `scripts/br-installconf.sh`. You probably won't need to modify this file.

## pkg-patches
The idea to deal with the patches here is the same of what was done previously on the `br-patches` directory. The difference is that instead, of patching Buildroot itself, the patches will be applied to packages that are built and installed by Buildroot.

First thing, read the file `README.suffix` in this directory to understand the required file name format. The contents of the `linux` sub-directory is the only one used by the script·`scripts/br-installconf.sh`. All other directories are used directly by Buildroot, whithout the intervention of the script.

Start with the `pkg-patches/linux` directory. Create a new sub-directory naming it with the kernel version you are working with. Copy all files from the sub-directory from the previous kernel version to the newly created one and rename them to reflect the new kernel version. Until Buildroot 2019 the diff file regarding the zynq architecture didn't brake the build, but with Buildroot 2025 this file had to be renamed so `scripts/br-installconf.sh` ignored it because this file was breaking the build for the x86 architecture. At the present date (September 2025), we didn't build LinuxRT for architectures other than x86, so a solution for zynq is still pending.

These patches are applied to packages downloaded by Buildroot, which don't exist at this point. So, to update the patches, you'll need to run the Buildroot machinery for the first time. At this point, you've already downloaded and untared Buildroot. Follow the instructions on [README - Installation section](https://github.com/slaclab/buildroot-site/blob/br-2025.02/README.md#installation) to create the soft link `site-top` pointing to where you downloaded Buildroot and also to see instructions on how to run the script `br-installconf.sh`. Alternatively you can use the [SLAC Buildroot Docker](https://github.com/slaclab/slac-buildroot-docker/) mentioned in the README, but you will need to modify the scripts so they download your version of Buildroot. The present repository is added as a submodule of the SLAC Buildroot Docker, so make sure to update it with the branch you started in the section `First steps`. Also, when running the next steps, it is better to use the script `start-dev-container.sh` instead of `create-container.sh` because the former allows you to connect to the container and work with the build process step-by-step. Although it needs a little preparation, we believe that the Docker method is easier because it already automates some of the things.

After running `br-installconf.sh`, you'll need to run `make` in the Buildroot directory. Buildroot will download the packages and start to build them. It is expected that the build will break once it tries to apply the old patches into the new files. Now you have the files that you need to update the patches. Use the same method described in the `br-patches directory` section for the package that broke the build. The only difference here is to run the `diff` command while in the `output/build` directory inside the Buildroot directory that you've untared earlier. Also, see that the name of the patch file will start with the package name instead of "buildroot". The name doesn't affect the building process, but helps other people that will maintain this repository.

Run `make` again. Hopefully your new patch will pass correctly and the build will break in the next package. Repeat the process until you have a clean build.

## Obtaining the build products
If you are using SLAC Buildroot Docker, follow the instructions on its repository README to get both the image and the toolchain.

For the manual process:
- Image: on the Buildroot directory, the files for the image will be on `output/images`.
- Toolchain: on the Buildroot directory, the files will be on `output/host`. At SLAC, we just copy the entire `host` directory to our release area.

## Testing
To test the images and toolchain at SLAC, you need to place them at specific directories so you can build packages, EPICS modules, and IOCs and boot the image on the CPUs.

### Image
Create a directory in `$TFTPBOOT/linuxRT/boot/` choosing a name that reflects the Buildroot version, the architecture, and that this image is still under test. Copy the files `bzImage`, `rootfs.ext2`, and `rootfs.ext2.gz` created by Buildroot in this directory.

For the CPU that will boot the image, modify the file `$TFTPBOOT/linuxRT/boot/ipxe/<CPU name>.ipxe`, commenting out the line starting with `set vers` and adding your own `set vers` for the directory that you created above. It is important to preserv the previous line in case you need to reboot the CPU with the previous image.

Just reboot the CPU and check if the new Buildroot is running with `cat /etc/os-release`. It's now ready for testing.

### Toolchain
Create a new directory in `$PACKAGE_SITE_TOP/linuxRT/` following the convention `buildroot-<Buildroot version>`. For example, `buildroot-2025.02`. The name convention is important because scripts and makefiles are all set with the assumption that it will follow this format.

Copy the entire host directory described above to this new directory. An example of how the final result will look like is `buildroot-2025.02/host/`. This is already the official release and won't change unless, of course, something doesn't work and you need to rebuild the toolchain with Buildroot. But this is very unlikely to happen.

### Building software for tests
We recommend that you build in a local area all the required software for the IOC that will be used for testing. This will give you the freedom to select the versions of each piece of software that you want and your local changes won't require that you formally release them while testing. You will need to modify each piece of software to point to the new toolchain and, also, to your local area when one piece depends on another.

When your tests are finished and your are confident that you can create a release for everything, you can just use `git diff` to see what changed and start the process of pull requests and official release piece by piece in the correct dependency order.

## Final release
The script `scripts/post-build.sh` use the information of the git tag to configure strings in the image. If no tag is present, it assigns a `dirty` tag, which is not what we want. Once everything was tested and proved to work, it is time to tag the final git commit, submit the tag to GitHub and recreate the image. This last image is the one that will be placed in `$TFTPBOOT/linuxRT/boot/` with an official directory name, following the naming convention `buildroot-<Buildroot version>-<SLAC release>-<Arch>`. The SLAC release is just an incremental number with 1 digit, starting from 1 (not zero). Arch can be, for example, x86_64 and i686. An example of a valid name is `buildroot-2025.02-1-x86_64`.
