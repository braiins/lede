#!/bin/sh

MNT_OVERLAY="/tmp/mnt/overlay"

LAST_MAC_PATH="${MNT_OVERLAY}/.last_mac"
OVERLAY_UPPER="${MNT_OVERLAY}/upper"

_sd_cleanup() {
	last_mac=$(cat "$LAST_MAC_PATH" 2>/dev/null)
	curr_mac=$(cat /sys/class/net/eth0/address)

	# if current MAC is the same as last one then do nothing
	[ x"$curr_mac" == x"$last_mac" ] && return

	# remove all configuration files which affect change of MAC address
	rm "$OVERLAY_UPPER/etc/miner_hwid" 2>/dev/null
	rm "$OVERLAY_UPPER/etc/board.json" 2>/dev/null
	rm "$OVERLAY_UPPER/etc/config/system" 2>/dev/null
	rm "$OVERLAY_UPPER/etc/config/network" 2>/dev/null

	# save current MAC address to ensure network persistence only for one device
	echo "$curr_mac" > "$LAST_MAC_PATH"
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
