define Package/base-files/install-subtarget
	$(INSTALL_DIR) $(1)/etc/rc.button
	$(INSTALL_BIN) $(PLATFORM_DIR)/miner/rc.button/BTN_0 $(1)/etc/rc.button/

	$(INSTALL_DIR) $(1)/lib/preinit
	$(CP) $(PLATFORM_DIR)/miner/dm1/preinit_dragonmint.sh $(1)/lib/preinit/05_preinit_dragonmint.sh
endef
