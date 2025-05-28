ARG RETICULUM_IMAGE_TAG=local

FROM ghcr.io/code0-tech/reticulum/ci-builds/rust:$RETICULUM_IMAGE_TAG as builder

WORKDIR /aquila
COPY projects/aquila .
RUN cargo build --release

FROM alpine:3.21

RUN apk --update add libc6-compat
COPY --from=builder /aquila/target/release/aquila .

CMD ["/aquila"]
