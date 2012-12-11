#! /bin/bash

# This script is intended to be downloaded and run on
# a new Ubuntu 12.04 image as UID 1000, with commands
# such as:
#
#   wget https://raw.github.com/okfn/ckanbuild/master/automated-build.sh
#   bash automated-build.sh <version>
#
# where <version> is the CKAN version to build
#
# It will clone the ckanbuild repository under
# /home/okfn/build/ if it does not already exist and
# build a ckan package with from the version specified

TARGET_DIR=/home/okfn/build/
USER_GROUP=1000:1000
CKAN_REPO=git+https://github.com/okfn/ckan.git

set -e # stop execution on errors

if [ -z "$1" ]; then
    echo 'You must specify version e.g. "2.0a"'
    exit 1
fi
VERSION="$1"

sudo apt-get -y install git python-virtualenv rubygems \
                        python-dev libpq-dev
sudo gem install --conservative fpm

if ! [ -d "$TARGET_DIR" ]; then
    sudo mkdir -p "$TARGET_DIR"
    sudo chown -R "$USER_GROUP" "$TARGET_DIR"
fi

cd "$TARGET_DIR"
[ -d ckanbuild ] || git clone https://github.com/okfn/ckanbuild.git
cd ckanbuild
[ -f ckan-bootstrap.py ] || python mk-ckan-bootstrap.py

python ckan-bootstrap.py ./builds/"$VERSION"/usr/lib/ckan \
    --ckan-location=${CKAN_REPO}@release-v${VERSION}#egg=ckan
./package.sh ./builds/"$VERSION"

echo
echo Package built under: ./builds/"$VERSION"/



