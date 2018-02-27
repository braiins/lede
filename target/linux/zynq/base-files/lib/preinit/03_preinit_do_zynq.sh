#!/bin/sh
#
# Copyright (c) 2014 The Linux Foundation. All rights reserved.
#

do_zynq() {
	. /lib/zynq.sh

	zynq_board_detect
}

boot_hook_add preinit_main do_zynq
