include $(TOPDIR)/rules.mk

PKG_NAME:=miner-extroot
PKG_RELEASE:=1

PKG_MAINTAINER:=Libor Vasicek <libor.vasicek@braiins.cz>

include $(INCLUDE_DIR)/package.mk

define Package/miner-extroot
  SECTION:=base
  CATEGORY:=Base system
  TITLE:=Mimer SD card extroot
  DEPENDS:=+block-mount
endef

define Package/miner-extroot/description
 Configuration file needed for mounting SD card extroot.
endef

define Build/Compile
endef

define Package/miner-extroot/install
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_DATA) ./files/fstab.config $(1)/etc/config/fstab
endef

$(eval $(call BuildPackage,miner-extroot))
