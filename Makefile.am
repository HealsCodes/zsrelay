SUBDIRS = src doc
pkgdata_DATA = AUTHORS README INSTALL

if IPHONE_OS
distclean-local:
	@rm -rf src/zsrelay/zsrelay_ || true
	@rm -rf src/zsrelay/zsrelay || true
	@rm -rf src/zscmd/zscmd_ || true
	@rm -rf src/zscmd/zscmd || true
	@rm -rf src/*/*.app
	@rm -rf src/*/*.bundle

fakesign: distclean-local all
	@if [ ! -x "$(SIGNHELPER)" ]; then \
		echo "Please call make with a valid SIGNHELPER (make SIGNHELPER=/path/to/helper)"; \
		exit 1; \
	fi
	@$(SIGNHELPER) src/zsrelay/zsrelay
	@$(SIGNHELPER) src/zscmd/zscmd

app-bundle: fakesign
	@mkdir -p src/zsrelay/ZSRelay.app
	@cp $(srcdir)/misc/Info.plist src/zsrelay/ZSRelay.app/Info.plist
	@cp src/zsrelay/zsrelay src/zsrelay/ZSRelay.app/zsrelay

dist-deb: app-bundle
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
	@SRCDIR=srcdir dpkg-buildpackage -uc -us -rfakeroot -d
endif

