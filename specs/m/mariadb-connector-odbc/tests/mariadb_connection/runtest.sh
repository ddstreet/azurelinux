#!/bin/bash
# vim: dict+=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   runtest.sh of mariadb_connection
#   Description: Tries to connect to MariaDB via unixODBC package
#   Author: Michal Schorm <mschorm@redhat.com>
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   Copyright (c) 2018 Red Hat, Inc.
#
#   This program is free software: you can redistribute it and/or
#   modify it under the terms of the GNU General Public License as
#   published by the Free Software Foundation, either version 2 of
#   the License, or (at your option) any later version.
#
#   This program is distributed in the hope that it will be
#   useful, but WITHOUT ANY WARRANTY; without even the implied
#   warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
#   PURPOSE.  See the GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program. If not, see http://www.gnu.org/licenses/.
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# TEST DESCRIPTION:
#   Prepare MariaDB database for connection
#   Configure the MariaDB connector for ODBC
#   Test that the we are able to log-in via ODBC as a specific DB user using password
#
# DOCUMENTATION:
#   https://mariadb.com/kb/en/about-mariadb-connector-odbc/
#
# VERSION DIFERENCES:
#   * Since MariaDB 10.4, new type of default authentication (unix_socket) is in place
#     That means we have to create a DB user and a password in order to be able to acces the DB
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Include Beaker environment
. /usr/share/beakerlib/beakerlib.sh || exit 1

PACKAGE="mariadb-connector-odbc"

rlJournalStart
    rlPhaseStartSetup
        # Check if all needed packages are installed
        rlAssertRpm $PACKAGE
        rlAssertRpm unixODBC
        rlAssertRpm mariadb
        rlAssertRpm mariadb-server
        # Check the default unixODBC configuration
        # There should already be an entry for MariaDB connector for ODBC
        rlAssertExists "/etc/odbcinst.ini"
        rlAssertGrep "MariaDB" "/etc/odbcinst.ini"
        # Start MariaDB
        rlRun "systemctl start mariadb" 0
    rlPhaseEnd


    rlPhaseStartTest
        # Insert the second part of the ODBC configuration
        # with SOCKET defined
        rlRun "cp -f socket_odbc.ini /etc/odbc.ini"
        rlAssertExists "/etc/odbc.ini"
        rlAssertGrep "MariaDB" "/etc/odbc.ini"
        rlAssertGrep "SOCKET" "/etc/odbc.ini"

        rlRun " echo \"SHOW DATABASES\" | isql -v mariadb-connector-odbc " 0
	rlRun " echo \"SELECT USER(),CURRENT_USER()\" | isql -v mariadb-connector-odbc " 0
    rlPhaseEnd


    rlPhaseStartTest
        # Insert the second part of the ODBC configuration
        # without SOCKET defined
        rlRun "cp -f odbc.ini /etc/"
        rlAssertExists "/etc/odbc.ini"
        rlAssertGrep "MariaDB" "/etc/odbc.ini"
        rlAssertNotGrep "SOCKET" "/etc/odbc.ini"

        rlRun " echo \"SHOW DATABASES\" | isql -v mariadb-connector-odbc " 1
	rlRun " echo \"SELECT USER(),CURRENT_USER()\" | isql -v mariadb-connector-odbc " 1
    rlPhaseEnd


    rlPhaseStartTest
        # Create a new DB user and password for this test
        rlRun "echo \"CREATE USER 'odbc_connector_user'@'localhost' IDENTIFIED BY 'odbc_connector_password'\" | mysql " 0
        # Save the credentials to a variable; we will append it to every isql command
        rlRun "CREDENTIALS=\"odbc_connector_user odbc_connector_password\"" 0

        rlRun " echo \"SHOW DATABASES\" | isql -v mariadb-connector-odbc $CREDENTIALS " 0
	rlRun " echo \"SELECT USER(),CURRENT_USER()\" | isql -v mariadb-connector-odbc $CREDENTIALS " 0
    rlPhaseEnd

rlJournalPrintText
rlJournalEnd
rlGetTestState
exit $ECODE
