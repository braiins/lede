REQUIRE_IMAGE_METADATA=1

RAMFS_COPY_BIN="/usr/sbin/fw_printenv /usr/sbin/fw_setenv"
RAMFS_COPY_DATA="/etc/fw_env.config /var/lock/fw_printenv.lock"

zynq_get_firmware_partition() {
	cur_firmware=$(fw_printenv -n firmware)
	partition_name=""

	# boot after upgrade is treated as a first one; this prevents interference
	# with inserted SD card where uEnv.txt can hinder the upgrade process
	fw_setenv first_boot yes

	# set upgrade stage to 0 to inform U-Boot that upgrade process has been
	# started; when first boot after upgrade is not successful then U-Boot
	# reverts firmware to previous one
	fw_setenv upgrade_stage 0

	if [ x"$cur_firmware" = x"2" ]; then
		partition_name="firmware1"
		fw_setenv firmware 1
	elif [ x"$cur_firmware" = x"1" ]; then
		partition_name="firmware2"
		fw_setenv firmware 2
	fi

	echo "$partition_name"
}

platform_check_image() {
	return 0;
}

platform_pre_upgrade() {
	nand_do_upgrade "$1"
}

platform_nand_pre_upgrade() {
	CI_UBIPART="$(zynq_get_firmware_partition)"
}
