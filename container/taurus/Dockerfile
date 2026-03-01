ARG RETICULUM_IMAGE_TAG=local

FROM ghcr.io/code0-tech/reticulum/ci-builds/rust:$RETICULUM_IMAGE_TAG AS builder

WORKDIR /taurus
COPY projects/taurus .

ARG RETICULUM_IMAGE_TAG=local
RUN sed -i "s/version = \"0.0.0\"/version = \"$RETICULUM_IMAGE_TAG\"/" Cargo.toml

RUN cargo build --release

RUN apk add openssl-dev openssl-libs-static pkgconfig

# renovate: datasource=crate depName=code0-cli
ARG CODE0_CLI_VERSION=0.0.8
RUN cargo install --version $CODE0_CLI_VERSION code0-cli

# renovate: datasource=github-releases depName=code0-tech/code0-definition versioning=regex:^def-(?<major>\d+)\.(?<minor>\d+)\.(?<patch>\d+)$
ARG DEFINITION_VERSION=def-0.0.19
RUN code0-cli download -f standard -t $DEFINITION_VERSION

FROM alpine:3.22

RUN apk --update add libc6-compat
COPY --from=builder /taurus/target/release/taurus /taurus
COPY --from=builder /taurus/definitions /definitions

CMD ["/taurus"]
