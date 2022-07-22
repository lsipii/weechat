SHELL=/bin/bash

# Settings
WEECHAT_CONFIG_PATH = ${HOME}/.weechat
WEECHAT_VERSION = "3.6"

###
# Usage routines
### 
init: initialize-submodules
install: initialize-submodules
	docker build -t lsipii/weechat-base:${WEECHAT_VERSION} -f ./weechat-container/debian/Containerfile --build-arg VERSION=${WEECHAT_VERSION} ./weechat-container \
		&& docker build -t lsipii/weechat:${WEECHAT_VERSION} --build-arg WEECHAT_VERSION=${WEECHAT_VERSION} .
run: ensure-config-folder
	docker run -ti --rm -v ${WEECHAT_CONFIG_PATH}:/home/user/.weechat lsipii/weechat:${WEECHAT_VERSION}

###
# Container sub-install routines
###
WEECHAT_RUNTIME_DEPS_SRC_PATH := ${HOME}/src/weechat-dependencies

# exec container entrypoint
run-entrypoint:
	make --silent install-links && weechat -d /home/user/.weechat

# util prereqs
ensure-config-folder:
	mkdir -p ${WEECHAT_CONFIG_PATH}
ensure-build-folders: ensure-config-folder
	mkdir -p ${WEECHAT_RUNTIME_DEPS_SRC_PATH}
initialize-submodules:
	git submodule init && git submodule update

# Apps
install-runtime: install-weeslack install-matrix
install-links: link-weeslack link-matrix

install-weeslack: ensure-build-folders
	python -m pip install websocket-client
	cd ${WEECHAT_RUNTIME_DEPS_SRC_PATH} && curl -O https://raw.githubusercontent.com/wee-slack/wee-slack/master/wee_slack.py
link-weeslack: ensure-build-folders
	mkdir -p ${WEECHAT_CONFIG_PATH}/python/autoload
	[ -L ${WEECHAT_CONFIG_PATH}/python/wee_slack.py ] || ln -sf ${WEECHAT_RUNTIME_DEPS_SRC_PATH}/wee_slack.py ${WEECHAT_CONFIG_PATH}/python/wee_slack.py
	[ -L ${WEECHAT_CONFIG_PATH}/python/autoload/wee_slack.py ] || ln -sf ../wee_slack.py ${WEECHAT_CONFIG_PATH}/python/autoload

install-matrix: ensure-build-folders
	if [ -d "${WEECHAT_RUNTIME_DEPS_SRC_PATH}/weechat-matrix" ]; then rm -Rf ${WEECHAT_RUNTIME_DEPS_SRC_PATH}/weechat-matrix; fi
	cd ${WEECHAT_RUNTIME_DEPS_SRC_PATH} && git clone https://github.com/poljar/weechat-matrix.git && cd weechat-matrix && python3 -m pip install -r requirements.txt
link-matrix: ensure-build-folders
	mkdir -p ${WEECHAT_CONFIG_PATH}/python/autoload
	[ -L ${WEECHAT_CONFIG_PATH}/python/matrix.py ] || ln -sf ${WEECHAT_RUNTIME_DEPS_SRC_PATH}/weechat-matrix/main.py ${WEECHAT_CONFIG_PATH}/python/matrix.py
	[ -L ${WEECHAT_CONFIG_PATH}/python/matrix ] || ln -sf ${WEECHAT_RUNTIME_DEPS_SRC_PATH}/weechat-matrix/matrix ${WEECHAT_CONFIG_PATH}/python/matrix
	[ -L ${WEECHAT_CONFIG_PATH}/python/autoload/matrix.py ] || ln -sf ../matrix.py ${WEECHAT_CONFIG_PATH}/python/autoload

