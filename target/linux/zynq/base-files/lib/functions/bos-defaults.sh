#!/bin/sh

BOS_MODE=$(cat /etc/bos_mode)
BOS_VERSION=$(cat /etc/bos_version)
BOS_VERSION_SUFFIX=${BOS_VERSION#*-*-*-*-*-}

BOS_UENV_PATH="/tmp/mnt/boot/uEnv.txt"
OVERRIDE_CFG_PATH="/tmp/override_cfg"

override_get_config() {
	local override_value=$(grep '^'"$2"'=' "$1" 2>/dev/null)
	echo ${override_value#$2=}
}

bos_get_config() {
	# return empty string when bOS mode is not 'nand' to use default settings
	case $BOS_MODE in
	'nand')
		/usr/sbin/fw_printenv -n "$1" 2>/dev/null
		;;
	'recovery')
		/usr/sbin/fw_printenv -c /tmp/fw_env.config -n "recovery_$1" 2>/dev/null
		;;
	'sd')
		# check configuration override attribute in 'uEnv.txt'
		local cfg_override=$(override_get_config "$BOS_UENV_PATH" "cfg_override")
		# this attribute is enabled by default
		cfg_override=${cfg_override:-yes}
		if [ "$cfg_override" == "yes" ]; then
			# configurations from 'uEnv.txt' has highest priority
			local uenv_value=$(override_get_config "$BOS_UENV_PATH" "$1")
			[ -n "$uenv_value" ] && { echo $uenv_value; return; }
			# then try to get configuration from file which was generated in previous stage
			# usually target specific implementation creates this file
			local override_value=$(override_get_config "$OVERRIDE_CFG_PATH" "$1")
			[ -n "$override_value" ] && { echo $override_value; return; }
			# and finally try to find BOS settings in NAND
			/usr/sbin/fw_printenv -n "$1" 2>/dev/null
		fi
		;;
	esac
}
