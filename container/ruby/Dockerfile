ARG RETICULUM_IMAGE_TAG=local

FROM ghcr.io/code0-tech/reticulum/ci-builds/mise:$RETICULUM_IMAGE_TAG

ARG RUBY_VERSION=3.4.7

RUN apk add --update --no-cache build-base tzdata zlib-dev perl linux-headers libffi readline yaml-dev
RUN mise install-into ruby@$RUBY_VERSION /usr/local/share/ruby; exit_code=$?; [ $exit_code -ne 0 ] && tail -n 500 /tmp/ruby-build.*.log; exit $exit_code
ENV PATH=/usr/local/share/ruby/bin:$PATH
