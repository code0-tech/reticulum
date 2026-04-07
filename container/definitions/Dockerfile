ARG RETICULUM_IMAGE_TAG=local

FROM ghcr.io/code0-tech/reticulum/ci-builds/rust:$RETICULUM_IMAGE_TAG

WORKDIR /

RUN apk add openssl-dev openssl-libs-static pkgconfig

# renovate: datasource=crate depName=code0-cli
ARG CODE0_CLI_VERSION=0.0.12
RUN cargo install --version $CODE0_CLI_VERSION code0-cli

# renovate: datasource=github-releases depName=code0-tech/code0-definition versioning=regex:^def-(?<major>\d+)\.(?<minor>\d+)\.(?<patch>\d+)$
ARG DEFINITION_VERSION=def-0.0.22
LABEL org.opencontainers.image.version=$DEFINITION_VERSION
RUN code0-cli download -t $DEFINITION_VERSION
