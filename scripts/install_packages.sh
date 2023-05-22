#!/bin/bash
# note this file is intended to be used during transitional releases to manually
# install packages

export DEBIAN_FRONTEND=noninteractive

for pkg_path in /root/builddeps/*; do
    cd $pkg_path
    build-deb
    dpkg -i ../${pkg}*.deb || apt-get --fix-broken install
done

rm -rf /root/builddeps
