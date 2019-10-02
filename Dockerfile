FROM libndi:latest AS build

RUN apt-get update && apt-get install -y --no-install-recommends pkg-config meson valac libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev gcc && rm -rf /var/lib/apt/lists/*

COPY . /build
WORKDIR /build
RUN meson build; ninja -C build;

FROM libndi:latest
RUN apt-get update && apt-get install -y --no-install-recommends gstreamer1.0-tools gstreamer1.0-plugins-base gstreamer1.0-plugins-good gstreamer1.0-plugins-bad gstreamer1.0-plugins-ugly libavahi-common3 && rm -rf /var/lib/apt/lists/*

COPY --from=build /build/build/libgstndi.so /usr/lib/x86_64-linux-gnu/gstreamer-1.0/
