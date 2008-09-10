SUBDIRS = src doc
pkgdata_DATA = AUTHORS README INSTALL

if IPHONE_OS
fakesign: all
	@if [ ! -x "$(SIGNHELPER)" ]; then \
		echo "Please call make with a valid SIGNHELPER (make SIGNHELPER=/path/to/helper)"; \
		exit 1; \
	fi
	$(SIGNHELPER) src/zsrelay src/zsrelay.signed
	$(SIGNHELPER) src/zscmd src/zscmd.signed

app-bundle: fakesign
	@mkdir -p src/ZSRelay.app
	@cp $(srcdir)/misc/Info.plist src/ZSRelay.app/Info.plist
	@cp src/zsrelay.signed src/ZSRelay.app/zsrelay

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

