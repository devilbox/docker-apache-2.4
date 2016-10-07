#!/bin/sh

##
## Settings
##
NAME="apache-2.4"


USR="cytopia"
IMG="${USR}/${NAME}"
REG="https://index.docker.io/v1/"



##
## Functions
##
get_docker_id() {
	_did="$( docker images | grep "${IMG}" | grep "latest" | awk '{print $3}' )"
	echo "${_did}"
}
is_logged_in() {
	_user="$( docker info | grep "${USR}" | awk '{print $2}' )"
	_dhub="$( docker info | grep 'Registry' | awk '{print $2}' )"

	if [ "${_user}" = "${USR}" ]; then
		if [ "${_dhub}" = "${REG}" ]; then
			return 0
		fi
	fi
	return 1
}
run() {
	_cmd="${1}"

	_red="\033[0;31m"
	_green="\033[0;32m"
	_reset="\033[0m"
	_user="$(whoami)"

	printf "${_red}%s \$ ${_green}${_cmd}${_reset}\n" "${_user}"
	sh -c "LANG=C LC_ALL=C ${_cmd}"
}



##
## Entrypoint
##
#run "docker build --no-cache -t ${IMG} ."
run "docker tag $( get_docker_id ) ${IMG}:latest"
if ! is_logged_in; then
	run "docker login"
fi
run "docker push ${IMG}"

