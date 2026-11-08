#!/bin/bash

# Include Beaker environment
. /usr/share/beakerlib/beakerlib.sh || exit 1

rlJournalStart
    rlPhaseStartSetup
        rlAssertRpm python3
        rlRun "tmp=\$(mktemp -d)" 0 "Create tmp directory"
        rlRun "cp test_foma.py foma-input.txt $tmp"
        rlRun "pushd $tmp"
    rlPhaseEnd

    rlPhaseStartTest
        rlRun "python3 test_foma.py -v" \
            0 "Running test cases"
    rlPhaseEnd

    rlPhaseStartCleanup
        rlRun "popd"
        rlRun "rm -r $tmp" 0 "Remove tmp directory"
    rlPhaseEnd
rlJournalEnd
