#!/bin/sh
if ! [ -d site/pkg-patches ] ; then
	echo "ERROR: site/pkg-patches/ not found"
	exit 1;
fi

for p in site/pkg-patches/* ; do
	f=`echo $p | sed -e 's%\([^/]*[/]\)\{2\}\([^-]*\)[-].*%\2%'`
	if ! [ -d package/$f/ ] ; then
		echo "ERROR: directory package/$f/ not found"
		exit 1;
	fi
	echo "copying $p -> package/$f/"
	cp $p package/$f/
done
