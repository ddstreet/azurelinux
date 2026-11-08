#!/bin/sh

# call from debian/
set -x

ver=6.4.0

p=rocm-compilersupport
b=$HOME/b/$p
if [ -d $b ]; then
    rm -rf $b
fi

mkdir -p $HOME/b
rsync -ar ../../$p $HOME/b

cd $HOME/b/$p
    
tar xf rocm-compilersupport-${ver}.tar.gz
tar cf llvm-project-rocm_${ver}.orig.tar llvm-project-rocm-${ver}
gzip --fast llvm-project-rocm_${ver}.orig.tar

cd llvm-project-rocm-${ver}
patch -p1 < ../debian/patches/patch.diff

mv ../debian .

# now cd llvm-project and do
# debuild -us -uc
