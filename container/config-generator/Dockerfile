ARG RETICULUM_IMAGE_TAG=local

FROM ghcr.io/code0-tech/reticulum/ci-builds/ruby:$RETICULUM_IMAGE_TAG

WORKDIR /config-generator
COPY container/config-generator/templates templates
COPY container/config-generator/generate.rb generate.rb

CMD ["ruby", "generate.rb"]
