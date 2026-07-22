ARG RETICULUM_IMAGE_TAG=local

FROM ghcr.io/code0-tech/reticulum/ci-builds/definitions:$RETICULUM_IMAGE_TAG AS definitions

FROM ghcr.io/code0-tech/reticulum/ci-builds/rust:$RETICULUM_IMAGE_TAG AS builder

WORKDIR /taurus
COPY projects/taurus .

ARG RETICULUM_IMAGE_TAG=local
RUN sed -i "s/version = \"0.0.0\"/version = \"$RETICULUM_IMAGE_TAG\"/" Cargo.toml

RUN cargo build --release

FROM alpine:3.24

RUN apk --update add libc6-compat
COPY --from=builder /taurus/target/release/taurus /taurus
COPY --from=definitions /definitions/taurus-boolean /definitions/taurus-boolean
COPY --from=definitions /definitions/taurus-control /definitions/taurus-control
COPY --from=definitions /definitions/taurus-http /definitions/taurus-http
COPY --from=definitions /definitions/taurus-list /definitions/taurus-list
COPY --from=definitions /definitions/taurus-number /definitions/taurus-number
COPY --from=definitions /definitions/taurus-object /definitions/taurus-object
COPY --from=definitions /definitions/taurus-text /definitions/taurus-text

CMD ["/taurus"]
