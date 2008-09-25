SUBDIRS = src doc
pkgdata_DATA = AUTHORS README INSTALL

if IPHONE_OS
distclean-local:
	@rm -rf src/zsrelay/zsrelay_ || true
	@rm -rf src/zsrelay/zsrelay || true
	@rm -rf src/zscmd/zscmd_ || true
	@rm -rf src/zscmd/zscmd || true
	@rm -rf src/prefplug/ZSRelaySettings_ || true
	@rm -rf src/prefplug/ZSRelaySettings || true
	@rm -rf src/*/*.app
	@rm -rf src/*/*.bundle

fakesign: distclean-local all
if IPHONE_OS_RELEASE2
	@if [ ! -x "$(SIGNHELPER)" ]; then \
		echo "Please call make with a valid SIGNHELPER (make SIGNHELPER=/path/to/helper)"; \
		exit 1; \
	fi
	$(SIGNHELPER) src/zsrelay/zsrelay
	$(SIGNHELPER) src/zscmd/zscmd
	$(SIGNHELPER) src/prefplug/ZSRelaySettings
	$(SIGNHELPER) src/zslauncher/ZSLauncher
endif

app-bundle: fakesign
	@mkdir -p src/zsrelay/ZSRelay.app
	@cp $(srcdir)/misc/Info.plist src/zsrelay/ZSRelay.app/Info.plist
	@cp src/zsrelay/zsrelay src/zsrelay/ZSRelay.app/zsrelay

pref-bundle: app-bundle
	@mkdir -p src/prefplug/ZSRelaySettings.bundle
	@cp -r $(srcdir)/misc/Prefs/* src/prefplug/ZSRelaySettings.bundle/
	@cp src/prefplug/ZSRelaySettings src/prefplug/ZSRelaySettings.bundle/

launcher-bundle: pref-bundle
	@mkdir -p src/zslauncher/iPhoneModem.app
	@cp -r $(srcdir)/misc/Launcher/* src/zslauncher/iPhoneModem.app/
	@cp src/zslauncher/ZSLauncher src/zslauncher/iPhoneModem.app/

dist-deb: launcher-bundle
	@cp -f $(srcdir)/debian/{pre,post}{inst,rm} debian/ || true
	@mkdir -p doc
	@mkdir -p tools
	@mkdir -p misc
	@find $(srcdir)/doc -not -name '*.in' \
	                    -not -name '*.am' \
			    -not -name 'Makefile' \
			    -exec cp -l '{}' doc/ ';'
	@find $(srcdir)/tools -not -name '*.in' \
	                      -not -name '*.am' \
			      -not -name 'Makefile' -exec cp -l '{}' tools/ ';'
	@find $(srcdir)/misc  -not -name '*.in' \
	                      -not -name '*.am' \
			      -not -name 'Makefile' -exec cp -l '{}' misc/ ';'
	@chmod +x debian/rules
	@chmod +x tools/*
	@SRCDIR=srcdir dpkg-buildpackage -nc -uc -us -rfakeroot -d
endif

