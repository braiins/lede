#!/bin/sh

ENV_CONF_PATH="/tmp/dragonmint_env.conf"
OVERRIDE_MAC_PATH="/tmp/override_mac"

do_dragonmint() {
	# find DragonMint env MTD partition
	local env_mtd=$(sed -n '/dragonmint_env/s/\(mtd[[:digit:]]\+\).*/\1/p' /proc/mtd)
	[ -n "$env_mtd" ] || return

	cat > "$ENV_CONF_PATH" <<-END
	# MTD device name   Device offset   Env. size   Flash sector size
	/dev/$env_mtd       0x00000         0x20000     0x20000
	/dev/$env_mtd       0x00000         0x20000     0x20000
	END

	local check_env=$(/usr/sbin/fw_printenv -c "$ENV_CONF_PATH" 2>&1 >/dev/null)
	if [ -n "$check_env" ]; then
		# environment in NAND is corrupted
		rm "$ENV_CONF_PATH" &>/dev/null
		return
	fi

	local mac=$(/usr/sbin/fw_printenv -c "$ENV_CONF_PATH" -n "ethaddr" 2>/dev/null)
	[ -n "$mac" ] && echo "$mac" > "$OVERRIDE_MAC_PATH"
}

boot_hook_add preinit_main do_dragonmint
