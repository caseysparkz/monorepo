# Author:       Casey Sparks
# Date:         July 31, 2024
# Description:  Python 3.11.2 image

FROM 770088062852.dkr.ecr.us-west-2.amazonaws.com/debian12:0.0.1

LABEL contact="docker@caseysparkz.com"
LABEL maintainer="docker@caseysparkz.com"
LABEL parent_image="770088062852.dkr.ecr.us-west-2.amazonaws.com/debian12:0.0.1"

ENV PYTHON_UNBUFFERED 0

USER root

RUN true                                                                    \
    && apt-get update                                                       \
    && apt-get install --assume-yes --no-install-recommends                 \
        "python3-boto3=1.26.27+dfsg-1"                                      \
        "python3-boto=2.49.0-4.1"                                           \
        "python3-dateutil=2.8.2-2"                                          \
        "python3-jinja2=3.1.2-1+deb12u3"                                    \
        "python3-requests=2.28.1+dfsg-1"                                    \
        "python3=3.11.2-1+b1"                                               \
    && update-alternatives --install                                        \
        /usr/bin/python                                                     \
        python                                                              \
        /usr/bin/python3                                                    \
        0                                                                   \
    && rm -rf                                                               \
        /var/cache/apt/*                                                    \
        /var/lib/apt/lists


USER app

ENTRYPOINT ["/usr/bin/python3"]
