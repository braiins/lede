#!/bin/sh

MNT_BOOT="/tmp/mnt/boot"
MNT_ANTMINER_ROOTFS="/tmp/mnt/antminer_rootfs"

OVERRIDE_MAC_PATH="/tmp/override_mac"
OVERRIDE_CFG_PATH="/tmp/override_cfg"

ANTMINER_MAC_PATH="$MNT_ANTMINER_ROOTFS/config/mac"
ANTMINER_NET_PATH="$MNT_ANTMINER_ROOTFS/config/network.conf"

get_net_config() {
	sed -n '/'$1'=/s/.*=["]*\([^"]*\)["]*/\1/p' "$ANTMINER_NET_PATH"
}

do_antminer() {
	# find AntMiner rootfs MTD partition
	local rootfs_mtd=$(sed -n '/antminer_rootfs/s/\(mtd[[:digit:]]\+\).*/\1/p' /proc/mtd)
	[ -n "$rootfs_mtd" ] || return

	# try to mount AntMiner rootfs from NAND
	local rootfs_mtd="/dev/${rootfs_mtd}"

	mkdir -p "$MNT_ANTMINER_ROOTFS" || return

	local rootfs_dettach rootfs_umount
	ubiattach -p "$rootfs_mtd" &>/dev/null && rootfs_dettach=yes && \
	mount -t ubifs ubi0:rootfs "$MNT_ANTMINER_ROOTFS" &>/dev/null && rootfs_umount=yes

	if [ x"$rootfs_umount" != x"yes" ]; then
		[ x"$rootfs_dettach" == x"yes" ] && ubidetach -p "$rootfs_mtd" &>/dev/null
		rmdir "$MNT_ANTMINER_ROOTFS"
		return
	fi

	# set MAC address to original value stored in NAND
	ln -s "$ANTMINER_MAC_PATH" "$OVERRIDE_MAC_PATH" &>/dev/null

	# store all network settings stored in NAND to override file which can be used
	# during further initialization
	local net_hostname=$(get_net_config "hostname")
	local net_ip=$(get_net_config "ipaddress")
	local net_mask=$(get_net_config "netmask")
	local net_gateway=$(get_net_config "gateway")
	local net_dns_servers=$(get_net_config "dnsservers" | tr " " ,)

	[ -n "$net_hostname" ] && echo "net_hostname=$net_hostname" >> "$OVERRIDE_CFG_PATH"
	[ -n "$net_ip" ] && echo "net_ip=$net_ip" >> "$OVERRIDE_CFG_PATH"
	[ -n "$net_mask" ] && echo "net_mask=$net_mask" >> "$OVERRIDE_CFG_PATH"
	[ -n "$net_gateway" ] && echo "net_gateway=$net_gateway" >> "$OVERRIDE_CFG_PATH"
	[ -n "$net_dns_servers" ] && echo "net_dns_servers=$net_dns_servers" >> "$OVERRIDE_CFG_PATH"
}

boot_hook_add preinit_main do_antminer
