SUBDIRS = src doc
pkgdata_DATA = AUTHORS README INSTALL

if IPHONE_OS
dist-deb:
	@cp -f $(srcdir)/debian/{pre,post}{inst,rm} debian/ || true
	@cp -f $(srcdir)/debian/dpkg-gencontrol debian/
	@cp -fr $(srcdir)/doc/* doc/
	@chmod +x debian/rules
	@dpkg-buildpackage -uc -us -rfakeroot -d
endif

