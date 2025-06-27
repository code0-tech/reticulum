ARG RETICULUM_IMAGE_TAG=local

FROM ghcr.io/code0-tech/reticulum/ci-builds/rust:$RETICULUM_IMAGE_TAG AS builder

WORKDIR /taurus
COPY projects/taurus .
RUN cargo build --release

FROM alpine:3.22

RUN apk --update add libc6-compat
COPY --from=builder /taurus/target/release/taurus .

CMD ["/taurus"]
