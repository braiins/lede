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
FORMAT_VERSION := '\"format_version\": \"1\"'

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
		-D $(SUBTARGET) -o $@.its -k $@ -d $(DTS_DIR)/$(DEVICE_DTS).dtb \
		-C none -a $(KERNEL_LOADADDR) -e $(KERNEL_ENTRY) \
		-A $(ARCH) -v $(LINUX_VERSION) \
		$(if $(IMAGE_ROOTFS_COMP),-r $(IMAGE_ROOTFS) -z $(IMAGE_ROOTFS_COMP))
	PATH=$(LINUX_DIR)/scripts/dtc:$(PATH) mkimage -f $@.its $@.new
	@mv $@.new $@
endef

define Build/append-tar-file
	# append file to the end of an archive with specific name
	$(if $(word 4,$(1)),cp $(word 4,$(1)) $@-tmp)
	$(if $(word 3,$(1)),$(if $(subst compress,,$(word 3,$(1))), \
		$(VERSION_SED) $@-tmp && cat $(word 1,$(1)) >> $@-tmp && tar -rf $@ $@-tmp, \
		gzip -c $(word 1,$(1)) > $@-tmp.gz && tar -rf $@ $@-tmp.gz), \
		tar -rf $@ $(word 1,$(1))) \
	--transform "s|.*|$(word 2,$(1))|"
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
	DEVICE_DTS := $(BOARD)-$(SUBTARGET)
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
	| append-tar-file ../$(SUBTARGET)/COMMAND sysupgrade-$$(SUBTARGET)/COMMAND version_sed COMMAND) \
	$(if $(CONFIG_SYSUPGRADE_WITH_SPL), \
	| append-tar-file $(BIN_DIR)/uboot-$(BOARD)-$(SUBTARGET)/boot.bin sysupgrade-$$(SUBTARGET)/spl) \
	$(if $(CONFIG_SYSUPGRADE_WITH_UBOOT), \
	| append-tar-file $(BIN_DIR)/uboot-$(BOARD)-$(SUBTARGET)/u-boot.img sysupgrade-$$(SUBTARGET)/uboot) \
	$(if $(CONFIG_SYSUPGRADE_WITH_FPGA), \
	| append-tar-file $$(CONFIG_TARGET_FPGA) sysupgrade-$$(SUBTARGET)/fpga compress) \
	| append-metadata \
	| append-signature
	FILESYSTEMS := cpio
	IMAGE_ROOTFS_COMP := gzip
	KERNEL_IN_UBI := 1
endef

define Device/sd
	DEVICE_TITLE := $(BOARDNAME) Miner Control Board (SD)
	IMAGES := fit.itb
	FILESYSTEMS := squashfs
	IMAGE_ROOTFS_COMP := none
endef
TARGET_DEVICES += sd

define Device/upgrade
	DEVICE_TITLE := $(BOARDNAME) Miner Control Board (Upgrade)
	IMAGES := fit.itb
	FILESYSTEMS := squashfs
	IMAGE_ROOTFS_COMP := none
endef
TARGET_DEVICES += upgrade

define Device/recovery
	DEVICE_TITLE := $(BOARDNAME) Miner Control Board (Recovery)
	IMAGES := fit.itb
	FILESYSTEMS := squashfs
	IMAGE_ROOTFS_COMP := none
endef
TARGET_DEVICES += recovery

define Device/nand
	DEVICE_TITLE := $(BOARDNAME) Miner Control Board
	KERNEL_SUFFIX := -fit.itb
	KERNEL = kernel-bin | fit
	IMAGES := factory.bin sysupgrade.tar
	FILESYSTEMS := squashfs
	IMAGE_ROOTFS_COMP :=
	IMAGE_METADATA := $(FORMAT_VERSION)
	BOARD_NAME := $(SUBTARGET)
	SUPPORTED_DEVICES := $(SUBTARGET)
endef
TARGET_DEVICES += nand

$(eval $(call BuildImage))
