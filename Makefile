SHELL=/bin/bash

# Settings
WEECHAT_CONFIG_PATH = ${HOME}/.weechat
WEECHAT_VERSION = "3.6"

# util scripts
ensure-build-folders = mkdir -p ${WEECHAT_RUNTIME_DEPS_SRC_PATH} && mkdir -p ${WEECHAT_CONFIG_PATH}
initialize-submodules = git submodule init && git submodule update

###
# Usage routines
###
init:
	$(initialize-submodules)
install:
	$(initialize-submodules) \
		&& docker build -t lsipii/weechat-base:${WEECHAT_VERSION} -f ./weechat-container/debian/Containerfile --build-arg VERSION=${WEECHAT_VERSION} ./weechat-container \
		&& docker build -t lsipii/weechat:${WEECHAT_VERSION} --build-arg WEECHAT_VERSION=${WEECHAT_VERSION} .
run: 
	mkdir -p ${WEECHAT_CONFIG_PATH}
	docker run -ti --rm -v ${WEECHAT_CONFIG_PATH}:/home/user/.weechat lsipii/weechat:${WEECHAT_VERSION}

###
# Sub-install routines
###
WEECHAT_RUNTIME_DEPS_SRC_PATH := ${HOME}/src/weechat-dependencies

install-runtime: install-weeslack install-matrix
install-links: link-weeslack link-matrix

install-weeslack:
	$(ensure-build-folders)
	python -m pip install websocket-client
	cd ${WEECHAT_RUNTIME_DEPS_SRC_PATH} && curl -O https://raw.githubusercontent.com/wee-slack/wee-slack/master/wee_slack.py
link-weeslack:
	$(ensure-build-folders)
	mkdir -p ${WEECHAT_CONFIG_PATH}/python/autoload
	ln -sf ${WEECHAT_RUNTIME_DEPS_SRC_PATH}/wee_slack.py ${WEECHAT_CONFIG_PATH}/python/wee_slack.py || echo "link exists"
	ln -sf ../wee_slack.py ${WEECHAT_CONFIG_PATH}/python/autoload || echo "link exists"

install-matrix:
	$(ensure-build-folders)
	if [ -d "${WEECHAT_RUNTIME_DEPS_SRC_PATH}/weechat-matrix" ]; then rm -Rf ${WEECHAT_RUNTIME_DEPS_SRC_PATH}/weechat-matrix; fi
	cd ${WEECHAT_RUNTIME_DEPS_SRC_PATH} && git clone https://github.com/poljar/weechat-matrix.git && cd weechat-matrix && python3 -m pip install -r requirements.txt
link-matrix:
	$(ensure-build-folders)
	ln -sf ${WEECHAT_RUNTIME_DEPS_SRC_PATH}/weechat-matrix/main.py ${WEECHAT_CONFIG_PATH}/python/matrix.py
	ln -sf ${WEECHAT_RUNTIME_DEPS_SRC_PATH}/weechat-matrix/matrix ${WEECHAT_CONFIG_PATH}/python/matrix
	mkdir -p ${WEECHAT_CONFIG_PATH}/python/autoload
	ln -sf ../matrix.py ${WEECHAT_CONFIG_PATH}/python/autoload

