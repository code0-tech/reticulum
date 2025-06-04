ARG RETICULUM_IMAGE_TAG=local

FROM ghcr.io/code0-tech/reticulum/ci-builds/mise:$RETICULUM_IMAGE_TAG

ARG RUBY_VERSION=3.2.2

RUN apk add --update --no-cache build-base tzdata zlib-dev perl linux-headers libffi readline yaml-dev
RUN mise install-into ruby@$RUBY_VERSION /usr/local/share/ruby
ENV PATH=/usr/local/share/ruby/bin:$PATH
