ARG RETICULUM_IMAGE_TAG=local

FROM ghcr.io/code0-tech/reticulum/ci-builds/rust:$RETICULUM_IMAGE_TAG AS builder

WORKDIR /aquila
COPY projects/aquila .

ARG RETICULUM_IMAGE_TAG=local
RUN sed -i "s/version = \"0.0.0\"/version = \"$RETICULUM_IMAGE_TAG\"/" Cargo.toml

RUN cargo build --release

FROM alpine:3.22

RUN apk --update add libc6-compat
COPY --from=builder /aquila/target/release/aquila .

CMD ["/aquila"]
