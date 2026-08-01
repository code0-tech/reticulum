ARG RETICULUM_IMAGE_TAG=local

FROM ghcr.io/code0-tech/reticulum/ci-builds/definitions:$RETICULUM_IMAGE_TAG AS definitions

FROM ghcr.io/code0-tech/reticulum/ci-builds/rust:$RETICULUM_IMAGE_TAG AS chef
WORKDIR /draco

FROM chef AS planner
ARG VARIANT
COPY projects/draco .
RUN cargo chef prepare --recipe-path recipe.json --bin $VARIANT

FROM chef AS builder
ARG VARIANT
COPY --from=planner /draco/recipe.json recipe.json
RUN cargo chef cook --release --recipe-path recipe.json --bin $VARIANT

COPY projects/draco .
RUN cargo build --release --bin $VARIANT

FROM alpine:3.24
ARG VARIANT

RUN apk --update add libc6-compat
COPY --from=builder /draco/target/release/$VARIANT /draco
COPY --from=definitions /definitions/draco-$VARIANT /definitions/draco-$VARIANT

CMD ["/draco"]
