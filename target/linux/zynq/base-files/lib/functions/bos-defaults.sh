#!/bin/sh

BOS_MODE=$(cat /etc/bos_mode)
BOS_VERSION=$(cat /etc/bos_version)
BOS_VERSION_SUFFIX=${BOS_VERSION#*-*-*-*-*-}

bos_get_config() {
	# return empty string when bOS mode is not 'nand' to use default settings
	case $BOS_MODE in
	'nand')
		/usr/sbin/fw_printenv -n "$1" 2>/dev/null
		;;
	'recovery')
		/usr/sbin/fw_printenv -c /tmp/fw_env.config -n "recovery_$1" 2>/dev/null
		;;
	esac
}
