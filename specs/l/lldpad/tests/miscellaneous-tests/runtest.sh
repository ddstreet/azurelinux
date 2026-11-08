#!/bin/bash
# SPDX-License-Identifier: LGPL-2.1+
# ~~~
#   runtest.sh of lldpad
#   Description: Tests for The lldpad package provides the Linux user space
#   daemon and configuration tool for Intel's Link Layer Discovery Protocol (LLDP)
#   agent with Enhanced Ethernet support.

#   Author: Susant Sahani <susant@redhat.com>
#   Copyright (c) 2018 Red Hat, Inc.
# ~~~~

# Include Beaker environment
. /usr/share/beakerlib/beakerlib.sh || exit 1

PACKAGE="lldpad"

SERVICE_UNITDIR="/run/systemd/system"
NETWORK_UNITDIR="/run/systemd/network"

rlJournalStart
    rlPhaseStartSetup
        rlAssertRpm $PACKAGE
        rlRun "systemctl stop firewalld" 0,5
        rlRun "setenforce 0" 0,1

        rlRun "mkdir -p $NETWORK_UNITDIR"
        rlRun "cp lldp.network $NETWORK_UNITDIR/"

        rlRun "cp tcpdumpd.service $SERVICE_UNITDIR"
        rlRun "systemctl daemon-reload"
        rlRun "cp lldpad-test.py /usr/bin/"
    rlPhaseEnd

    rlPhaseStartTest
        rlLog "lldpad tests"
        rlRun "/usr/bin/python3 /usr/bin/lldpad-test.py"
    rlPhaseEnd

    rlPhaseStartCleanup
        rlRun "rm /usr/bin/lldpad-test.py $NETWORK_UNITDIR/lldp.network $SERVICE_UNITDIR/tcpdumpd.service"
        rlRun "systemctl daemon-reload"
        rlRun "setenforce 1" 0,1
        rlLog "lldpad tests done"
    rlPhaseEnd
rlJournalPrintText
rlJournalEnd

rlGetTestState
