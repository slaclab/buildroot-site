################################################################################
#
# libeudev
#
################################################################################

LIBEUDEV_VERSION = 3.2.2
LIBEUDEV_SITE = http://dev.gentoo.org/~blueness/eudev
LIBEUDEV_SOURCE = eudev-$(LIBEUDEV_VERSION).tar.gz
LIBEUDEV_LICENSE = GPL-2.0+ (programs), LGPL-2.1+ (libraries)
LIBEUDEV_LICENSE_FILES = COPYING
LIBEUDEV_INSTALL_STAGING = YES

# mq_getattr is in librt
LIBEUDEV_CONF_ENV += LIBS=-lrt

LIBEUDEV_CONF_OPTS = \
	--disable-manpages \
	--sbindir=/sbin \
	--libexecdir=/lib \
	--disable-introspection \
	--disable-kmod \
	--disable-blkid \
    --disable-programs \
    --disable-hwdb \
    --disable-mtd_probe

LIBEUDEV_DEPENDENCIES = host-gperf host-pkgconf

ifeq ($(BR2_ROOTFS_MERGED_USR),)
LIBEUDEV_CONF_OPTS += --with-rootlibdir=/lib --enable-split-usr
endif

ifeq ($(BR2_PACKAGE_LIBSELINUX),y)
LIBEUDEV_CONF_OPTS += --enable-selinux
LIBEUDEV_DEPENDENCIES += libselinux
else
LIBEUDEV_CONF_OPTS += --disable-selinux
endif

$(eval $(autotools-package))
