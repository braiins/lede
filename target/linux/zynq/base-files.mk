define Package/base-files/install-target
	$(VERSION_SED) \
		$(1)/etc/bos_major \
		$(1)/etc/bos_version
	$(call Package/base-files/install-subtarget,$(1))
endef
