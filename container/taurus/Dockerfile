ARG RETICULUM_IMAGE_TAG=local

FROM ghcr.io/code0-tech/reticulum/ci-builds/rust:$RETICULUM_IMAGE_TAG AS builder

WORKDIR /taurus
COPY projects/taurus .
RUN cargo build --release

# renovate: datasource=github-releases depName=code0-tech/code0-definition versioning=regex:^def-(?<currentValue>.+)$
ARG DEFINITION_VERSION=def-0.0.19
RUN apk add openssl-dev openssl-libs-static pkgconfig && cargo install code0-cli && code0-cli download -f standard -t $DEFINITION_VERSION

FROM alpine:3.22

RUN apk --update add libc6-compat
COPY --from=builder /taurus/target/release/taurus /taurus
COPY --from=builder /taurus/definitions /definitions

CMD ["/taurus"]
