#!/bin/sh

# Gather and save version info

# Check if we have all the info we need
if [ $# -lt 1 -o ! -d $1 ] ; then
	echo "Error: need target dir argument" >&2
	exit 1
fi
if [ $# -lt 2 ] ; then
	echo "Error: need BSP argument" >&2
	exit 1
else
BSP_NAME="$2"
fi
if [ -z "${BR2_CONFIG}" ] ; then
	echo "Error: need BR2_CONFIG envvar" >&2
	exit 1
fi
if [ -z "${BUILD_DIR}" ] ; then
	echo "Error: need BUILD_DIR envvar" >&2
	exit 1
fi

V_DIR=$1/etc/site
if [ ! -d ${V_DIR} ] ; then
	mkdir -p ${V_DIR}
fi

cpNzip() {
	rm -f ${V_DIR}/$2-config ${V_DIR}/$2-config.gz
	# use -9 -n to match kernel gzip so binary /proc/config.gz matches exactly
	# (hopefully) -- ultimately you can still compare unzipped and sorted configs
	if ! gzip -n -f -9  < $1 > ${V_DIR}/$2-config.gz ; then
		echo "Unable to save $2 config" >&2
		exit 1
	fi
}

getMakeVar() {
	# check if overridden from environment
	SOMEVAL=`printenv $1`
	if [ -z "$SOMEVAL" ] ; then
    	SOMEVAL=`make ${MKOUTDIR} SOMEVARTOPRINT="$1" MAKEFLAGS= --no-print-directory -f - print-some-var <<"EOF"
include Makefile
print-some-var:
	@echo $($(SOMEVARTOPRINT))
EOF
`
    	if [ $? != 0 -o -z "$SOMEVAL" ] ; then
        	echo "Unable to determine $1" >&2
        	exit 1
    	fi
	fi
    echo $SOMEVAL
}

BR_VER=`getMakeVar BR2_VERSION`
if [ $? != 0 ] ; then exit 1 ; fi

# Copy buildroot config file
cpNzip ${BR2_CONFIG} buildroot-${BR_VER}

# Copy kernel config file
LINUX_VER=`getMakeVar LINUX_VERSION`
if [ $? != 0 ] ; then exit 1 ; fi

cpNzip ${BUILD_DIR}/linux-${LINUX_VER}/.config "linux-${LINUX_VER}"

BB_VER=`getMakeVar BUSYBOX_VERSION`
if [ $? != 0 ] ; then exit 1 ; fi

cpNzip ${BUILD_DIR}/busybox-${BB_VER}/.config "busybox-${BB_VER}"

(cd site; git describe --always --dirty) > ${V_DIR}/site-gitdescription.txt
if [ $? != 0 ] ; then
	echo "Unable to obtain git description of 'site/'" >&2
	exit 1
fi

# Amend inittab for nanopi
case "${BSP_NAME}" in
  *nanopi-neo)
      if ! grep -q ttyGS0 $1/etc/inittab ; then
         echo "Amending /etc/inittab for ttyGS0 (nanopi USB gadget)" >&2
         echo 'ttyGS0::respawn:/sbin/getty -L ttyGS0 0 vt100 #USB_GADGET' >> $1/etc/inittab
      fi
      if [ ! -f $1/etc/fw_env.config ] ; then
         echo "Creating /etc/fw_env.config for nanopi-neo" >&2
         echo '# From u-boot.cfg (sunxi-h3-nanopi-neo); 10/2017'  > $1/etc/fw_env.config
         echo '/dev/mmcblk0 0x88000 0x20000'                     >> $1/etc/fw_env.config
      fi
  ;;
  *)
  ;;
esac
