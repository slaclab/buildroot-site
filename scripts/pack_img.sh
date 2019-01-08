#!/bin/bash
echo =========
echo $*
echo =========

KERNEL_ADDR=0x46000000

header () {
cat <<"END_OF_HEADER"
	/*
	 * Simple U-boot uImage source file containing a single kernel and FDT blob
	 */

	/dts-v1/;

	/ {
		description = "Simple image with single Linux kernel, ramdisk and multiple FDT blobs";
		#address-cells = <1>;

		images {
			kernel-1 {
				description = "Linux kernel";
				data = /incbin/("./output/images/zImage");
				type = "kernel";
				arch = "arm";
				os = "linux";
				compression = "none";
				load  = <#KERNEL_ADDR#>;
				entry = <#KERNEL_ADDR#>;
				hash-1 {
					algo = "crc32";
				};
				hash-2 {
					algo = "sha1";
				};
			};
			ramdisk-1 {
				description = "buildroot-ramdisk";
				data = /incbin/("./output/images/rootfs.ext2.gz");
				type = "ramdisk";
				arch = "arm";
				os = "linux";
				compression = "gzip";
				load = <00000000>;
				entry = <00000000>;
				hash-1 {
					algo = "sha1";
				};
			};
END_OF_HEADER
}

fdts () {
  idx=1
  for i in $*; do
	echo "			fdt-${idx} {"
	echo '				data = /incbin/("'"${i}"'");'
	cat  <<END_OF_BLOB
				description = "Flattened Device Tree blob (`basename ${i} .dtb`)";
				type = "flat_dt";
				arch = "arm";
				compression = "none";
				hash-1 {
					algo = "crc32";
				};
				hash-2 {
					algo = "sha1";
				};
			};
END_OF_BLOB
	((idx++))
  done
  echo '		};'
}

configs () {
	echo '		configurations {'
	echo '			default = "conf-1";'
	idx=1
  	for i in $*; do
		echo '			conf-'"${idx}"' {'
		echo '				description = "Boot Linux kernel with FDT for '"`basename $i .dtb`"'";'
		echo '				kernel = "kernel-1";'
		echo '				ramdisk = "ramdisk-1";'
		echo '				fdt = "fdt-'"${idx}"'";'
		echo '			};'
		((idx++))
	done
	echo '		};'
}

fit () {
	header
	fdts $*
	configs $*
	echo '	};'
}

# If there are .dtb files then we want to make a uboot
# image for zynq.
DTBS=
for feil in $1/*.dtb; do
  if [ -f $feil ] ; then
    DTBS="$DTBS $feil"
  fi
  case `basename ${feil} .dtb` in
    *nanopi-neo)
      KERNEL_ADDR=0x45000000
    ;;
    *)
      KERNEL_ADDR=0x00000000
  esac
  if [ -n "$DTBS" ] ; then
	fit $DTBS | sed -e "s/#KERNEL_ADDR#/$KERNEL_ADDR/g" | mkimage -f - $1/linux.fit
  fi
done
