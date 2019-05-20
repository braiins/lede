#!/bin/sh

MNT_BOOT="/tmp/mnt/boot"
MNT_OVERLAY="/tmp/mnt/overlay"

sd_mount() {
	. /lib/functions/bos-defaults.sh

	# skip this preinit if it is not SD mode
	[ $BOS_MODE == 'sd' ] || return

	mkdir -p "$MNT_BOOT"
	mkdir -p "$MNT_OVERLAY"

	mount /dev/mmcblk0p1 "$MNT_BOOT" >/dev/null || rmdir "$MNT_BOOT"
	mount /dev/mmcblk0p2 "$MNT_OVERLAY" &>/dev/null || rmdir "$MNT_OVERLAY"
}

boot_hook_add preinit_main sd_mount
