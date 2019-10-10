# gst-plugin-ndi

A **WIP** plugin for gstreamer written in Vala to add support for [NewTek](https://www.newtek.com/)'s [NDI technology](https://ndi.tv/). Currently there is only an `ndisink` element implemented that takes raw video and (optionally) raw audio and passes it to the network as NDI.

This has not been tested in any production use cases and is currently a very early prototype. No thought or testing has been put into A/V sync yet (it may work, or it may drift, or it may just be completely wrong to start with).

## Building
### Compilation
Ensure the necessary dependencies are installed:
* pkg-config 
* meson 
* valac 
* libgstreamer1.0-dev 
* libgstreamer-plugins-base1.0-dev
* NDI SDK (installed as per the [Installing NDI SDK section](#installing-ndi-sdk) below)

Run `meson build` to configure the build environment. Change to the build directory and run `ninja` to build.
```
meson build --prefix=/usr
cd build
ninja
```

To install, copy `libgstndi.so` to the Gstreamer plugins directory (`/usr/lib/x86_64-linux-gnu/gstreamer-1.0/` on Ubuntu).

### Docker
The included Dockerfile depends on an unpublished Docker image called `libndi`. I have opted to not publish this due to the licensing around the NDI SDK. However, if you wish to use the Dockerfile in this repository, you can build your own `libndi` image that has the NDI SDK installed as per the instructions below.

### Installing NDI SDK
* You need to have `libavahi-common3` and `libavahi-client3` installed. These are dependencies of the NDI SDK.
* So that the build system can find the NDI SDK, install the following pkg-config file in `/usr/lib/x86_64-linux-gnu/pkgconfig/` as `ndi.pc`:
```
prefix=/usr
exec_prefix=${prefix}
libdir=${prefix}/lib/x86_64-linux-gnu
includedir=${prefix}/include/libndi
datarootdir=${prefix}/share
datadir=${datarootdir}

Name: NewTek NDI
Description: NewTek NDI
Version: 4.0
Libs: -L${libdir} -lndi
Cflags: -I${includedir}
```
* Install the NDI SDK shared libraries (`.so` files) into `/usr/lib/x86_64-linux-gnu/`
* Install the NDI SDK header files (`.h` files) into `/usr/include/libndi`
