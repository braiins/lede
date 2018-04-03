#!/bin/sh

# redirect STDOUT and STDERR to /dev/kmsg
exec 1<&- 2<&- 1>/dev/kmsg 2>&1

RECOVERY_MTD=/dev/mtd6
FIMRWARE_MTD=/dev/mtd7

FACTORY_OFFSET=0x800000
FACTORY_SIZE=0xC00000

FPGA_OFFSET=0x1400000
FPGA_SIZE=0x100000

SYSTEM_BIT_PATH=/tmp/system.bit
FACTORY_BIN_PATH=/tmp/factory.bin

REBOOT=no

mtd_write() {
	mtd -e "$2" write "$1" "$2"
}

echo "Miner is in the recovery mode!"

FACTORY_RESET=$(fw_printenv -n factory_reset 2> /dev/null)

# immediately exit when error occurs
set -e

if [ x${FACTORY_RESET} == x"yes" ] ; then
	echo "Resetting to factory settings..."

	# get uncompressed factory image
	nanddump -s ${FACTORY_OFFSET} -l ${FACTORY_SIZE} ${RECOVERY_MTD} \
	| gunzip \
	> "$FACTORY_BIN_PATH"

	# get bitstream for FPGA
	nanddump -s ${FPGA_OFFSET} -l ${FPGA_SIZE} ${RECOVERY_MTD} \
	> "$SYSTEM_BIT_PATH"

	# write the same FPGA bitstream to both MTD partitions
	mtd_write "$SYSTEM_BIT_PATH" fpga1
	mtd_write "$SYSTEM_BIT_PATH" fpga2

	# erase all firmware partition
	mtd erase firmware1
	mtd erase firmware2

	ubiformat ${FIMRWARE_MTD} -f "$FACTORY_BIN_PATH"

	# remove factory reset mode from U-Boot env
	fw_setenv factory_reset

	sync
	echo "Factory reset has been successful!"

	REBOOT=yes
fi

# remove recovery mode from U-Boot env to boot in normal mode next time
fw_setenv recovery

if [ x${REBOOT} == x"yes" ] ; then
	# reboot system
	echo "Restarting system..."
	reboot
fi
