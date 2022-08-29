SHELL=/bin/bash

# Settings
WEECHAT_CONFIG_PATH = ${HOME}/.weechat
WEECHAT_VERSION = "3.6"

###
# Usage routines
### 
install: build
build: initialize-submodules
	cp ./weechat-container/alpine/Containerfile ./weechat-alpine.dockerfile
	sed -i 's/FROM alpine:3.15 as base/FROM alpine:3.16 as base/' ./weechat-alpine.dockerfile
	sed -i 's/php7/php8/g' ./weechat-alpine.dockerfile
	sed -i 's/-u 1001 -D/-u 1000 -D/' ./weechat-alpine.dockerfile
	docker build -t lsipii/weechat-base:${WEECHAT_VERSION} -f ./weechat-alpine.dockerfile --build-arg VERSION=${WEECHAT_VERSION} ./weechat-container \
		&& docker build -t lsipii/weechat:${WEECHAT_VERSION} --build-arg WEECHAT_VERSION=${WEECHAT_VERSION} .
	rm ./weechat-alpine.dockerfile
run: ensure-config-folder
	docker run -e TZ=$$(make --silent get-timezone-string) --name weechat -ti --rm -v ${WEECHAT_CONFIG_PATH}:/home/user/.weechat:Z lsipii/weechat:${WEECHAT_VERSION}
start: ensure-config-folder
	[ -z "$$(docker ps -q -f name=weechat)" ] && docker run -d -e TZ=$$(make --silent get-timezone-string) --name weechat -ti --rm -v ${WEECHAT_CONFIG_PATH}:/home/user/.weechat:Z lsipii/weechat:${WEECHAT_VERSION} || exit 0
attach: start
	docker attach weechat --detach-keys="ctrl-d, "; exit 0
clean:
	docker rm weechat || exit 0
	docker rmi lsipii/weechat-base:${WEECHAT_VERSION} || exit 0
	docker rmi lsipii/weechat:${WEECHAT_VERSION} || exit 0

###
# Container sub-install routines
###
WEECHAT_RUNTIME_DEPS_SRC_PATH := ${HOME}/src/weechat-dependencies

# exec container entrypoint
run-entrypoint: run-ensure-links
	weechat --dir /home/user/.weechat

# util prereqs
ensure-config-folder:
	mkdir -p ${WEECHAT_CONFIG_PATH}
ensure-build-folders: ensure-config-folder
	mkdir -p ${WEECHAT_RUNTIME_DEPS_SRC_PATH}
initialize-submodules:
	git submodule init && git submodule update
get-timezone-string:
	@cat /etc/timezone
run-ensure-links:
	make --silent install-links
###
# Runtime plugins
###
install-runtime: install-weeslack install-matrix
# On runtime, ensure links to pre-installed plugins 
install-links: link-weeslack link-matrix

install-weeslack: ensure-build-folders
	python -m pip install websocket-client
	cd ${WEECHAT_RUNTIME_DEPS_SRC_PATH} && curl -O https://raw.githubusercontent.com/wee-slack/wee-slack/xoxc-tokens/wee_slack.py
link-weeslack: ensure-build-folders
	mkdir -p ${WEECHAT_CONFIG_PATH}/python/autoload
	[ -L ${WEECHAT_CONFIG_PATH}/python/wee_slack.py ] || ln -sf ${WEECHAT_RUNTIME_DEPS_SRC_PATH}/wee_slack.py ${WEECHAT_CONFIG_PATH}/python/wee_slack.py
	[ -L ${WEECHAT_CONFIG_PATH}/python/autoload/wee_slack.py ] || ln -sf ../wee_slack.py ${WEECHAT_CONFIG_PATH}/python/autoload

install-matrix: ensure-build-folders
	if [ -d "${WEECHAT_RUNTIME_DEPS_SRC_PATH}/weechat-matrix" ]; then rm -Rf ${WEECHAT_RUNTIME_DEPS_SRC_PATH}/weechat-matrix; fi
	cd ${WEECHAT_RUNTIME_DEPS_SRC_PATH} && git clone https://github.com/poljar/weechat-matrix.git && cd weechat-matrix && python -m pip install -r requirements.txt
link-matrix: ensure-build-folders
	mkdir -p ${WEECHAT_CONFIG_PATH}/python/autoload
	[ -L ${WEECHAT_CONFIG_PATH}/python/matrix.py ] || ln -sf ${WEECHAT_RUNTIME_DEPS_SRC_PATH}/weechat-matrix/main.py ${WEECHAT_CONFIG_PATH}/python/matrix.py
	[ -L ${WEECHAT_CONFIG_PATH}/python/matrix ] || ln -sf ${WEECHAT_RUNTIME_DEPS_SRC_PATH}/weechat-matrix/matrix ${WEECHAT_CONFIG_PATH}/python/matrix
	[ -L ${WEECHAT_CONFIG_PATH}/python/autoload/matrix.py ] || ln -sf ../matrix.py ${WEECHAT_CONFIG_PATH}/python/autoload

