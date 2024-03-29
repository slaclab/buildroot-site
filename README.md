#CLONING SLAC-CONFIGURATION OF BUILDROOT

##Directory Structure

###TOP Directory

I like to structure my buildroot tree in the following way:

At the top I like to have a buildroot-version specific directory:

    buildroot-<version>/ e.g.,  buildroot-2019.08/

Inside the top directory there are three principal subdirectories:

####1. DOWNLOAD Subdirectory

    download/

is where the build process stores downloaded sources. It is handy
to keep them there so that if you rebuild everything you don't have
to download everything again. Also, if you have different configurations
of buildroot then they can all share the same downloads.

Nowadays I even go a bit further and share the `download` directory
among different buildroot versions in this case I make `download`
a symlink to some outside location.

####2. BUILDROOT Subdirectory

    buildroot-<version>[-<config>]/

This is the top directory of the unpacked `buildroot` sources.
Everything that buildroot builds ends up somewhere underneath this directory.

If you unpack the buildroot distribution in the <TOP> directory
then the unpack procedure creates a `buildroot-<version>` directory.

It should be noted that buildroot does not currently support
building different configurations (e.g., different targets
or kernel versions) from a single source tree.
Therefore you must maintain/build different configurations side-by-side.
I do this by unpacking the buildroot source multiple times and renaming
the top directories after the configuration.

E.g., if I have stable and development versions for x86 (assume version
2019.08) then I could have

    buildroot-2019.08/download/
    buildroot-2019.08/buildroot-2019.08-x86-devl/
    buildroot-2019.08/buildroot-2019.08-x86/

which I obtained doing

    chdir buildroot-2019.08/
    tar xf ../download/buildroot-2019.08.tar.bz2
    mv buildroot-2019.08 buildroot-2019.08-x86
    tar xf ../download/buildroot-2019.08.tar.bz2
    mv buildroot-2019.08 buildroot-2019.08-x86-devl

If you only build for the same target architecture then you
could also omit the `x86`. Nothing about these names is special
or required.

####3. SLAC `site` Subdirectory

All the site specific modifications of buildroot and other
software as well as configuration files for buildroot, busybox,
kernel etc. are maintained in git and cloned into a

    site-top/

If you want different builds to use different
branches or releases of `site-top/` then there can be multiple
clones, e.g. a stable and development one:

    site-top/
    site-top-devl/

####4. Symlink Connecting Buildroot to Site-Top

Each build/configuration is connected to a `site-top` by
means of a symlink. E.g., for the aforementioned stable
and development builds there could be

    buildroot-2019.08-x86/site       -> ../site-top
    buildroot-2019.08-x86-devl/site  -> ../site-top-devl

####4. HOST Subdirectory

As of 2014.02 the buildroot configuration is set up so that
the toolchain is installed into the `host/` subdirectory.
This enables different variants of the same buildroot version
(e.g., different kernel configs or a 'test' variant) to share
a toolchain. (A config which wishes to share this toolchain
must in-turn be configured accordingly.)

External software can just use the toolchain in

    <TOP>/buildroot-<version>/host/<host-arch>/<target-arch>/usr/bin/

This structure supports multiple host architectures (since we
still use 32-bit build machines in some places at slac).

NOTE: if you issue `make clean` at the buildroot top then
this will erase everything installed into the `host` area, too.
I usually don't want this to happen and I simply

  rm -rf output

from the buildroot top instead of issuing `make clean`.

##INSTALLATION

All the following steps assume version 2019.08. If you are using
a different version, please modify the instructions accordingly.

###1. Preparation

The first steps reflect what has been described under 'directory
structure' above.

Create the TOP directory and chdir there:

    mkdir <prefix>/buildroot-2019.08
    cd    <prefix>/buildroot-2019.08

Create `download` directory:

    mkdir download

Download buildroot 

    wget -P download/ http://buildroot.uclibc.org/downloads/buildroot-2019.08.tar.bz2

Unpack

    tar xf download/buildroot-2019.08.tar.bz2

You might now want to rename

    mv buildroot-2019.08  buildroot-2019.08-x86_64

Repeat the 'unpack' and 'rename' steps if you want to build
multiple configurations.

###2. Create Symlink to Site-Top

Clone site-top

NOTE: you need to clone the specific branch matching your buildroot release!
      The `master` branch is empty...

    git clone -b br-2019.08 https://github.com/slaclab/buildroot-site site-top

Create symlink to site-specific config files, patches etc.

    ln -s ../site-top buildroot-2019.08-x86_64/site

###3. Run SLAC prep helper script

Since 2015.02 a bash script was added which performs several
steps that had to be done manually:

  - apply buildroot patches (from `site/br-patches/`)
    A `.stamp_br_patched` flag-file is created after this step
    so that the script doesn't attempt to apply patches twice.
  - Compile the buildroot config file from snippets (arch-specific
    and common/generic pieces) under `site/config/`.
  - Convert the buildroot config file (which really is a 'defconfig',
    i.e., a list of settings that deviate from the defaults) to a
    full-blown config file (`.config`).
  - Compile the linux kernel defconfig file from arch-specific and
    common/generic pieces under `site/config/` to `linux-<version>.config`.
    (This is a 'defconfig'.)

First, change the working-directory into the buildroot source directory.

    cd buildroot-2019.08-x86_64/   # or whatever you renamed the directory to

Note: this directory (i.e., the top-directory of the unpacked buildroot
distribution) is often referred to as the 'buildroot top directory' in this
text.

Then execute

    site/scripts/br-installconf.sh -a <arch>

were <arch> is one of:
  - zynq
  - i686
  - x86_64
  - nanopi

Upon successful completion the script will install a `.stamp_br_installconf`
flag-file which will prevent the script from executing again (can be
overridden with a `-f` option).

Script options:

````
    -h: help
    -f: force    -- recompile config files 
    -p: no-patch -- do not apply buildroot patches (handy if you want to
                    'force' a reinstall of config files (e.g., for
                    different arch) but patches had been applied already.
    -d: dry-run  -- show what script would do (some steps are retraced,
                    i.e., files are restored).
````

###4. Build

Make sure your CWD is neither in `PATH` nor in `LD_LIBRARY_PATH` and issue

    make

NOTE: if your main build machine has no access to the internet then
      you can use the following steps:

         1. log onto a machine *with* internet access.
         2. chdir to buildroot top (where buildroot .config file sits)
         3. type `make source` (this just downloads everything needed)
         4. log out, back into your build machine
         5. type `make`

####4.1. Output Products

Products generated by the build (kernel image, root-file system etc.)
are in `output/images/`.

###5. Modifying the Configuration Files

This process is explained in a separate `README.buildroot.modify_config`
file.

###6. Version Control

(Gzipped) copies of 
  - buildroot config file
  - linux kernel config file
  - busybox config file
as well as the output of `(cd site; git describe --always --dirty)` which captures
the state of the slac-specific configuration(s) are stored in the
target's root filesystem under

    /etc/site/

The kernel configuration is the configuration effective when buildroot
was compiled. This can be compared against the run-time kernel config
information available at

    /proc/config.gz
