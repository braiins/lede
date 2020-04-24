#!/bin/sh

MNT_OVERLAY="/tmp/mnt/overlay"

BOS_UENV_PATH="/tmp/mnt/boot/uEnv.txt"
OVERLAY_UPPER="${MNT_OVERLAY}/upper"

LAST_MAC_PATH="${MNT_OVERLAY}/.last_mac"
LAST_UENV_PATH="${MNT_OVERLAY}/.last_uenv"

_sd_cleanup() {
	local last_mac=$(cat "$LAST_MAC_PATH" 2>/dev/null)
	local curr_mac=$(cat /sys/class/net/eth0/address)

	# if current MAC and 'uEnv.txt' is the same as the last one then do nothing
	[ x"$curr_mac" == x"$last_mac" ] \
	&& [ \( -f "$BOS_UENV_PATH" -a -f "$LAST_UENV_PATH" \) -o \( ! -f "$BOS_UENV_PATH" -a ! -f "$LAST_UENV_PATH" \) ] \
	&& cat "$LAST_UENV_PATH" 2>/dev/null | md5sum -cs \
	&& return

	# remove all configuration files which affect change of MAC address
	rm "$OVERLAY_UPPER/etc/miner_hwid" 2>/dev/null
	rm "$OVERLAY_UPPER/etc/board.json" 2>/dev/null
	rm "$OVERLAY_UPPER/etc/config/system" 2>/dev/null
	rm "$OVERLAY_UPPER/etc/config/network" 2>/dev/null

	# save current MAC address to ensure network persistence only for one device
	echo "$curr_mac" > "$LAST_MAC_PATH"
	# save MD5 of 'uEnv.txt' if exists otherwise delete the file
	[ -f "$BOS_UENV_PATH" ] \
	&& md5sum "$BOS_UENV_PATH" > "$LAST_UENV_PATH" \
	|| rm -f "$LAST_UENV_PATH"
}

sd_cleanup() {
	# nothing to clean up if overlay cannot be mounted
	[ -d "$MNT_OVERLAY" ] || return

	_sd_cleanup

	# unmount overlay which will be mounted later by system
	umount "$MNT_OVERLAY" >/dev/null
	rmdir "$MNT_OVERLAY" >/dev/null
}

boot_hook_add preinit_main sd_cleanup
