# @see: https://github.com/weechat/weechat-container
# build: make build
# docker build -t lsipii/weechat-base:3.6 -f ./weechat-container/debian/Containerfile --build-arg VERSION=3.6 ./weechat-container
# docker build -t lsipii/weechat:3.6 .
# run: make run
# docker run -ti -v ${HOME}/.weechat:/home/user/.weechat lsipii/weechat:3.6
ARG WEECHAT_VERSION="3.6"
FROM lsipii/weechat-base:${WEECHAT_VERSION}

USER root

#
# Runtime environment variables
#
ARG WEECHAT_CONFIG_PATH
ENV WEECHAT_CONFIG_PATH=${WEECHAT_CONFIG_PATH}

#
# Build dependencies
#
RUN apt-get update && apt-get install -y python3 python3-pip libolm-dev git curl
RUN update-alternatives --install /usr/bin/python python /usr/bin/python3 2

# cleanup
RUN apt-get clean; \
    rm -rf /var/lib/apt/lists/*

#
# runtime dependencies
#
COPY ./Makefile .
RUN make install-runtime

# Switch back to user role as in parent image
USER user

CMD ["make", "run-entrypoint"]