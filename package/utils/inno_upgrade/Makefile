include $(TOPDIR)/rules.mk

PKG_NAME:=inno_upgrade
PKG_RELEASE:=1

PKG_MAINTAINER:=Libor Vasicek <libor.vasicek@braiins.cz>

include $(INCLUDE_DIR)/package.mk

define Package/inno_upgrade
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=Upgrade Inno firmware to braiins/LEDE
endef

define Package/inno_upgrade/description
 Upgrade firmware from original Inno miner to braiins/LEDE one.
endef

define Build/Compile
endef

define Package/inno_upgrade/install
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) ./files/inno_upgrade.sh $(1)/usr/sbin/
endef

$(eval $(call BuildPackage,inno_upgrade))
