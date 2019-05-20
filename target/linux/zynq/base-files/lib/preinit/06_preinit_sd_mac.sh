#!/bin/sh

MNT_BOOT="/tmp/mnt/boot"

BOS_UENV_PATH="$MNT_BOOT/uEnv.txt"
OVERRIDE_MAC_PATH="/tmp/override_mac"

get_new_mac() {
	# detect variable 'ethaddr' in 'uEnv.txt' which has highest priority
	grep -q '^ethaddr=' "$BOS_UENV_PATH" &>/dev/null && return

	# get new MAC address from file which was generated in previous stage
	# usually target specific implementation creates this file
	if [ -f "$OVERRIDE_MAC_PATH" ]; then
		cat "$OVERRIDE_MAC_PATH" 2>/dev/null
		rm "$OVERRIDE_MAC_PATH" &>/dev/null
		return
	fi

	# try to get MAC address from NAND from bOS environment variable
	fw_printenv -n "ethaddr" 2>/dev/null
	return
}

override_mac() {
	# check if SD boot directory exists
	[ -d "$MNT_BOOT" ] || return

	local new_mac=$(get_new_mac)
	[ -n "$new_mac" ] && /sbin/ifconfig eth0 hw ether "$new_mac" >/dev/null
}

boot_hook_add preinit_main override_mac
