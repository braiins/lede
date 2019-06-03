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
	local new_mac=$(fw_printenv -n "ethaddr" 2>/dev/null)
	# it is also stored in factory configuration environment variable
	[ -n "$new_mac" ] || new_mac=$(/usr/sbin/bos get_factory_cfg "ethaddr" 2>/dev/null)

	if [ -z "$new_mac" ]; then
		# generate new MAC when all source failed
		new_mac=$(dd if=/dev/urandom bs=1024 count=1 2>/dev/null | /usr/bin/md5sum | \
			sed 's/^\(..\)\(..\)\(..\)\(..\)\(..\)\(..\).*$/\1:\2:\3:\4:\5:\6/')

		# generate a random Ethernet address (MAC) that is not multicast
		# and bit 1 (local) is set
		local firstbyte=$(echo "$new_mac" | cut -d: -f 1)
		local lastfive=$(echo "$new_mac" | cut -d: -f 2-6)

		firstbyte=$(printf '%02x' $(( 0x$firstbyte & 254 | 2)))
		new_mac="$firstbyte:$lastfive"
	fi

	echo "$new_mac"
	return
}

override_mac() {
	# check if SD boot directory exists
	[ -d "$MNT_BOOT" ] || return

	local new_mac=$(get_new_mac)
	[ -n "$new_mac" ] && /sbin/ifconfig eth0 hw ether "$new_mac" >/dev/null
}

boot_hook_add preinit_main override_mac
