REQUIRE_IMAGE_METADATA=1

RAMFS_COPY_BIN="/usr/sbin/fw_printenv /usr/sbin/fw_setenv /usr/sbin/nanddump /usr/bin/tail"
RAMFS_COPY_DATA="/etc/fw_env.config /var/lock/fw_printenv.lock"

zynq_write_uboot() {
	local tar_file=$1
	local board_name="$(nand_board_name)"

	local uboot_length=`(tar xf ${tar_file} sysupgrade-$board_name/uboot -O | wc -c) 2> /dev/null`

	[ "$uboot_length" != 0 ] && {
		echo "Upgrading U-Boot..."
		mtd erase uboot
		tar xf $tar_file sysupgrade-$board_name/uboot -O | mtd write - uboot
	}
}

zynq_write_fpga_partition() {
	local tar_file=$1
	local cur_partition_name="fpga$2"
	local dst_partition_name="fpga$3"
	local board_name="$(nand_board_name)"
	local cur_mtd="/dev/mtd$(($2 + 1))"
	local cur_fpga="/tmp/cur_fpga.bin"

	local fpga_length=`(tar xf ${tar_file} sysupgrade-$board_name/fpga -O | wc -c) 2> /dev/null`

	if [ "$fpga_length" != 0 ]; then
		echo "Upgrading FPGA bitstream..."
		mtd erase ${dst_partition_name}
		tar xf $tar_file sysupgrade-$board_name/fpga -O | mtd write - ${dst_partition_name}
	else
		# dump current FPGA bitstream and compare it with destination one
		# copy current partition to destination one only if it differs
		nanddump ${cur_mtd} > "$cur_fpga"
		[ $(mtd verify "$cur_fpga" ${dst_partition_name} 2>&1 1>/dev/null | tail -n 1) != "Success" ] && {
			echo "Upgrading FPGA bitstream with current one..."
			mtd erase ${dst_partition_name}
			mtd write "$cur_fpga" ${dst_partition_name}
		}
		rm "$cur_fpga"
	fi
}

zynq_get_firmware_partition() {
	local dst_firmware=$1
	local partition_name="firmware$1"

	# boot after upgrade is treated as a first one; this prevents interference
	# with inserted SD card where uEnv.txt can hinder the upgrade process
	fw_setenv first_boot yes

	# set upgrade stage to 0 to inform U-Boot that upgrade process has been
	# started; when first boot after upgrade is not successful then U-Boot
	# reverts firmware to previous one
	fw_setenv upgrade_stage 0

	# switch to new firmware in environment
	fw_setenv firmware ${dst_firmware}

	echo "$partition_name"
}

zynq_command_check_image() {
	# check if sysupgrade.tar contains COMMAND script with check_image function
	# and run it; this function can be used for checking target environment and
	# refuse upgrade when the firmware is not compatible
	local args="$1"
	local board_name="$(cat /tmp/sysinfo/board_name)"
	local command_length=`(get_image "$args" | tar xf - sysupgrade-$board_name/COMMAND -O | wc -c) 2> /dev/null`
	local command_file="/tmp/sysupgrade-COMMAND"

	[ "$command_length" != 0 ] && {
		get_image "$args" | tar xf - sysupgrade-$board_name/COMMAND -O > "$command_file"
		source "$command_file"
		if type 'check_image' >/dev/null 2>/dev/null; then
			check_image "$board_name" "$args" || return 1
		fi
	}

	return 0
}

zynq_command_pre_upgrade() {
	# check if sysupgrade.tar contains COMMAND script with pre_upgrade function
	# and run it; this function can be used for fixing NAND U-Boot environment
	# variables or upgrading nonstandard partitions like SPL
	local tar_file=$1
	local board_name="$(nand_board_name)"
	local command_file="/tmp/sysupgrade-COMMAND"

	local command_length=`(tar xf ${tar_file} sysupgrade-$board_name/COMMAND -O | wc -c) 2> /dev/null`

	[ "$command_length" != 0 ] && {
		tar xf $tar_file sysupgrade-$board_name/COMMAND -O > "$command_file"
		source "$command_file"
		if type 'pre_upgrade' >/dev/null 2>/dev/null; then
			pre_upgrade "$board_name" "$tar_file"
		fi
	}
}

platform_check_image() {
	[ "$#" -gt 1 ] && return 1

	get_image "$1" | tar -tf - >/dev/null || {
		echo "Invalid image type"
		return 1
	}

	zynq_command_check_image "$1" || return 1
}

platform_pre_upgrade() {
	nand_do_upgrade "$1"
}

platform_nand_pre_upgrade() {
	local cur_firmware=$(fw_printenv -n firmware)
	local dst_firmware=$(($cur_firmware % 2 + 1))

	zynq_command_pre_upgrade "$1"
	zynq_write_uboot "$1"
	zynq_write_fpga_partition "$1" ${cur_firmware} ${dst_firmware}
	CI_UBIPART="$(zynq_get_firmware_partition ${dst_firmware})"

	echo "Switching to ${CI_UBIPART}..."
	sync
}
