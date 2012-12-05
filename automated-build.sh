#! /bin/bash

# This script is intended to be downloaded and run on
# a new Ubuntu 12.04 image as UID 1000, with commands
# such as:
#
#   wget https://raw.github.com/okfn/ckanbuild/master/automated-build.sh
#   bash automated-build.sh
#
# It will clone the ckanbuild repository under
# /home/okfn/build/ if it does not already exist and
# build a ckan package with from the latest version
# of the source code

TARGET_DIR=/home/okfn/build/
USER_GROUP=1000:1000

set -e # stop execution on errors

sudo apt-get -y install git python-virtualenv rubygems \
                        python-dev libpq-dev
sudo gem install --conservative fpm

if ! [ -d "$TARGET_DIR" ]; then
    sudo mkdir -p "$TARGET_DIR"
    sudo chown -R "$USER_GROUP" "$TARGET_DIR"
fi

# XXX somewhat terrible: cloning repo just to get the latest __version__
# and then later pip installing from *another* clone
cd "$TARGET_DIR"
[ -d ckan ] || git clone https://github.com/okfn/ckan.git
cd ckan
VERSION=`python -c'import ckan; print ckan.__version__'`

cd "$TARGET_DIR"
[ -d ckanbuild ] || git clone https://github.com/okfn/ckanbuild.git
cd ckanbuild
[ -f ckan-bootstrap.py ] || python mk-ckan-bootstrap.py
if ! [ -d builds/"$VERSION" ]; then
    python ckan-bootstrap.py ./builds/"$VERSION"/usr/lib/ckan
    ./package.sh ./builds/"$VERSION"
fi




