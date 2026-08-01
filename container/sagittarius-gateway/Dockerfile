ARG RETICULUM_IMAGE_TAG=local

FROM ghcr.io/code0-tech/reticulum/ci-builds/rust:$RETICULUM_IMAGE_TAG AS chef
WORKDIR /sagittarius

FROM chef AS planner
COPY projects/sagittarius/Cargo.toml .
COPY projects/sagittarius/Cargo.lock .
COPY projects/sagittarius/gateway gateway
RUN cargo chef prepare --recipe-path recipe.json --bin gateway

FROM chef AS builder
COPY --from=planner /sagittarius/recipe.json recipe.json
RUN cargo chef cook --release --recipe-path recipe.json

COPY projects/sagittarius/Cargo.toml .
COPY projects/sagittarius/Cargo.lock .
COPY projects/sagittarius/gateway gateway

RUN cargo build --release

FROM alpine:3.24

RUN apk --update add libc6-compat
COPY --from=builder /sagittarius/target/release/gateway .

ARG RETICULUM_IMAGE_TAG=local
ENV GATEWAY_VERSION=$RETICULUM_IMAGE_TAG

CMD ["/gateway"]
