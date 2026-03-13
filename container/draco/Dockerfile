ARG RETICULUM_IMAGE_TAG=local

FROM ghcr.io/code0-tech/reticulum/ci-builds/definitions:$RETICULUM_IMAGE_TAG AS definitions

FROM ghcr.io/code0-tech/reticulum/ci-builds/rust:$RETICULUM_IMAGE_TAG AS builder
ARG VARIANT

WORKDIR /draco
COPY projects/draco .

ARG RETICULUM_IMAGE_TAG=local
RUN sed -i "s/version = \"0.0.0\"/version = \"$RETICULUM_IMAGE_TAG\"/" Cargo.toml

WORKDIR /draco/adapters/$VARIANT
RUN cargo build --release

FROM alpine:3.22
ARG VARIANT

RUN apk --update add libc6-compat
COPY --from=builder /draco/target/release/$VARIANT /draco
COPY --from=definitions /definitions/$VARIANT /definitions/$VARIANT

CMD ["/draco"]
