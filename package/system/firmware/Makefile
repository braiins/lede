include $(TOPDIR)/rules.mk

CURRENT_DATE:=$(shell date --rfc-3339=date)
GIT_HASH:=$(shell git rev-parse --short HEAD)
GIT_DIRTY:=$(if $(shell git status --porcelain),-dirty)

PKG_NAME:=firmware
PKG_RELEASE:=$(CURRENT_DATE)-$(GIT_HASH)$(GIT_DIRTY)

PKG_MAINTAINER:=Libor Vasicek <libor.vasicek@braiins.cz>

include $(INCLUDE_DIR)/package.mk

define Package/firmware
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=Current Firmware
endef

define Package/firmware/description
 Meta package for automated firmware upgrades.
endef

define Build/Compile
endef

define Package/firmware/install
	$(INSTALL_DIR) $(1)/etc
	$(INSTALL_CONF) ./files/fw_info.json $(1)/etc/
endef

define Package/firmware/preinst
#!/bin/sh

# if run within buildroot exit
[ -n "$${IPKG_INSTROOT}" ] && exit 0

[ -f "/tmp/sysupgrade.tar" ] || {
	echo "Missing '/tmp/sysupgrade.tar' needed for firmware upgrade"
	exit 1
}

echo "Running system upgrade..."
sysupgrade "/tmp/sysupgrade.tar" || exit 1

# the package is not actually installed
# wait to suppress error printing
sleep 10
exit 2
endef

define Package/firmware/postrm
#!/bin/sh

# if this script is run then simple package remove has been called
echo "Processing factory reset..."
fw_setenv factory_reset yes
reboot
endef

$(eval $(call BuildPackage,firmware))
