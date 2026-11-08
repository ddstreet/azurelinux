#!/bin/sh

apt install build-essential devscripts debhelper locales

echo "deb-src http://deb.debian.org/debian unstable main" > /etc/apt/sources.list

apt-get update
apt modernize-sources

dpkg-reconfigure locales
