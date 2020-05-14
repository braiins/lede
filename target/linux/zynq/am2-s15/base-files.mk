define Package/base-files/install-subtarget
	$(INSTALL_DIR) $(1)/etc/rc.button
	$(INSTALL_BIN) $(PLATFORM_DIR)/miner/rc.button/BTN_0 $(1)/etc/rc.button/
endef
