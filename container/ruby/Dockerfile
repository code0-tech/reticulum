ARG RETICULUM_IMAGE_TAG=local

FROM ghcr.io/code0-tech/reticulum/ci-builds/mise:$RETICULUM_IMAGE_TAG

ARG RUBY_VERSION=3.4.7
LABEL org.opencontainers.image.version=$RUBY_VERSION

RUN apk add --update --no-cache build-base tzdata zlib-dev perl linux-headers libffi readline yaml-dev
COPY container/ruby/patches /ruby-patches
ENV MISE_RUBY_APPLY_PATCHES=/ruby-patches/0001-thread_pthread.c-make-get_main_stack-portable-on-lin.patch
RUN mise install-into ruby@$RUBY_VERSION /usr/local/share/ruby; exit_code=$?; rm -rf /ruby-patches; [ $exit_code -ne 0 ] && tail -n 500 /tmp/ruby-build.*.log; exit $exit_code
ENV PATH=/usr/local/share/ruby/bin:$PATH
