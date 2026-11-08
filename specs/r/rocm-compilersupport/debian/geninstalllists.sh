#!/bin/sh

set -x

ver=18-25.rocm6.2.4

P="rocm-comgr-devel rocm-comgr \
hipcc \
rocm-device-libs \
rocm-lld-devel rocm-lld rocm-lld-libs \
rocm-clang-runtime-devel rocm-clang-devel rocm-clang rocm-clang-libs \
rocm-llvm-static rocm-llvm-devel rocm-llvm rocm-llvm-libs"

for p in $P; do
    rpm -qlp ~/rpmbuild/RPMS/x86_64/$p-${ver}.*.rpm | grep -v build-id | grep -v 'share/licenses' | sed 's@/usr/lib64@/usr/lib@' > ${p}.install
done


