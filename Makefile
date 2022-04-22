.ONESHELL: 
VOL_PATH=$(shell podman volume inspect --format '{{.Mountpoint}}' apt_cache)
build:
	mkdir -p build
	[ -f opentrack/CMakeLists.real ] && echo 'CMakeLists.real exists, manual cleanup needed' && exit 1
	(
		set -e
		mv opentrack/CMakeLists.txt opentrack/CMakeLists.real
		cp CMakeListsOverride.txt opentrack/CMakeLists.txt
		
		sed -i s/-m32// opentrack/proto-wine/CMakeLists.txt

		podman build \
			-v ${VOL_PATH}:/var/cache/apt \
			-t build_cont \
			.

		podman run -it \
			-v $$(pwd):/project:O \
			-v $$(pwd)/build/:/project/build \
			-w /project \
			build_cont \
			make _build
	)
	EXIT=$$?
	mv opentrack/CMakeLists.real opentrack/CMakeLists.txt
	exit $$EXIT
.PHONY: build

_build:
	set -e
	cd build
	cmake ../opentrack \
		-DSDK_WINE=true \
		-DCMAKE_INSTALL_PREFIX=/usr \
		-DCMAKE_BUILD_TYPE=Release
	
	make -j8
	make package

init:
	podman volume create apt_cache
.PHONY: init