#
# Copyright (C) 2015 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#
include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/image.mk

#################################################
# Format version
#################################################

# format version of sysupgrade image
# it is possible to upgrade firmware only with supported formats
DM1_FORMAT := '\"format_version\": \"1\"'

#################################################
# Images
#################################################

# $(1): rootfs contents directory
define Image/mkfs/cpio
	( cd $(call mkfs_target_dir,$(1))/; find . | cpio -o -H newc | gzip -9n > $@ )
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
		-D $(DEVICE_NAME) -o $@.its -k $@ -d $(DTS_DIR)/$(DEVICE_DTS).dtb \
		-C none -a $(KERNEL_LOADADDR) -e $(KERNEL_ENTRY) \
		-A $(ARCH) -v $(LINUX_VERSION) \
		$(if $(IMAGE_ROOTFS_COMP),-r $(IMAGE_ROOTFS) -z $(IMAGE_ROOTFS_COMP))
	PATH=$(LINUX_DIR)/scripts/dtc:$(PATH) mkimage -f $@.its $@.new
	@mv $@.new $@
endef

define Build/append-tar-file
	# append file to the end of an archive with specific name
	$(if $(word 3,$(1)), \
		gzip -c $(word 1,$(1)) > $@-tmp.gz && tar -rf $@ $@-tmp.gz --transform "s|.*|$(word 2,$(1))|", \
		tar -rf $@ $(word 1,$(1)) --transform "s|.*|$(word 2,$(1))|")
endef

define Build/append-signature
	# sign firmware tarball
	echo -n $$(sha256sum $@ | awk '{print $$1}') > $@.digest
	usign -S -m $@.digest -s $(BUILD_KEY) -x - | fwtool -S - $@
endef

#################################################
# Devices
#################################################

DEVICE_VARS += IMAGE_ROOTFS_COMP

# default kernel load address
KERNEL_LOADADDR=0x8000
KERNEL_ENTRY=0x8000

TARGET_FILESYSTEMS += cpio

define Device/Default
	KERNEL := kernel-bin
	KERNEL_NAME := zImage
	PAGESIZE := 2048
	BLOCKSIZE := 128k
	IMAGES := uramdisk.image.gz fit.itb
	IMAGE/uramdisk.image.gz := uRamdisk
	IMAGE/fit.itb := append-kernel | fit
	IMAGE/factory.bin := append-ubi
	IMAGE/sysupgrade.tar := sysupgrade-tar \
	$(if $(CONFIG_SYSUPGRADE_WITH_COMMAND), \
	| append-tar-file ./COMMAND sysupgrade-$$(DEVICE_NAME)/COMMAND) \
	$(if $(CONFIG_SYSUPGRADE_WITH_UBOOT), \
	| append-tar-file $(BIN_DIR)/uboot-$(BOARD)-$$(DEVICE_NAME)/u-boot.img sysupgrade-$$(DEVICE_NAME)/uboot) \
	$(if $(CONFIG_SYSUPGRADE_WITH_FPGA), \
	| append-tar-file $$$$(CONFIG_TARGET_FPGA_$$(DEVICE_NAME)) sysupgrade-$$(DEVICE_NAME)/fpga compress) \
	| append-metadata \
	| append-signature
	FILESYSTEMS := cpio
	IMAGE_ROOTFS_COMP := gzip
	KERNEL_IN_UBI := 1
endef

define Device/zc702
	DEVICE_TITLE := ZC702 Development Board
	DEVICE_DTS := zynq-zc702
endef
TARGET_DEVICES += zc702

define Device/zed
	DEVICE_TITLE := ZedBoard Development Board
	DEVICE_DTS := zynq-zed
endef
TARGET_DEVICES += zed

define Device/zybo
	DEVICE_TITLE := ZYBO Development Board
	DEVICE_DTS := zynq-zybo
endef
TARGET_DEVICES += zybo

define Device/dm1-g9-sd
	DEVICE_TITLE := DragonMint T1/G9 Miner Control Board (SD)
	DEVICE_DTS := zynq-dm1-g9
	IMAGES := fit.itb
	FILESYSTEMS := squashfs
	IMAGE_ROOTFS_COMP := none
endef
TARGET_DEVICES += dm1-g9-sd

define Device/dm1-g19-sd
	DEVICE_TITLE := DragonMint T1/G19 Miner Control Board (SD)
	DEVICE_DTS := zynq-dm1-g19
	IMAGES := fit.itb
	FILESYSTEMS := squashfs
	IMAGE_ROOTFS_COMP := none
endef
TARGET_DEVICES += dm1-g19-sd

define Device/dm1-g9-inno
	DEVICE_TITLE := DragonMint T1/G9 Miner Control Board (Inno)
	DEVICE_DTS := zynq-dm1-g9
	IMAGES := fit.itb
	FILESYSTEMS := squashfs
	IMAGE_ROOTFS_COMP := none
endef
TARGET_DEVICES += dm1-g9-inno

define Device/dm1-g19-inno
	DEVICE_TITLE := DragonMint T1/G19 Miner Control Board (Inno)
	DEVICE_DTS := zynq-dm1-g19
	IMAGES := fit.itb
	FILESYSTEMS := squashfs
	IMAGE_ROOTFS_COMP := none
endef
TARGET_DEVICES += dm1-g19-inno

define Device/dm1-g9-recovery
	DEVICE_TITLE := DragonMint T1/G9 Miner Control Board (Recovery)
	DEVICE_DTS := zynq-dm1-g9
	IMAGES := fit.itb
	FILESYSTEMS := squashfs
	IMAGE_ROOTFS_COMP := none
endef
TARGET_DEVICES += dm1-g9-recovery

define Device/dm1-g19-recovery
	DEVICE_TITLE := DragonMint T1/G19 Miner Control Board (Recovery)
	DEVICE_DTS := zynq-dm1-g19
	IMAGES := fit.itb
	FILESYSTEMS := squashfs
	IMAGE_ROOTFS_COMP := none
endef
TARGET_DEVICES += dm1-g19-recovery

define Device/dm1-g9
	DEVICE_TITLE := DragonMint T1/G9 Miner Control Board
	DEVICE_DTS := zynq-dm1-g9
	KERNEL_SUFFIX := -fit.itb
	KERNEL = kernel-bin | fit
	IMAGES := factory.bin sysupgrade.tar
	FILESYSTEMS := squashfs
	IMAGE_ROOTFS_COMP :=
	IMAGE_METADATA := $(DM1_FORMAT)
	SUPPORTED_DEVICES := dm1-g9
endef
TARGET_DEVICES += dm1-g9

define Device/dm1-g19
	DEVICE_TITLE := DragonMint T1/G19 Miner Control Board
	DEVICE_DTS := zynq-dm1-g19
	KERNEL_SUFFIX := -fit.itb
	KERNEL = kernel-bin | fit
	IMAGES := factory.bin sysupgrade.tar
	FILESYSTEMS := squashfs
	IMAGE_ROOTFS_COMP :=
	IMAGE_METADATA := $(DM1_FORMAT)
	SUPPORTED_DEVICES := dm1-g19
endef
TARGET_DEVICES += dm1-g19

$(eval $(call BuildImage))
