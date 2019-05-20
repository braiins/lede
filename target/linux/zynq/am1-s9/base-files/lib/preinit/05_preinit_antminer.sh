#!/bin/sh

MNT_BOOT="/tmp/mnt/boot"
MNT_ANTMINER_ROOTFS="/tmp/mnt/antminer_rootfs"

ANTMINER_MAC_PATH="$MNT_ANTMINER_ROOTFS/config/mac"
OVERRIDE_MAC_PATH="/tmp/override_mac"

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
}

boot_hook_add preinit_main do_antminer
