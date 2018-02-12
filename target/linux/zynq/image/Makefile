#
# Copyright (C) 2015 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#
include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/image.mk

#################################################
# Images
#################################################

# $(1): rootfs contents directory
define Image/mkfs/cpio
	( cd $(call mkfs_target_dir,$(1))/; find . | cpio -o -H newc | gzip -9n > $@ )
endef

define Build/dtb
	$(call Image/BuildDTB,$(DTS_DIR)/zynq-$(DEVICE_ID).dts,$@.dtb)
endef

define Build/uRamdisk
	# Create uboot cpio.gz
	mkimage -A arm -T ramdisk -C gzip -n "$(PROFILE) OpenWRT rootfs" \
		-d $(IMAGE_ROOTFS) $@.new
	mv $@.new $@
endef

define Build/fit
	# create FIT image with rootfs
	./mkits.sh \
		-D $(DEVICE_ID) -o $@.its -k $(IMAGE_KERNEL) -d $(IMAGE_KERNEL).dtb \
		-C none -a $(KERNEL_LOADADDR) -e $(KERNEL_ENTRY) \
		-A $(ARCH) -v $(LINUX_VERSION) \
		$(if $(IMAGE_ROOTFS_COMP),-r $(IMAGE_ROOTFS) -z $(IMAGE_ROOTFS_COMP))

	PATH=$(LINUX_DIR)/scripts/dtc:$(PATH) mkimage -f $@.its $@
endef

#################################################
# Devices
#################################################

DEVICE_VARS += DEVICE_ID
DEVICE_VARS += IMAGE_ROOTFS_COMP

# default kernel load address
KERNEL_LOADADDR=0x8000
KERNEL_ENTRY=0x8000

TARGET_FILESYSTEMS += cpio

define Device/Default
	KERNEL := dtb | kernel-bin
	KERNEL_NAME = zImage
	IMAGES := uramdisk.image.gz fit.itb
	IMAGE/uramdisk.image.gz := uRamdisk
	IMAGE/fit.itb := fit
	FILESYSTEMS := cpio
	IMAGE_ROOTFS_COMP := gzip
endef

define Device/zc702
	DEVICE_TITLE := ZC702 Development Board
	DEVICE_ID := zc702
endef
TARGET_DEVICES += zc702

define Device/zed
	DEVICE_TITLE := ZedBoard Development Board
	DEVICE_ID := zed
endef
TARGET_DEVICES += zed

define Device/zybo
	DEVICE_TITLE := ZYBO Development Board
	DEVICE_ID := zybo
endef
TARGET_DEVICES += zybo

define Device/miner-sd
	DEVICE_TITLE := Miner Controller Board (SD)
	DEVICE_ID := miner
	IMAGES := fit.itb
	FILESYSTEMS := squashfs
	IMAGE_ROOTFS_COMP := none
endef
TARGET_DEVICES += miner-sd

define Device/miner-nand
	DEVICE_TITLE := Miner Controller Board (NAND)
	DEVICE_ID := miner
	IMAGES := fit.itb rootfs.bin
	IMAGE/rootfs.bin := append-rootfs
	FILESYSTEMS := squashfs
	IMAGE_ROOTFS_COMP :=
endef
TARGET_DEVICES += miner-nand

$(eval $(call BuildImage))
