#
# Copyright (C) 2015 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#
include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/host.mk

ARCH:=arm
BOARD:=zynq
BOARDNAME:=Xilinx Zynq 7000 SoCs
FEATURES:=fpu gpio rtc usb usbgadget targz squashfs nand
DEPENDS:=+@KERNEL_DEVKMEM +@KERNEL_DEVMEM
CPU_TYPE:=cortex-a9
CPU_SUBTYPE:=neon
SUBTARGETS:=dm1-g9 dm1-g19
MAINTAINER:=Jason Wu <jason.wu.misc@gmail.com>

# future support SUBTARGETS: for both zynq and zynqmp

define Target/Description
	Build firmware image for Zynq 7000 SoC devices.
endef

KERNEL_PATCHVER:=4.4

include $(INCLUDE_DIR)/target.mk

KERNELNAME:=zImage dtbs

DEFAULT_PACKAGES += uboot-envtools firmware
DEFAULT_PACKAGES += uboot-zynq-$(SUBTARGET) uboot-zynq-$(SUBTARGET)-sd

$(eval $(call BuildTarget))
