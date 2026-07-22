# Author:       Casey Sparks
# Date:         July 31, 2024
# Description:  Debian 12 image
FROM docker.io/library/debian:12

LABEL contact="docker@caseysparkz.com"
LABEL maintainer="docker@caseysparkz.com"
LABEL parent_image="docker.io/library/debian:12"

ENV DEBCONF_NOWARNINGS yes
ENV DEBIAN_FRONTEND noninteractive
ENV TZ UTC

RUN true                                                                    \
  && echo "${TZ}" > /etc/timezone                                           \
  && apt-get update                                                         \
  && apt-get install                                                        \
    --assume-yes                                                            \
    --no-install-recommends                                                 \
    "locales=2.36-9+deb12u7"                                                \
  && localedef                                                              \
    -i en_US                                                                \
    -c                                                                      \
    -f UTF-8                                                                \
    -A /usr/share/locale/locale.alias                                       \
    en_US.UTF-8                                                             \
  && rm                                                                     \
    --recursive                                                             \
    --force                                                                 \
    /var/lib/apt/lists/*                                                    \
  && useradd                                                                \
    --home-dir "/home/app"                                                  \
    --create-home                                                           \
    --shell /usr/bin/bash                                                   \
    --system                                                                \
    app

WORKDIR /home/app

USER app
