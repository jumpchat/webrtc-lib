WEBRTC_VERSION=2.2.5
WEBRTC_REVISISON=80865776cf8a1a811166ee005951b7f5b01deacd
WEBRTC_REPO=https://webrtc.googlesource.com/src.git
WEBRTC_ROOT=${HOME}/.webrtc
WEBRTC_BUILDDIR=${WEBRTC_ROOT}/webrtc/${WEBRTC_REVISISON}
WEBRTC_ARCH=x64
WEBRTC_DEBUG=false
ifeq ($(DEBUG),true)
	WEBRTC_BUILDMODE=Debug
	WEBRTC_DEBUG=true
	WEBRTC_LIBNAME=libwebrtcd.a
else
	WEBRTC_BUILDMODE=Release
	WEBRTC_DEBUG=false
	WEBRTC_LIBNAME=libwebrtc.a
endif
WEBRTC_OUTDIR=${WEBRTC_OS}/${WEBRTC_ARCH}/out/${WEBRTC_BUILDMODE}
WEBRTC_BUILD_ARGS=is_debug=${WEBRTC_DEBUG} \
	rtc_include_tests=false \
	rtc_libvpx_build_vp9=true \
	treat_warnings_as_errors=false \
	rtc_enable_protobuf=false \
	use_custom_libcxx=false \
	ffmpeg_branding="Chrome" \
	target_cpu="${WEBRTC_ARCH}" \
	${WEBRTC_EXTRA_ARGS}

GCLIENT=${WEBRTC_ROOT}/depot_tools/gclient
GN=${WEBRTC_ROOT}/depot_tools/gn
NINJA=${WEBRTC_ROOT}/depot_tools/ninja
TAR=tar
BASH=bash
export PATH:=${WEBRTC_ROOT}/depot_tools:/usr/bin:${PATH}

UNAME_S := $(shell uname -s)
ifeq ($(OS),Windows_NT)
	export DEPOT_TOOLS_WIN_TOOLCHAIN=0
	WEBRTC_ROOT=$(subst \,/,${HOME}/.webrtc)
	WEBRTC_OS=win
	GCLIENT=${WEBRTC_ROOT}/depot_tools/gclient.bat
	GN=${WEBRTC_ROOT}/depot_tools/gn.bat
	NINJA=${WEBRTC_ROOT}/depot_tools/ninja.exe
	TAR=$(subst \,/,${HOME}/scoop/shims/tar.exe)
	ifeq ($(DEBUG),true)
		WEBRTC_LIBNAME=webrtcd.lib
	else
		WEBRTC_LIBNAME=webrtc.lib
	endif
	ifeq ($(UNAME_P),x86_64)
		WEBRTC_ARCH=x64
	endif
	ifneq ($(filter %86,$(UNAME_P)),)
		WEBRTC_ARCH=x86
	endif
	BASH=busybox bash
else
    ifeq ($(UNAME_S),Linux)
        WEBRTC_OS=linux
    endif
    ifeq ($(UNAME_S),Darwin)
        WEBRTC_OS=mac
    endif
    UNAME_P := $(shell uname -m)
    ifeq ($(UNAME_P),x86_64)
        WEBRTC_ARCH=x64
    endif
    ifneq ($(filter %86,$(UNAME_P)),)
        WEBRTC_ARCH=x86
    endif
    ifneq ($(filter arm%,$(UNAME_P)),)
        WEBRTC_ARCH=arm
    endif
endif
WEBRTC_LIBDIR=${WEBRTC_BUILDDIR}/lib/${WEBRTC_OS}/${WEBRTC_ARCH}
WEBRTC_LIB=${WEBRTC_LIBDIR}/${WEBRTC_LIBNAME}
ifeq ($(WEBRTC_OS), android)
	WEBRTC_BUILD_ARGS += rtc_use_h264=false
	WEBRTC_LIB = ${WEBRTC_BUILDDIR}/lib/${WEBRTC_OS}/${WEBRTC_ARCH}/libjingle_peerconnection_java.jar
else
	WEBRTC_BUILD_ARGS += rtc_use_h264=true
endif
WEBRTC_BUILD_ARGS += target_cpu="${WEBRTC_ARCH}"
WEBRTC_BUILD_ARGS += target_os="${WEBRTC_OS}"
WEBRTC_TARBALL=libwebrtc-${WEBRTC_OS}-${WEBRTC_ARCH}-${WEBRTC_VERSION}.tar.xz

build: info depot_tools webrtc_sync webrtc_build webrtc_headers

all:
	${MAKE} DEBUG=false build
	${MAKE} DEBUG=true build
	${MAKE} webrtc_headers webrtc_tarball

debug:
	${MAKE} DEBUG=true build

arm: depot_tools webrtc_sync arm_tools
	${MAKE} WEBRTC_ARCH=arm

arm6: depot_tools webrtc_sync arm_tools
	${MAKE} WEBRTC_ARCH=arm WEBRTC_EXTRA_ARGS='arm_version=6 arm_arch="armv6" arm_float_abi="hard" arm_fpu="vfp" arm_use_neon=false rtc_use_h264=false'

x64:
	${MAKE} WEBRTC_ARCH=x64

x86:
	${MAKE} WEBRTC_ARCH=x86

android: ${WEBRTC_BUILDDIR}/webrtc_android_sync
	${MAKE} WEBRTC_ARCH=arm WEBRTC_OS=android

ios: ${WEBRTC_BUILDDIR}/webrtc_ios_sync
	bash ${WEBRTC_BUILDDIR}/src/tools_webrtc/ios/build_ios_libs.sh

help:
	@echo "make [architecture] [DEBUG=(true|false)]"
	@echo "Architectures:"
	@echo "  * arm"
	@echo "  * x64"
	@echo "  * x86"

clean:
	rm -rf ${WEBRTC_BUILDDIR}/lib
	rm -rf ${WEBRTC_BUILDDIR}/include
	rm -rf ${WEBRTC_BUILDDIR}/src/${WEBRTC_OS}

info:
	@echo "Build mode:   ${WEBRTC_BUILDMODE}"
	@echo "OS:           ${WEBRTC_OS}"
	@echo "Architecture: ${WEBRTC_ARCH}"

depot_tools: ${WEBRTC_ROOT}/depot_tools
${WEBRTC_ROOT}/depot_tools:
	mkdir -p ${WEBRTC_ROOT}
	cd ${WEBRTC_ROOT} && git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git

webrtc_sync: ${WEBRTC_BUILDDIR}/webrtc_sync
${WEBRTC_BUILDDIR}/webrtc_sync:
	mkdir -p ${WEBRTC_BUILDDIR}
	cd ${WEBRTC_BUILDDIR} && \
		${GCLIENT} config --unmanaged --name=src ${WEBRTC_REPO} && \
		${GCLIENT} sync --nohooks --revision src@${WEBRTC_REVISISON} \
			--reset --no-history --delete_unversioned_trees --with_branch_heads && \
		${GCLIENT} runhooks && \
		touch webrtc_sync

webrtc_build: ${WEBRTC_LIB}

# windows, linux, mac lib
${WEBRTC_LIB}: ${WEBRTC_BUILDDIR}/webrtc_sync
	mkdir -p ${WEBRTC_LIBDIR}
	cd ${WEBRTC_BUILDDIR}/src && \
		${GN} gen ${WEBRTC_OUTDIR} --args='${WEBRTC_BUILD_ARGS}' && \
		${NINJA} -C ${WEBRTC_OUTDIR} examples jsoncpp desktop_capture
	${BASH} -x ./link.sh ${WEBRTC_LIB} ${WEBRTC_BUILDDIR}/src/${WEBRTC_OUTDIR}

# android lib - can conly be built on linux
${WEBRTC_BUILDDIR}/lib/${WEBRTC_OS}/${WEBRTC_ARCH}/libjingle_peerconnection_java.jar: ${WEBRTC_BUILDDIR}/webrtc_sync
	mkdir -p ${WEBRTC_BUILDDIR}/lib/${WEBRTC_OS}/${WEBRTC_ARCH}/armeabi-v7a
	cd ${WEBRTC_BUILDDIR}/src && \
		${GN} gen ${WEBRTC_OUTDIR} --args='${WEBRTC_BUILD_ARGS}' && \
		${NINJA} -C ${WEBRTC_OUTDIR} examples jsoncpp
	cp ${WEBRTC_BUILDDIR}/src/${WEBRTC_OUTDIR}/libjingle_peerconnection_so.so ${WEBRTC_BUILDDIR}/lib/${WEBRTC_OS}/${WEBRTC_ARCH}/armeabi-v7a
	cp ${WEBRTC_BUILDDIR}/src/${WEBRTC_OUTDIR}/lib.java/sdk/android/libjingle_peerconnection_java.jar ${WEBRTC_BUILDDIR}/lib/${WEBRTC_OS}/${WEBRTC_ARCH}

webrtc_headers: ${WEBRTC_BUILDDIR}/include/rtc_base ${WEBRTC_BUILDDIR}/include/json ${WEBRTC_BUILDDIR}/include/absl ${WEBRTC_BUILDDIR}/include/libyuv
${WEBRTC_BUILDDIR}/include/rtc_base:
	mkdir -p ${WEBRTC_BUILDDIR}/rtc_base
	cd ${WEBRTC_BUILDDIR} && \
		rsync -avm --include '*.h' -f 'hide,! */' src/api src/rtc_base src/pc src/media src/modules src/p2p src/call src/common_video src/common_audio src/logging src/system_wrappers src/*.h include/
${WEBRTC_BUILDDIR}/include/json:
	cd ${WEBRTC_BUILDDIR} && \
		rsync -avm --include '*.h' -f 'hide,! */' src/third_party/jsoncpp/source/include/json include/
${WEBRTC_BUILDDIR}/include/absl:
	cd ${WEBRTC_BUILDDIR} && \
		rsync -avm --include '*.h' -f 'hide,! */' src/third_party/abseil-cpp/absl include/
${WEBRTC_BUILDDIR}/include/libyuv:
	cd ${WEBRTC_BUILDDIR} && \
		rsync -avm --include '*.h' -f 'hide,! */' src/third_party/libyuv/include/libyuv include/

webrtc_tarball: ${WEBRTC_TARBALL}
${WEBRTC_TARBALL}: ${WEBRTC_LIB} ${WEBRTC_BUILDDIR}/include/webrtc ${WEBRTC_BUILDDIR}/include/json
	cd ${WEBRTC_ROOT} && \
		${TAR} -Jcf ${WEBRTC_TARBALL} webrtc/${WEBRTC_REVISISON}/include webrtc/${WEBRTC_REVISISON}/lib/${WEBRTC_OS}/${WEBRTC_ARCH}
	mv ${WEBRTC_ROOT}/${WEBRTC_TARBALL} .

arm_tools: ${WEBRTC_BUILDDIR}/src/build/linux/debian_stretch_arm-sysroot
${WEBRTC_BUILDDIR}/src/build/linux/debian_stretch_arm-sysroot:
	cd ${WEBRTC_BUILDDIR}/src/ && build/linux/sysroot_scripts/install-sysroot.py --arch=arm

${WEBRTC_BUILDDIR}/webrtc_android_sync: ${WEBRTC_BUILDDIR}/webrtc_sync
	mkdir -p ${WEBRTC_BUILDDIR}
	cd ${WEBRTC_BUILDDIR} && \
		(grep -q -F 'target_os' .gclient || echo 'target_os = ["android", "unix"]' >> .gclient) && \
		${GCLIENT} sync --revision src@${WEBRTC_REVISISON} \
			--reset --no-history --delete_unversioned_trees --with_branch_heads && \
		./src/build/install-build-deps-android.sh && \
		touch webrtc_android_sync

${WEBRTC_BUILDDIR}/webrtc_ios_sync: ${WEBRTC_BUILDDIR}/webrtc_sync
	mkdir -p ${WEBRTC_BUILDDIR}
	cd ${WEBRTC_BUILDDIR} && \
		(grep -q -F 'target_os' .gclient || echo 'target_os = ["ios", "mac"]' >> .gclient) && \
		${GCLIENT} sync --revision src@${WEBRTC_REVISISON} \
			--reset --no-history --delete_unversioned_trees --with_branch_heads && \
		touch webrtc_ios_sync
