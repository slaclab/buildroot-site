#
# BR 2017.08 does not include 'normal' makefile snippets if .config is not
# created yet. It does, however, include makefiles from the 'docs' subdir.
# We resort to this hack...
#
# We want to keep common definitions and board-specific ones separate in the
# defconfigs. Because there doesn't seem to be an 'include' mechanism we
# have to resort to compiling a single file...

$(BR2_EXTERNAL_SITE_SLAC_PATH)/configs/%_defconfig: $(BR2_EXTERNAL_SITE_SLAC_PATH)/configs/br-$(BR2_VERSION)-common.config $(BR2_EXTERNAL_SITE_SLAC_PATH)/configs/br-$(BR2_VERSION)-%.config
	$(RM) $@
	cat $^  | sort -b -t= -k1,1 -u -s > $@
