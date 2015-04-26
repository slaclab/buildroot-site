#!/bin/sh
TEMP=`getopt -o a:hpfd -n "$0" -- "$@"`

if [ $? != 0 ] ; then
	echo "getopt error - terminating..." >&2;
	exit 1;
fi

eval set -- "$TEMP"

while true; do
	case "$1" in
		-h )
			echo "Usage: $0 -a <buildroot_arch> [-pfd]"
			echo "          -a zynq | x86_64 | i386"
			echo "          -p omit patching buildroot (if already done)"
			echo "          -f force rerun (if already done)"
			echo "          -d dry-run"
			exit 0
		;;
		-p )
			NOPATCH="y";
			shift
		;;
		-f )
			FORCE="y";
			shift
		;;
		-d )
			DRY_RUN="--dry-run";
			shift
		;;
		-a )
			case "$2" in
				"zynq" | "i386" | "x86_64")
					ARCH="$2"
					case "$2" in
						"zynq")            KARCH="$2"  ;;
						"i386" | "x86_64") KARCH="x86" ;;
					esac
				;;
				*)
					echo "Unsupported arch/config '$2'" ;
					exit 1
				;;
			esac
			shift 2
		;;
		--) shift; break
		;;
		*) echo "Invalid option $1" >&2; exit 1
		;;
	esac
done

if [ -z "$ARCH" ] ; then
	echo "Error: No target architecture given" >&2
	echo "Usage: $0 -a <zynq | i386 | x86_64>" >&2
	exit 1;
fi

if [ -f .stamp_br_installconf ] ; then
	if [ -z "$FORCE" ] ; then
		echo "Error: $0 was already executed (use -f to force, -fp to avoid repatching)!" >&2
		exit 1;
	fi
	rm .stamp_br_installconf
	if [ -z "$NOPATCH" ] ; then
		rm .stamp_br_patched
	fi
fi

if [ -f .stamp_br_patched -o "$NOPATCH" = "y" ] ; then
	if [ "$NOPATCH" = "y" ] ; then
		touch .stamp_br_patched
	fi
else
	if cat site/br-patches/buildroot* | patch ${DRY_RUN} -p0 -b ; then
		if [ -z "${DRY_RUN}" ] ; then
			touch .stamp_br_patched
		fi
	fi
fi

BR_VER=`make print-version`
if [ $? != 0 ]; then
	echo "Error: unable to determine buildroot version" >&2
	exit 1
fi

restore() {
	rm .config .config.orig
	if [ -f .config.bup ] ; then
		mv .config.bup .config
	fi
	if [ -f .config.old.bup ] ; then
		mv .config.old.bup .config.old
	fi
	if [ -f linux-${LINUX_VER}.config.bup ] ; then
		mv linux-${LINUX_VER}.config.bup linux-${LINUX_VER}.config
	fi
}

if [ -f .config ] ; then
	mv .config .config.bup
fi
cat site/config/br-${BR_VER}-${ARCH}.config site/config/br-${BR_VER}-generic.config > .config
if [ $? != 0 ] ; then
	echo "Error: unable to install .config file" >&2
	exit 1
fi
cp .config .config.orig
if [ -f .config.old ] ; then
	cp .config.old .config.old.bup
fi

make olddefconfig

LINUX_VER=`make -f - print-linux-version <<"EOF"
include Makefile
print-linux-version:
	@echo $(LINUX_VERSION)
EOF
`
if [ $? != 0 -o -z "${LINUX_VER}" ]; then
	echo "Error: unable to determine linux version" >&2
	restore;
	exit 1
fi

if [ -d site/pkg-patches/linux/${LINUX_VER} ] ; then
	true
else
	echo "Error: no linux kernel patches for ${LINUX_VER} found!?!" >&2
	echo "(Must have at least a directory for them)" >&2
	restore;
	exit 1
fi

echo "BR version $BR_VER"
echo "LI version '$LINUX_VER'"

if [ -n "${DRY_RUN}" ] ; then
	restore;
	exit 0
fi


if [ -f linux-${LINUX_VER}.config ] ; then
	mv linux-${LINUX_VER}.config linux-${LINUX_VER}.config.bup
fi
if [ -f site/config/linux-${LINUX_VER}-common.config -a -f site/config/linux-${LINUX_VER}-${KARCH}.config ] ; then
	cat site/config/linux-${LINUX_VER}-common.config site/config/linux-${LINUX_VER}-${KARCH}.config  > linux-${LINUX_VER}.config
	cp linux-${LINUX_VER}.config linux-${LINUX_VER}.config.orig
else
	echo "Error: linux config snippets for linux-${LINUX_VER} not found" >&2
	restore;
	exit 1
fi

touch .stamp_br_installconf

echo "Now type 'make' to build"
