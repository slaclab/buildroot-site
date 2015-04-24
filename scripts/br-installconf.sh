#!/bin/sh
TEMP=`getopt -o a: -n "$0" -- "$@"`

if [ $? != 0 ] ; then
	echo "getopt error - terminating..." >&2;
	exit 1;
fi

eval set -- "$TEMP"

while true; do
	case "$1" in
		-a )
			case "$2" in
				"zynq" | "i386" | "x86_64") ARCH="$2" ;;
				*) echo "Unsupported arch/config '$2'" ;
				   exit 1;;
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

BR_VER=`make print-version`
if [ $? != 0 ]; then
	echo "Error: unable to determine buildroot version" >&2
	exit 1
fi

LINUX_VER=`make -f - print-linux-version <<"EOF"
include Makefile
print-linux-version:
	echo $(LINUX_VERSION)
EOF
`
if [ $? != 0 ]; then
	echo "Error: unable to determine linux version" >&2
	exit 1
fi

echo "BR version $BR_VER"
echo "LI version $LINUX_VER"

exit 0




if [ -f .config ] ; then
	mv .config .config.bup
fi
cat site/config/br-$BR_VER-$ARCH.config site/config/br-$BR_VER-generic.config > .config
if [ $? != 0 ] ; then
	echo "Error: unable to install .config file" >&2
	exit 1
fi

make olddefconfig
