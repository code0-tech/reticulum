ARG RETICULUM_IMAGE_TAG=local

FROM ghcr.io/code0-tech/reticulum/ci-builds/rust:$RETICULUM_IMAGE_TAG AS builder
ARG VARIANT

WORKDIR /draco
COPY projects/draco .
WORKDIR /draco/adapters/$VARIANT
RUN cargo build --release

FROM alpine:3.22
ARG VARIANT

RUN apk --update add libc6-compat
COPY --from=builder /draco/target/release/$VARIANT /draco

CMD ["/draco"]
