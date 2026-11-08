To generate a debian from fedora.

1. Prepare the big patch
On fedora do

> rpmbuild -bp rocm-compilersupport.spec

This will produce something like

~/rpmbuild/BUILD/rocm-compilersupport-19-build/llvm-project-rocm-6.4.0

Go to the dir and untar the original source 

> cd ~/rpmbuild/BUILD/rocm-compilersupport-19-build/
> mkdir a
> cd a
> tar xf ../../../SOURCES/rocm-compilersupport-6.4.0.tar.gz

Make a copy for later debian

> tar cf llvm-project-rocm_6.4.0.orig.tar llvm-project-rocm-6.4.0
> gzip llvm-project-rocm_6.4.0.orig.tar

Make/move original source

> cd ..
> cp -r a/llvm-project-rocm-6.4.0 llvm-project-rocm-6.4.0.orig

Remove the unneeded directories 

> cd llvm-project-rocm-6.4.0.orig
> rm -rf {bolt,flang,libc,libclc,lldb,llvm-libgcc,mlir,polly,third-party}

Remove fedora prep cruft

> cd llvm-project-rocm-6.4.0
> rm *.sed prep.sh

Make the patch

> diff -ruN llvm-project-rocm-6.4.0.orig llvm-project-rocm-6.4.0 > patch.diff

Change the fedora path to a debian path

> sed -i -e 's@usr/lib64/rocm/@usr/lib/rocm/@' patch.diff

Copy this patch to debian/patches

2. Prepare the build area

On ubuntu/debian run

> setuptmp.sh

3. try out a build

> cd ~/b/rocm-compilersupport/llvm-project-6.4.0
> debuild -us -uc

When there is an error, check if the cmake config options match the specfile.

