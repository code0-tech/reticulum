ARG RETICULUM_IMAGE_TAG=local

FROM ghcr.io/code0-tech/reticulum/ci-builds/rust:$RETICULUM_IMAGE_TAG AS chef
WORKDIR /aquila

FROM chef AS planner
COPY projects/aquila .
RUN cargo chef prepare --recipe-path recipe.json --bin aquila

FROM chef AS builder
COPY --from=planner /aquila/recipe.json recipe.json
RUN cargo chef cook --release --recipe-path recipe.json

COPY projects/aquila .
RUN cargo build --release

FROM alpine:3.24

RUN apk --update add libc6-compat
COPY --from=builder /aquila/target/release/aquila .

ARG RETICULUM_IMAGE_TAG=local
ENV AQUILA_VERSION=$RETICULUM_IMAGE_TAG

CMD ["/aquila"]
