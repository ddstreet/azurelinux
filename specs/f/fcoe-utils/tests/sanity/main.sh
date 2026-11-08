#!/bin/bash
# Copyright (c) 2016 Red Hat, Inc. 
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#   Author: Xiaonan He <xhe@redhat.com>
ls
#set -x
source tc.sh || exit 200
yum update -y fcoe-utils
if [ $? -ne 0 ];then
	exit 1
fi
	
tlog "running $0"
trun "yum info fcoe-utils"
trun "uname -a"
tok "[[ -f /usr/sbin/fipvlan ]]"
tend
