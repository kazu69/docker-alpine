FROM alpine:latest
MAINTAINER kazu69

RUN apk --update add \
    bash \
    git \
    wget \
    curl \
    vim \
    build-base \
    readline-dev \
    openssl-dev \
    zlib-dev \
    ca-certificates \
    tar \
    xz \
&&  rm -rf /var/cache/apk/*

RUN apk --update add tzdata && \
    cp /usr/share/zoneinfo/Asia/Tokyo /etc/localtime && \
    apk del tzdata && \
    rm -rf /var/cache/apk/*
