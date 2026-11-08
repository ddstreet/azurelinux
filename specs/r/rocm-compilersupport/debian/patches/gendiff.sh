#!/bin/sh

set -x

cp -r ~/rpmbuild/SOURCES/rocm-compilersupport-6.2.4.tar.gz .
tar xf rocm-compilersupport-6.2.4.tar.gz
mv llvm-project-rocm-6.2.4 llvm-project-rocm-6.2.4_orig

rpmbuild -bp ../../rocm-compilersupport.spec
mv ~/rpmbuild/BUILD/rocm-compilersupport-18-build/llvm-project-rocm-6.2.4 .

diff -ru llvm-project-rocm-6.2.4_orig llvm-project-rocm-6.2.4 > patch.diff

sed i -e 's@/usr/lib64@/usr/lib@' patch.diff

rm -rf llvm-project-rocm-6.2.4_orig
rm -rf llvm-project-rocm-6.2.4
rm rocm-compilersupport-6.2.4.tar.gz




