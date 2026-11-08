#!/bin/sh

SOURCE=$1
TARGET=`basename $1`

cp $SOURCE $TARGET
sha512sum --tag $TARGET > sources
