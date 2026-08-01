ARG RETICULUM_IMAGE_TAG=local

FROM ghcr.io/code0-tech/reticulum/ci-builds/definitions:$RETICULUM_IMAGE_TAG AS definitions

FROM ghcr.io/code0-tech/reticulum/ci-builds/rust:$RETICULUM_IMAGE_TAG AS chef
WORKDIR /taurus

FROM chef AS planner
COPY projects/taurus .
RUN cargo chef prepare --recipe-path recipe.json --bin taurus

FROM chef AS builder
COPY --from=planner /taurus/recipe.json recipe.json
RUN cargo chef cook --release --recipe-path recipe.json -p taurus

COPY projects/taurus .
RUN cargo build --release -p taurus

FROM alpine:3.23

RUN apk --update add libc6-compat
COPY --from=builder /taurus/target/release/taurus /taurus
COPY --from=definitions /definitions/taurus-boolean /definitions/taurus-boolean
COPY --from=definitions /definitions/taurus-control /definitions/taurus-control
COPY --from=definitions /definitions/taurus-http /definitions/taurus-http
COPY --from=definitions /definitions/taurus-list /definitions/taurus-list
COPY --from=definitions /definitions/taurus-number /definitions/taurus-number
COPY --from=definitions /definitions/taurus-object /definitions/taurus-object
COPY --from=definitions /definitions/taurus-text /definitions/taurus-text

ARG RETICULUM_IMAGE_TAG=local
ENV TAURUS_VERSION=$RETICULUM_IMAGE_TAG

CMD ["/taurus"]
