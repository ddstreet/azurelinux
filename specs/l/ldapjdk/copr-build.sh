#!/bin/sh

REPO=$1

if [ "$REPO" == "" ]; then
    REPO="pki-10.6"
fi

fedpkg copr-build --nowait $REPO
