ARG RETICULUM_IMAGE_TAG=local

FROM ghcr.io/code0-tech/reticulum/ci-builds/mise:$RETICULUM_IMAGE_TAG

ARG RUST_VERSION=1.89
LABEL org.opencontainers.image.version=$RUST_VERSION

RUN apk add build-base
RUN mise install-into rust@$RUST_VERSION /usr/local/share/rust
ENV PATH=/usr/local/share/rust:$PATH
