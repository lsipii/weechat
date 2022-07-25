# @see: https://github.com/weechat/weechat-container
# build: make build
# docker build -t lsipii/weechat-base:3.6 -f ./weechat-container/alpine/Containerfile --build-arg VERSION=3.6 ./weechat-container
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

ARG RUNTIME_DEPS="\
    make \
    python3 \
    python3-dev \
    py3-pip \
    olm \
    zstd \
    zstd-dev \
    bash"

# @see: https://github.com/wee-slack/wee-slack/issues/812
# @see: https://github.com/poljar/weechat-matrix/issues/319#issue-1101498236
ARG BUILD_DEPS="\
    olm-dev \
    git \
    curl \
    musl-dev \
    gcc \
    py3-wheel \
    py3-importlib-metadata \
    libffi-dev \
    clang \
    lld"
#
# Build dependencies
#
RUN apk add --no-cache ${BUILD_DEPS} ${RUNTIME_DEPS}

# Link python3 for brewity (sic)
RUN ln -sf python3 /usr/bin/python

# Ensure uptodate pip, missing libs
RUN python -m pip install --upgrade pip six

# Install rust for matrix crypto deps
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

#
# install runtime libs
#
USER user
COPY ./Makefile .
RUN make install-runtime

#
# Cleanup
#
USER root
RUN sh -s /home/user/.cargo/bin/rustup self uninstall -- -y
RUN apk del ${BUILD_DEPS}


# Switch back to user role as in parent image
USER user

CMD ["make", "run-entrypoint"]
