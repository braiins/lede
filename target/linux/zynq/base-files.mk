define Package/base-files/install-target
	$(VERSION_SED) \
		$(1)/etc/bos_version
endef
