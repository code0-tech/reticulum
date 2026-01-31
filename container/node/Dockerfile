ARG RETICULUM_IMAGE_TAG=local
ARG NODE_VERSION=24.8.0

FROM node:$NODE_VERSION-alpine AS node_image
FROM ghcr.io/code0-tech/reticulum/ci-builds/mise:$RETICULUM_IMAGE_TAG

ARG NODE_VERSION=24.8.0
LABEL org.opencontainers.image.version=$NODE_VERSION

COPY --from=node_image /usr/lib /usr/lib
COPY --from=node_image /usr/local/lib /usr/local/lib
COPY --from=node_image /usr/local/include /usr/local/include
COPY --from=node_image /usr/local/bin /usr/local/bin
ENV PATH=/usr/local/bin:$PATH
