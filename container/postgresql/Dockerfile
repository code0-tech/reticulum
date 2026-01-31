ARG RETICULUM_IMAGE_TAG=local

FROM ghcr.io/code0-tech/reticulum/ci-builds/mise:$RETICULUM_IMAGE_TAG

ARG POSTGRESQL_VERSION=16.1
LABEL org.opencontainers.image.version=$POSTGRESQL_VERSION

RUN apk add --update --no-cache build-base linux-headers icu-data-full icu-dev readline-dev zlib-dev libressl-dev musl-dev libffi-dev util-linux-dev

RUN mise plugins install postgres
RUN echo "POSTGRES_SKIP_INITDB=true" > .install-env \
    && MISE_ENV_FILE=.install-env mise install-into postgres@$POSTGRESQL_VERSION /usr/local/share/postgres \
    && rm .install-env
ENV PATH=/usr/local/share/postgres/bin:$PATH
