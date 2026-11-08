#!/usr/bin/env python3
# SPDX-License-Identifier: LGPL-2.1+
# ~~~
#   lldpad-test.py integration test
#   Description: Test for lldpad: Link Layer Discovery Protocol (LLDP) agent daemon
#
#   Author: Susant Sahani <susant@redhat.com>
#   Copyright (c) 2018 Red Hat, Inc.
# ~~~

import errno
import os
import sys
import time
import unittest
import subprocess
import signal
import shutil
import psutil
from pyroute2 import IPRoute

LLDPAD_TCP_DUMP_FILE='/tmp/lldpad-tcp-dump.pcap'

def setUpModule():
    """Initialize the environment, and perform sanity checks on it."""

    if shutil.which('lldpad') is None:
        raise OSError(errno.ENOENT, 'lldpad not found')

class lldpadUtilities():
    """Provide a set of utility functions start stop lldpad ."""

    def Startlldpad(self):
        """Start lldpad"""
        subprocess.check_output(['systemctl', 'start', 'lldpad'])
        self.addCleanup(subprocess.call, ['systemctl', 'stop', 'lldpad'])

    def ConfigureLldpad(self):
        subprocess.check_output(['lldptool', '-L', '-i', 'lldpad-peer', 'adminStatus=rxtx'])
        subprocess.check_output(['lldptool', '-L', '-i', 'lldpad', 'adminStatus=rx'])

    def CaptureLLDPPackets(self):
        """Start tcpdump to capture packets"""
        subprocess.check_output(['systemctl','start', 'tcpdumpd.service'])
        self.addCleanup(subprocess.call, ['rm', LLDPAD_TCP_DUMP_FILE])

    def StopCaptureLLDPPackets(self):
        subprocess.check_output(['systemctl', 'stop', 'tcpdumpd.service'])

    def SetupVethInterface(self):
        """Setup veth interface"""

        ip = IPRoute()

        ip.link('add', ifname='lldpad', peer='lldpad-peer', kind='veth')
        idx_ladvd= ip.link_lookup(ifname='lldpad')[0]
        idx_ladvd_peer = ip.link_lookup(ifname='lldpad-peer')[0]

        ip.link('set', index=idx_ladvd, address='02:01:02:03:04:08')
        ip.link('set', index=idx_ladvd_peer, address='02:01:02:03:04:09')
        ip.link('set', index=idx_ladvd, state='up')
        ip.link('set', index=idx_ladvd_peer, state='up')

        ip.close()
        time.sleep(4)

    def TearDownVethInterface(self):

        ip = IPRoute()
        ip.link('del', index=ip.link_lookup(ifname='lldpad')[0])
        ip.close()

    def FindLLDPFieldsinTCPDump(self, **kwargs):
        """Look attributes in lldpad logs."""

        contents = subprocess.check_output(['tcpdump', '-v', '-r', LLDPAD_TCP_DUMP_FILE]).rstrip().decode('utf-8')
        if kwargs is not None:
                for key in kwargs:
                    self.assertRegex(contents, kwargs[key])

class lldpadTestsViaNetworkd(unittest.TestCase, lldpadUtilities):

    def setUp(self):
        """ Setup """
        self.SetupVethInterface()
        self.Startlldpad()
        self.ConfigureLldpad()

    def tearDown(self):
        self.TearDownVethInterface()

    def test_systemd_networkd_lldp(self):
        """ Receive LLDP packets via networkd """

        subprocess.check_output(['systemctl', 'restart', 'systemd-networkd'])
        time.sleep(30)

        output=subprocess.check_output(['networkctl','lldp', 'lldpad']).rstrip().decode('utf-8')
        self.assertRegex(output, "lldpad")
        self.assertRegex(output, "02:01:02:03:04:09")

        """ Verify LLDP Packets received by lldpad transmitted from networkd """
        output = subprocess.check_output(['lldptool', 'get-tlv', '-n', '-i', 'lldpad-peer']).rstrip().decode('utf-8')
        self.assertRegex(output, "Ifname: lldpad")
        self.assertRegex(output, "120")

class lldpadTests(unittest.TestCase, lldpadUtilities):

    def setUp(self):
        """ Setup """
        self.SetupVethInterface()
        self.Startlldpad()
        self.ConfigureLldpad()

        """ TTL is 120 """
        self.CaptureLLDPPackets()
        time.sleep(10)
        self.StopCaptureLLDPPackets()
        time.sleep(1)

    def tearDown(self):
        self.TearDownVethInterface()

    def test_lldpad_configured(self):
        """ Verify lldpad-peer interface configured """

        # Chassis ID TLV
	# MAC: 02:01:02:03:04:09
        # Port ID TLV
	# MAC: 02:01:02:03:04:09
        # Time to Live TLV
	# 120
        # End of LLDPDU TLV

        time.sleep(2)

        output = subprocess.check_output(['lldptool', '-t', '-i', 'lldpad-peer']).rstrip().decode('utf-8')
        self.assertRegex(output, "Chassis ID TLV")
        self.assertRegex(output, "MAC: 02:01:02:03:04:09")
        self.assertRegex(output, "Port ID TLV")
        self.assertRegex(output, "MAC: 02:01:02:03:04:09")
        self.assertRegex(output, "Time to Live TLV")
        self.assertRegex(output, "120")
        self.assertRegex(output, "End of LLDPDU TLV")

    def test_lldptool_get_tlv(self):
        """ Verify lldpad got the packet transmitted from lldpad-peer interface """

        # Chassis ID TLV
	# MAC: 02:01:02:03:04:09
        # Port ID TLV
	# MAC: 02:01:02:03:04:09
        # Time to Live TLV
	# 120
        # End of LLDPDU TLV

        time.sleep(2)

        output = subprocess.check_output(['lldptool', 'get-tlv', '-n', '-i', 'lldpad']).rstrip().decode('utf-8')
        self.assertRegex(output, "Chassis ID TLV")
        self.assertRegex(output, "MAC: 02:01:02:03:04:09")
        self.assertRegex(output, "Port ID TLV")
        self.assertRegex(output, "MAC: 02:01:02:03:04:09")
        self.assertRegex(output, "Time to Live TLV")
        self.assertRegex(output, "120")
        self.assertRegex(output, "End of LLDPDU TLV")

    def test_management_address(self):
        """ Test Get/Set a Management Address"""

        subprocess.check_output(['lldptool', '-T', '-i', 'lldpad', '-V', 'mngAddr', 'ipv4=192.168.10.10'])
        subprocess.check_output(['lldptool', '-T', '-i', 'lldpad', '-V', 'mngAddr', 'ipv6=::1'])

        output=subprocess.check_output(['lldptool', '-t', '-i', 'lldpad', '-V', 'mngAddr', '-c', 'ipv4']).rstrip().decode('utf-8')
        self.assertRegex(output, "ipv4=192.168.10.10");

        output=subprocess.check_output(['lldptool', '-t', '-i', 'lldpad', '-V', 'mngAddr', '-c', 'ipv6']).rstrip().decode('utf-8')
        self.assertRegex(output, "ipv6=::1");

    def test_lldpad_trasmitted_packets(self):
        """ verify at the other end of veth(lldpad) lldpad has trasmitted packets. Extract from tcpdump"""

        # 16:46:06.007162 LLDP, length 46
	# Chassis ID TLV (1), length 7
	# Subtype MAC address (4): 02:01:02:03:04:09 (oui Unknown)
	# Port ID TLV (2), length 7
	# Subtype MAC address (3): 02:01:02:03:04:09 (oui Unknown)
	# Time to Live TLV (3), length 2: TTL 120s
	# End TLV (0), length 0

        self.FindLLDPFieldsinTCPDump(test2='02:01:02:03:04:09',
                                     test3='TTL.*120s')


if __name__ == '__main__':
    unittest.main(testRunner=unittest.TextTestRunner(stream=sys.stdout,
                                                     verbosity=2))
