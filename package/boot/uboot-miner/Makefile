#
# Copyright (C) 2015 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/image.mk

PKG_NAME:=u-boot
PKG_VERSION:=2016.03
PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.bz2
PKG_SOURCE_URL:= \
	http://mirror2.openwrt.org/sources \
	ftp://ftp.denx.de/pub/u-boot

PKG_HASH:=e49337262ecac44dbdeac140f2c6ebd1eba345e0162b0464172e7f05583ed7bb

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(BUILD_VARIANT)/$(PKG_NAME)-$(PKG_VERSION)

PKG_LICENSE:=GPL-2.0 GPL-2.0+
PKG_LICENSE_FILES:=Licenses/README

include $(INCLUDE_DIR)/package.mk

define uboot/Default
	TITLE:=
	CONFIG:=
	IMAGE:=
endef

define uboot/miner-sd
	TITLE:=U-Boot $(PKG_VERSION) for Xilinx ZC702 Dev Board (SD)
	CONFIG:=miner_sd
endef

define uboot/miner-nand
	TITLE:=U-Boot $(PKG_VERSION) for Xilinx ZC702 Dev Board (NAND)
	CONFIG:=miner_nand
endef

UBOOTS := \
	miner-sd \
	miner-nand

define Package/uboot/template
define Package/uboot-zynq-$(1)
	SECTION:=boot
	CATEGORY:=Boot Loaders
	DEPENDS:=@TARGET_zynq
	TITLE:=$(2)
	URL:=http://www.denx.de/wiki/U-Boot
	VARIANT:=$(1)
	MAINTAINER:=Jason Wu <jason.wu.misc@gmail.com>
endef
endef

define BuildUBootPackage
	$(eval $(uboot/Default))
	$(eval $(uboot/$(1)))
	$(call Package/uboot/template,$(1),$(TITLE))
endef

ifdef BUILD_VARIANT
$(eval $(call uboot/$(BUILD_VARIANT)))
UBOOT_CONFIG:=$(if $(CONFIG),$(CONFIG),$(BUILD_VARIANT))
UBOOT_IMAGE:=$(if $(IMAGE),$(IMAGE),openwrt-$(BOARD)-$(BUILD_VARIANT)-u-boot.bin)
endif

define Build/Configure
	+$(MAKE) $(PKG_JOBS) -C $(PKG_BUILD_DIR) \
		$(BOARD)_$(UBOOT_CONFIG)_config DTC=$(LINUX_DIR)/scripts/dtc/dtc
endef

define Build/Compile
	+$(MAKE) $(PKG_JOBS) -C $(PKG_BUILD_DIR) \
		CROSS_COMPILE=$(TARGET_CROSS)
	+$(TARGET_CROSS)strip $(PKG_BUILD_DIR)/u-boot -o $(PKG_BUILD_DIR)/u-boot.elf
	+$(CP) ./files/fsbl.elf $(PKG_BUILD_DIR)
	+$(CP) ./files/system.bit $(PKG_BUILD_DIR)
	+echo "the_ROM_image:{[bootloader]./files/fsbl.elf ./files/system.bit $(PKG_BUILD_DIR)/u-boot.elf}" \
		>$(PKG_BUILD_DIR)/BOOT.bif
	+bootgen -image $(PKG_BUILD_DIR)/BOOT.bif -arch zynq -w -o $(PKG_BUILD_DIR)/BOOT.bin
endef

define Package/uboot/install/default
	$(INSTALL_DIR) $(BIN_DIR)/uboot-$(BOARD)-$(1)

	$(CP) $(PKG_BUILD_DIR)/BOOT.bin \
		$(BIN_DIR)/uboot-$(BOARD)-$(1)
endef

define Package/uboot/install/template
define Package/uboot-zynq-$(1)/install
	$(call Package/uboot/install/default,$(2))
endef
endef

$(foreach u,$(UBOOTS), \
	$(eval $(call Package/uboot/install/template,$(u),$(u))) \
)

$(foreach u,$(UBOOTS), \
	$(eval $(call BuildUBootPackage,$(u))) \
	$(eval $(call BuildPackage,uboot-zynq-$(u))) \
)
