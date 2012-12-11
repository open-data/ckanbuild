#! /bin/bash

# This script is intended to be downloaded and run on
# a new Ubuntu 12.04 image as UID 1000, with commands
# such as:
#
#   wget https://raw.github.com/okfn/ckanbuild/master/automated-target.sh
#   bash automated-target.sh <type>
#
# where <type> is "webserver", "dbserver" or "both".
# The default is "both"
#
# It will clone the ckanbuild repository under
# /home/okfn/build/ if it does not already exist and
# install using the scripts from that repository

TARGET_DIR=/home/okfn/build/
USER_GROUP=1000:1000

set -e # stop execution on errors

if [ -z "$1" -o "$1" == "both" ]; then
    SERVER_TYPE=both
elif [ "$1" == "webserver" -o "$1" == "dbserver" ]; then
    SERVER_TYPE="$1"
else
    echo 'type must be one of "webserver", "dbserver" or "both"'
    exit 1
fi

sudo apt-get -y install git 

if ! [ -d "$TARGET_DIR" ]; then
    sudo mkdir -p "$TARGET_DIR"
    sudo chown -R "$USER_GROUP" "$TARGET_DIR"
fi

cd "$TARGET_DIR"
[ -d ckanbuild ] || git clone https://github.com/okfn/ckanbuild.git
cd ckanbuild
[ "$SERVER_TYPE" == "webserver" ] || ./bin/dbserver.sh init
[ "$SERVER_TYPE" == "dbserver" ] || ./bin/webserver.sh init


