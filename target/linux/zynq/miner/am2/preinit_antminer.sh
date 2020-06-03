#!/bin/sh

MNT_BOOT="/tmp/mnt/boot"
MNT_ANTMINER_CONFIGS="/tmp/mnt/antminer_configs"

OVERRIDE_MAC_PATH="/tmp/override_mac"
OVERRIDE_CFG_PATH="/tmp/override_cfg"

ANTMINER_MAC_PATH="$MNT_ANTMINER_CONFIGS/mac"
ANTMINER_NET_PATH="$MNT_ANTMINER_CONFIGS/network.conf"

ANTMINER_DEFAULT_HOSTNAME="antMiner"

get_net_config() {
	sed -n '/'$1'=/s/.*=["]*\([^"]*\)["]*/\1/p' "$ANTMINER_NET_PATH"
}

do_antminer() {
	# find Antminer configs MTD partition
	local configs_mtd=$(sed -n '/antminer_configs/s/\(mtd[[:digit:]]\+\).*/\1/p' /proc/mtd)
	[ -n "$configs_mtd" ] || return

	# try to mount Antminer configs from NAND
	local configs_mtd="/dev/${configs_mtd}"

	mkdir -p "$MNT_ANTMINER_CONFIGS" || return

	local configs_dettach configs_umount
	ubiattach -p "$configs_mtd" &>/dev/null && configs_dettach=yes && \
	mount -t ubifs ubi0:configs "$MNT_ANTMINER_CONFIGS" &>/dev/null && configs_umount=yes

	if [ x"$configs_umount" != x"yes" ]; then
		[ x"$configs_dettach" == x"yes" ] && ubidetach -p "$configs_mtd" &>/dev/null
		rmdir "$MNT_ANTMINER_CONFIGS"
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

	# replace default AntMiner hostname with unique BOS hostname
	[ x"$net_hostname" == x"$ANTMINER_DEFAULT_HOSTNAME" ] && net_hostname=

	[ -n "$net_hostname" ] && echo "net_hostname=$net_hostname" >> "$OVERRIDE_CFG_PATH"
	[ -n "$net_ip" ] && echo "net_ip=$net_ip" >> "$OVERRIDE_CFG_PATH"
	[ -n "$net_mask" ] && echo "net_mask=$net_mask" >> "$OVERRIDE_CFG_PATH"
	[ -n "$net_gateway" ] && echo "net_gateway=$net_gateway" >> "$OVERRIDE_CFG_PATH"
	[ -n "$net_dns_servers" ] && echo "net_dns_servers=$net_dns_servers" >> "$OVERRIDE_CFG_PATH"
}

boot_hook_add preinit_main do_antminer
