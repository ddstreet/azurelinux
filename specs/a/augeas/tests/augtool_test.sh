#!/bin/bash

set -eux

augtool -L > augtool_test.out 2> augtool_test.err <<EOF
# do not try to parse /etc/profile.d/*, and /etc/profile files,
# as the Shellvars lens cannot handle their advanced syntax
rm /augeas/load/Shellvars/*[. =~ regexp("/etc/profile.*")]

# exclude /etc/mke2fs.conf, as it has various issues:
# https://bugzilla.redhat.com/1807010
rm /augeas/load/Mke2fs/

# exclude 21-cloudinit.conf, which seems to have issues
ins excl before /augeas/load/Rsyslog/*[label() = 'excl'][position() = 1]
set /augeas/load/Rsyslog/*[label() = 'excl'][position() = 1] /etc/rsyslog.d/21-cloudinit.conf

# load, and print the errors
load
print /augeas//error
EOF

# remove output related to the removal of the /etc/profile.* 'incl'
# transforms
sed -i '/^rm /d' augtool_test.out

echo "BEGIN output ========"
cat augtool_test.out
echo "END output ========"
echo "BEGIN error ========"
cat augtool_test.err
echo "END error ========"

test ! -s augtool_test.out
test ! -s augtool_test.err
