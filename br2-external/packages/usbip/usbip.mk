################################################################################ 
# 
# usbip
# 
################################################################################ 
 
USBIP_SITE = $(LINUX_SITE)
USBIP_SOURCE = $(LINUX_SOURCE)
USBIP_DL_SUBDIR=$(LINUX_DL_SUBDIR)
USBIP_LICENSE = GPLv2+ 
#Unfortunately there are no package-specific tar options; we
#piggy-back on the STRIP_COMPONENTS :-(
USBIP_STRIP_COMPONENTS=4
USBIP_LICENSE_FILES = COPYING 
USBIP_INSTALL_STAGING = YES 


USBIP_EXTRACT_CMDS = \
    $(INFLATE$(suffix $(USBIP_SOURCE))) $(USBIP_DL_DIR)/$(USBIP_SOURCE) | \
    $(TAR) --strip-components=$(USBIP_STRIP_COMPONENTS) \
        -C $(USBIP_DIR) --anchored --wildcards '*/tools/usb/usbip' \
        $(TAR_OPTIONS) -


USBIP_AUTORECONF=YES
 
USBIP_DEPENDENCIES += host-automake host-autoconf host-libtool 
USBIP_DEPENDENCIES += linux

ifeq ($(BR2_PACKAGE_EUDEV),y)
USBIP_DEPENDENCIES += eudev
endif

ifeq ($(BR2_PACKAGE_LIBEUDEV),y)
USBIP_DEPENDENCIES += libeudev
endif

# build breaks with -Werror enabled
TARGET_CFLAGS += -Wno-stringop-truncation -Wno-format-truncation
 
$(eval $(autotools-package)) 
