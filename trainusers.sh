#!/bin/bash

#####
# Set default command line options
#####
USERNAME_PREFIX=sagc
USERLIST_FILE='/root/userlist.txt'
USERNAME_SUFFIX_START=1
USERNAME_SUFFIX_END=10
USERNAME_SUFFIX_ZERO_PADDING_LENGTH=3
PASSWORD_LENGTH=12


usage="USAGE: $(basename $0) [-h] -a <action> [-f <userlist_file>] [-u <user_prefix>] [-s <start>] [-e <end>] [-z <zero_padding>] [-l <length_of_password>] [[-p <pwgen_arg>] ...]

User/password creation/management.
  where:
    -h Show this help text
    -a Action to perform (create|chpass|lock|unlock|pwon|pwoff|delete)
      create: create users with passwords
      chpass: change the user's passwords
      lock:   lock user's passwords
      unlock: unlock user's passwords
      pwon:   allow password authentication in SSH
      pwoff:  disable password authentication in SSH
      delete: delete user accounts
    -f File of colon-separated usernames and passwords (default: ${USERLIST_FILE})
    -u Username prefix (default: ${USERNAME_PREFIX})
    -s Username suffix start number (default: ${USERNAME_SUFFIX_START})
    -e Username suffix end number (default: ${USERNAME_SUFFIX_END})
    -z Zero-pad username suffix number to this length (default:${USERNAME_SUFFIX_ZERO_PADDING_LENGTH})
    -l Password length (default: ${PASSWORD_LENGTH})
    -p Arguments to pass to pwgen (default: --ambiguous --symbols --numerals --capitalize)"

PWGEN_ARGS=()

#####
# Parse command line options
#####
while getopts ":ha:f:u:s:e:z:l:p:" opt; do
  case $opt in
    h) >&2 echo "${usage}"
       exit
       ;;
    a) ACTION=${OPTARG}
       ;;
    f) USERLIST_FILE=${OPTARG}
       ;;
    u) USERNAME_PREFIX=${OPTARG}
       ;;
    s) USERNAME_SUFFIX_START=${OPTARG}
       ;;
    e) USERNAME_SUFFIX_END=${OPTARG}
       ;;
    z) USERNAME_SUFFIX_ZERO_PADDING_LENGTH=${OPTARG}
       ;;
    l) PASSWORD_LENGTH=${OPTARG}
       ;;
    p) PWGEN_ARGS+=(${OPTARG})
       ;;
    ?) >&2 printf "Illegal option: '-%s'\n" "${OPTARG}"
       >&2 echo "{$usage}"
       exit 1
       ;;
    :) >&2 echo "Option -${OPTARG} requires an argument."
      >&2 echo "${usage}"
      exit 1
      ;;
    *) >&2 echo "${usage}"
       exit
       ;;
  esac
done

# Define colours for STDERR text
RED='\033[0;31m'
ORANGE='\033[0;33m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

if [ -z "${ACTION}" ]; then
  >&2 echo -e "${RED}ERROR: -a must be specified${NC}"
  >&2 echo "${usage}"
  exit
fi

# Set default pwgen arguments if non were supplied by the user
if [[ ${#PWGEN_ARGS[@]} == 0 ]]; then
  PWGEN_ARGS=("--ambiguous" "--symbols" "--numerals" "--capitalize")
fi

# ensure pwgen exists
if [ ! -x /usr/bin/pwgen ]
then
  apt update && apt install pwgen
fi

case $ACTION in
  create)
    if [[ -e ${USERLIST_FILE} ]]; then
      while IFS=':' read username password; do
        useradd --create-home --home-dir /home/${username} --shell /bin/bash ${username}
	echo "${username}:${password}" | chpasswd
      done < ${USERLIST_FILE}
    else
      touch ${USERLIST_FILE}
      chmod 600 ${USERLIST_FILE}

      for i in $(seq --format "%0${USERNAME_SUFFIX_ZERO_PADDING_LENGTH}g" ${USERNAME_SUFFIX_START} ${USERNAME_SUFFIX_END})
      do
        PASS=$(pwgen ${PASSWORD_LENGTH} ${PWGEN_ARGS[@]} 1)
        useradd --create-home --home-dir /home/${USERNAME_PREFIX}${i} --shell /bin/bash ${USERNAME_PREFIX}${i}
        echo "${USERNAME_PREFIX}${i}:${PASS}" | tee -a ${USERLIST_FILE} | chpasswd
      done
    fi
  ;;
  chpass)
    touch ${USERLIST_FILE}
    chmod 600 ${USERLIST_FILE}

    for i in $(seq --format "%0${USERNAME_SUFFIX_ZERO_PADDING_LENGTH}g" ${USERNAME_SUFFIX_START} ${USERNAME_SUFFIX_END})
    do
      PASS=$(pwgen ${PASSWORD_LENGTH} ${PWGEN_ARGS[@]} 1)
      sed -i "/${USERNAME_PREFIX}${i}/d" ${USERLIST_FILE}
      echo "${USERNAME_PREFIX}${i}:${PASS}" | tee -a ${USERLIST_FILE} | chpasswd
    done
  ;;
  lock)
    for i in $(seq --format "%0${USERNAME_SUFFIX_ZERO_PADDING_LENGTH}g" ${USERNAME_SUFFIX_START} ${USERNAME_SUFFIX_END})
    do
      passwd --lock ${USERNAME_PREFIX}${i}
    done
  ;;
  unlock)
    for i in $(seq --format "%0${USERNAME_SUFFIX_ZERO_PADDING_LENGTH}g" ${USERNAME_SUFFIX_START} ${USERNAME_SUFFIX_END})
    do
      passwd --unlock ${USERNAME_PREFIX}${i}
    done
  ;;
  pwon)
    sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
    systemctl restart sshd
    ;;
  pwoff)
    sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
    systemctl restart sshd
    ;;
  delete)
    for i in $(seq --format "%0${USERNAME_SUFFIX_ZERO_PADDING_LENGTH}g" ${USERNAME_SUFFIX_START} ${USERNAME_SUFFIX_END})
    do
      userdel --remove ${USERNAME_PREFIX}${i}
      sed -i "/${USERNAME_PREFIX}${i}/d" ${USERLIST_FILE}
      echo "${USERNAME_PREFIX}${i}: deleted"
    done
  ;;
esac
