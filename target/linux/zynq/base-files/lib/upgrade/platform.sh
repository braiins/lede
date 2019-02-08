REQUIRE_IMAGE_METADATA=1

RAMFS_COPY_BIN="/usr/sbin/fw_printenv /usr/sbin/fw_setenv /usr/sbin/nanddump /usr/bin/tail"
RAMFS_COPY_DATA="/etc/fw_env.config /var/lock/fw_printenv.lock"

zynq_write_spl() {
	local tar_file=$1
	local board_name="$(nand_board_name)"

	local spl_length=`(tar xf ${tar_file} sysupgrade-$board_name/spl -O | wc -c) 2> /dev/null`

	[ "$spl_length" != 0 ] && {
		echo "Upgrading SPL..."
		mtd erase boot
		tar xf $tar_file sysupgrade-$board_name/spl -O | mtd write - boot
	}
}

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

	# remove factory reset to prevent collision with upgrade
	fw_setenv factory_reset

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

firmware_check_signature() {
	# signature is stored at the end of the firmware image
	if ! fwtool -q -s /tmp/sysupgrade.sig "$1"; then
		echo "Image signature not found"
		return 1
	fi

	# the last 4 bytes contains size of signature
	local image_size=$((0x$(get_image "$1" | tail -c 4 | hexdump -v -n 4 -e '1/1 "%02x"')))
	local image_digest=$(get_image "$1" | head -c -${image_size} | sha256sum | awk '{print $1}')

	# check signature of image digest without signature metadata
	if ! echo -n "$image_digest" | usign -V -q -m - -x "/tmp/sysupgrade.sig" -P "/etc/opkg/keys"; then
		echo "Invalid image signature"
		return 1
	fi
}

firmware_check_format() {
	. /usr/share/libubox/jshn.sh

	json_load "$(cat $1)" || {
		echo "Invalid image metadata"
		return 1
	}

	# get image format version
	json_get_vars format_version || return 1

	json_load "$(cat /etc/fw_info.json)" || {
		echo "Invalid firmware info"
		return 1
	}

	json_select supported_formats || return 1

	json_get_keys format_keys
	for k in $format_keys; do
		json_get_var supported_format "$k"
		[ "$format_version" = "$supported_format" ] && return 0
	done

	echo "Image format '$format_version' not supported by this firmware"
	echo -n "Supported formats:"
	for k in $format_keys; do
		json_get_var supported_format "$k"
		echo -n " $supported_format"
	done
	echo
}

platform_check_image() {
	[ "$#" -gt 1 ] && return 1

	get_image "$1" | tar -tf - >/dev/null || {
		echo "Invalid image type"
		return 1
	}

	firmware_check_signature "$1" || return 1

	if fwtool -q -i /tmp/sysupgrade.meta "$1"; then
		firmware_check_format "/tmp/sysupgrade.meta" || return 1
	fi

	zynq_command_check_image "$1" || return 1
}

platform_pre_upgrade() {
	nand_do_upgrade "$1"
}

platform_nand_pre_upgrade() {
	local cur_firmware=$(fw_printenv -n firmware)
	local dst_firmware=$(($cur_firmware % 2 + 1))

	zynq_command_pre_upgrade "$1"
	zynq_write_spl "$1"
	zynq_write_uboot "$1"
	zynq_write_fpga_partition "$1" ${cur_firmware} ${dst_firmware}
	CI_UBIPART="$(zynq_get_firmware_partition ${dst_firmware})"

	echo "Switching to ${CI_UBIPART}..."
	sync
}
