SUBDIRS = src doc
pkgdata_DATA = AUTHORS README INSTALL

if IPHONE_OS
fakesign: all
	@if [ ! -x "$(SIGNHELPER)" ]; then \
		echo "Please call make with a valid SIGNHELPER (make SIGNHELPER=/path/to/helper)"; \
		exit 1; \
	fi
	$(SIGNHELPER) src/zsrelay src/zsrelay.signed

dist-deb: fakesign
	@cp -f $(srcdir)/debian/{pre,post}{inst,rm} debian/ || true
	@mkdir -p doc
	@mkdir -p tools
	@find $(srcdir)/doc -not -name '*.in' \
	                    -not -name '*.am' \
			    -not -name 'Makefile' \
			    -exec cp -l '{}' doc/ ';'
	@find $(srcdir)/tools -not -name '*.in' \
	                      -not -name '*.am' \
			      -not -name 'Makefile' -exec cp -l '{}' tools/ ';'
	@chmod +x debian/rules
	@chmod +x tools/*
	@SRCDIR=srcdir dpkg-buildpackage -uc -us -rfakeroot -d
endif

