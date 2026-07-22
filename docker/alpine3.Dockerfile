# Author:       Casey Sparks
# Date:         July 31, 2024
# Description:  Alpine 3.20.2
FROM docker.io/library/alpine:3.20.2

LABEL contact="docker@caseysparkz.com"
LABEL maintainer="docker@caseysparkz.com"
LABEL parent_image="docker.io/library/alpine:3.20.2"

ENV LANG "en_US.UTF8"
ENV LANGUAGE "en_US.UTF8"
ENV LC_ALL "en_US.UTF8"

RUN true                                                                    \
    && apk add --no-cache                                                   \
        musl-locales=0.1.0-r1                                               \
        musl-locales-lang=0.1.0-r1                                          \
        tzdata=2026b-r0                                                     \
    && ln -s "/usr/share/zoneinfo/UTC" /etc/localtime                       \
    && echo "UTC" > /etc/timezone                                           \
    && adduser                                                              \
        -h "/home/app"                                                      \
        -s /usr/bin/bash                                                    \
        -S                                                                  \
        app

WORKDIR "/home/app"

USER "app"
