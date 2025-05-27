FROM alpine:3.21
LABEL org.opencontainers.image.source=https://github.com/code0-tech/reticulum

RUN echo "@edge http://dl-cdn.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories
RUN apk add bash curl tar
RUN apk add mise@edge
