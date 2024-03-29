#!/bin/bash

_usage() {
  echo "$0 <--nose|--tube|--payload> <--ip=target ip addr> [-i|--interactive][-u|--user][-p|--pass password][-h]"
}

_readdotenv() {
  if [ -f .env ]
  then
    export $(cat .env | sed 's/#.*//g' | xargs)
  fi
}

_provision() {

  if [ -z "$TARGET_TYPE" ] ; then
    echo "Target type is not defined yet it is mandatory!"
    _usage
    exit 1
  fi

  if [ -z "$TARGET_IP" ] ; then
    echo "Target IP is not defined yet it is mandatory!"
    _usage
    exit 1
  fi

  if [ ${TARGET_TYPE} = "tube" ] ; then
    ANSIBLE_USER=$PAYLOAD_USER
    ANSIBLE_PASSWORD=$PAYLOAD_PASSWD
  fi

  if [ ${TARGET_TYPE} = "payload" ] ; then
    ANSIBLE_USER=$TUBE_USER
    ANSIBLE_PASSWORD=$TUBE_PASSWD
  fi

  if [ ${TARGET_TYPE} = "nose" ] ; then
    ANSIBLE_USER=$NOSE_USER
    ANSIBLE_PASSWORD=$NOSE_PASSWD
  fi

  ANSIBLE_USER=${ANSIBLE_USER:-${CUSTOM_USER:-ubuntu}}
  ANSIBLE_PASSWORD=${ANSIBLE_PASSWORD:-${CUSTOM_PASSWORD:-ubuntu}}

  CUSTOM_USER=${CUSTOM_USER:-${ANSIBLE_USER:-ubuntu}}
  CUSTOM_PASSWORD=${CUSTOM_PASSWORD:-${ANSIBLE_PASSWORD:-ubuntu}}

  ANSIBLE_EXTRA_OPTIONS="${ANSIBLE_EXTRA_OPTIONS} in_vehicle_wifi_pass=$IN_VEHICLE_WIFI_PASS "
  ANSIBLE_EXTRA_OPTIONS="${ANSIBLE_EXTRA_OPTIONS} github_token=$GITHUB_TOKEN "
  ANSIBLE_EXTRA_OPTIONS="${ANSIBLE_EXTRA_OPTIONS} target_type=$TARGET_TYPE "
  ANSIBLE_EXTRA_OPTIONS="${ANSIBLE_EXTRA_OPTIONS} ansible_user=$CUSTOM_USER "
  ANSIBLE_EXTRA_OPTIONS="${ANSIBLE_EXTRA_OPTIONS} ansible_password=$CUSTOM_PASSWORD "
  ANSIBLE_EXTRA_OPTIONS="${ANSIBLE_EXTRA_OPTIONS} ansible_become_pass=$CUSTOM_PASSWORD "
  ANSIBLE_EXTRA_OPTIONS="${ANSIBLE_EXTRA_OPTIONS} ansible_ssh_extra_args='-o StrictHostKeyChecking=no' -o 'UserKnownHostsFile /dev/null'"

  ansible-playbook -i ${TARGET_IP}, main.yml --extra-vars "$ANSIBLE_EXTRA_OPTIONS"
}

_getopts() {
  for i in "$@"
  do
    case $i in
      --ip=*)
        TARGET_IP="${i#*=}"
        shift ;;
      --tube)
        TARGET_TYPE="tube"
        shift ;;
      --payload)
        TARGET_TYPE="payload"
        shift ;;
      --nose)
        TARGET_TYPE="nose"
        shift ;;
      -u=*|--user=*)
        CUSTOM_USER="${i#*=}"
        shift ;;
      -p=*|--pass=*)
        CUSTOM_PASSWORD="${i#*=}"
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