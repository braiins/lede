#!/bin/sh
#
# Copyright (c) 2014 The Linux Foundation. All rights reserved.
# Copyright (C) 2011 OpenWrt.org
#

ZYNQ_BOARD_NAME=
ZYNQ_MODEL=

zynq_board_detect() {
	local machine
	local name

	machine=$(cat /proc/device-tree/model)

	case "$machine" in
	*"Zynq ZC702 Miner Control Board")
		name="miner-nand"
		;;
	esac

	[ -z "$name" ] && name="unknown"

	[ -z "$ZYNQ_BOARD_NAME" ] && ZYNQ_BOARD_NAME="$name"
	[ -z "$ZYNQ_MODEL" ] && ZYNQ_MODEL="$machine"

	[ -e "/tmp/sysinfo/" ] || mkdir -p "/tmp/sysinfo/"

	echo "$ZYNQ_BOARD_NAME" > /tmp/sysinfo/board_name
	echo "$ZYNQ_MODEL" > /tmp/sysinfo/model
}

zynq_board_name() {
	local name

	[ -f /tmp/sysinfo/board_name ] && name=$(cat /tmp/sysinfo/board_name)
	[ -z "$name" ] && name="unknown"

	echo "$name"
}
