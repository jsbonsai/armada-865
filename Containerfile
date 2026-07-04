ARG FEX_PKG=ghcr.io/virtudude/armada-packages/fex@sha256:db24aa032c986e595427b8bba668d0201fe9dc9176cae6050c4137113a06c3c0
ARG MESA_PKG=ghcr.io/virtudude/armada-packages/mesa@sha256:02508c22812d47b052378c655129c0847066b19473b142876a403913189d5c8e
ARG MANGOHUD_PKG=ghcr.io/jsbonsai/armada-packages/mangohud@sha256:38460dfe33e9532bd4f0bbd49df661ccb6a9e2fda6d7b802a0d951ce7790a7e0
ARG GAMESCOPE_PKG=ghcr.io/virtudude/armada-packages/gamescope@sha256:d2e4f3125e1d889665671c69bfab3662474d0fcdca9aeeed58e00ceeb8a97e2a
ARG KERNEL_PKG=ghcr.io/jsbonsai/armada-packages/kernel@sha256:e3e6cbaa4a7487aa24c2fe83fe121e53c190ae4b2daef5d3915c04fc22068e14
ARG INPUTPLUMBER_PKG=ghcr.io/virtudude/armada-packages/inputplumber@sha256:1df4f9fc74dbb41c7ebe33bb6934745a4ab01c002178ae2bd34e7e99cebafd35
ARG EXTEST_PKG=ghcr.io/virtudude/armada-packages/extest@sha256:3b0d047706d5f3398972d433f0b76f6f2d953bf52383a428857ede13cc16a109
ARG NETWORKMANAGER_PKG=ghcr.io/virtudude/armada-packages/networkmanager@sha256:f9b05673dc312d28660ac89e3bf268bd756a8f000dafa7c950f5dd5da22d5b80

FROM ${FEX_PKG} AS fex
FROM ${MESA_PKG} AS mesa
FROM ${MANGOHUD_PKG} AS mangohud
FROM ${GAMESCOPE_PKG} AS gamescope
FROM ${KERNEL_PKG} AS kernel
FROM ${INPUTPLUMBER_PKG} AS inputplumber
FROM ${NETWORKMANAGER_PKG} AS networkmanager
FROM ${EXTEST_PKG} AS extest

FROM docker.io/library/node:22-slim AS decky-build
WORKDIR /build
COPY decky/armada-control/package.json decky/armada-control/package-lock.json ./
RUN npm ci
COPY decky/armada-control/ ./
RUN npm run build

FROM scratch AS ctx
COPY build_files /build_files/
COPY decky /decky/
COPY system_files /system_files/

FROM quay.io/fedora/fedora-bootc:44
ARG ARMADA_VERSION=unknown
LABEL org.opencontainers.image.version="${ARMADA_VERSION}"

RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=bind,from=fex,source=/rpms,target=/packages/fex \
    --mount=type=bind,from=mesa,source=/rpms,target=/packages/mesa \
    --mount=type=bind,from=mangohud,source=/rpms,target=/packages/mangohud \
    --mount=type=bind,from=gamescope,source=/rpms,target=/packages/gamescope \
    --mount=type=bind,from=kernel,source=/kernel,target=/packages/kernel \
    --mount=type=bind,from=inputplumber,source=/rpms,target=/packages/inputplumber \
    --mount=type=bind,from=networkmanager,source=/rpms,target=/packages/networkmanager \
    --mount=type=bind,from=extest,source=/,target=/packages/extest \
    --mount=type=bind,from=decky-build,source=/build/dist,target=/packages/decky-dist \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    mkdir -p /usr/lib/armada && \
    printf '%s\n' "${ARMADA_VERSION}" >/usr/lib/armada/version && \
    /ctx/build_files/build.sh

RUN bootc container lint
