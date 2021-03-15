#!/bin/bash

_usage() {
  echo "$0 <--ip target ip addr> [-i|--interactive][-p|--pass password][-h][--patch]"
}

_readdotenv() {
  if [ -f .env ]
  then
    export $(cat .env | sed 's/#.*//g' | xargs)
  fi
}

_provision() {
  ANSIBLE_PASSWORD=${ANSIBLE_PASSWORD:-ubuntu}
  ANSIBLE_PLAYBOOK=${ANSIBLE_PLAYBOOK:-main.yml}

  if [ -z "$TARGET_IP" ] ; then
    echo "Target IP is not defined yet it is mandatory!"
    _usage
    exit 1
  fi

  ANSIBLE_EXTRA_OPTIONS="${ANSIBLE_EXTRA_OPTIONS} github_token=$GITHUB_TOKEN "
  ANSIBLE_EXTRA_OPTIONS="${ANSIBLE_EXTRA_OPTIONS} ansible_user=ubuntu "
  ANSIBLE_EXTRA_OPTIONS="${ANSIBLE_EXTRA_OPTIONS} ansible_ssh_extra_args='-o StrictHostKeyChecking=no' -o 'UserKnownHostsFile /dev/null'"
  ANSIBLE_EXTRA_OPTIONS="${ANSIBLE_EXTRA_OPTIONS} ansible_password=$ANSIBLE_PASSWORD "
  ANSIBLE_EXTRA_OPTIONS="${ANSIBLE_EXTRA_OPTIONS} ansible_become_pass=$ANSIBLE_PASSWORD "

  ansible-playbook -i ${TARGET_IP}, ${ANSIBLE_PLAYBOOK} --extra-vars "$ANSIBLE_EXTRA_OPTIONS"
}

_getopts() {
  for i in "$@"
  do
    case $i in
      --ip=*)
        TARGET_IP="${i#*=}"
        shift ;;
      -b=*|--play=*)
        ANSIBLE_PLAYBOOK="${i#*=}"
        shift ;;
      -p|--pass=*)
        ANSIBLE_PASSWORD="${i#*=}"
        shift ;;
      -i|--interactive)
        INTERACTIVE=1
        shift ;;
      -h|--help)
        HELP=1
        shift ;;
      *)
        _usage
        exit 1 ;;
    esac
  done
}

_interactive() {
  read -p "Target machine IP address: " TARGET_IP
  ROLES=()
  for role in $(ls | grep 'yml\|yaml') ; do
    ROLES+=(`echo $role | awk -F. '{print $1}'`);
  done
  read -p "Role <`for i in ${ROLES[@]} ; do printf $i ; ! [ $i == ${ROLES[-1]} ] && printf '|' ; done`>: " ROLE

  read -p "Is this a test build: " TEST
  read -p "Is this a development build: " DEV_BUILD
}

_getopts $@

if [ "$INTERACTIVE" != 1 ] ; then
  _readdotenv
  _provision
else
  _interactive
fi