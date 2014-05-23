default:
	test -d build || mkdir build
	perl build_site.pl base_template.html content
	cp -R content/copy/* build
	cp build_site.pl build/code/
