ARG RETICULUM_IMAGE_TAG=local

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

FROM alpine:3.23
ARG VARIANT

RUN apk --update add libc6-compat
COPY --from=builder /draco/target/release/$VARIANT /draco

CMD ["/draco"]
