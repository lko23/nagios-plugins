#!/bin/bash
# 

#   Copyright (C) 2015 Eduardo Dimas (https://github.com/eddimas/nagios-plugins)
#   Copyright (C) Markus Walther (voltshock@gmx.de)
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

#
# Plugin to check processes running
# The script needs an pair of ssh keys working to run on the server side to check it
# 
# Command-Line for check_procs.sh
# command_line    $USER1$/check_procs.sh -l $USERNAME -H $HOSTNAME$ -p $ARG1$ -w $ARG2$ -c $ARG3$"
# 
# Command-Line for service (example)
# check_procs.sh!sshRemoteUser!192.168.1.2!sshd!1!10
#
##########################################################

PROGNAME=`basename $0`
VERSION="Version 1.1,"
AUTHOR="2015, Eduardo Dimas (https://github.com/eddimas/nagios-plugins)"

help() {
cat << END
Usage :
        $PROGNAME -l [STRING] -H [STRING] -p [VALUE] -w [VALUE] -c [VALUE]

        OPTION          DESCRIPTION
        ----------------------------------
        -h              Help
        -l [STRING]     Remote user
        -H [STRING]     Host name
        -p [VALUE]      Name of process to check, multiple processes 'proc1\|proc2'
        -w [VALUE]      Warning Threshold (higher)
        -c [VALUE]      Critical Threshold (lower)

        ----------------------------------
Note : [VALUE] must be an integer.
END
}

if [ $# -ne 10 ]
then
        help;
        exit 3;
fi

while getopts "l:H:p:w:c:" OPT
do
        case $OPT in
        l) USERNAME="$OPTARG" ;;
        H) HOSTNAME="$OPTARG" ;;
        p) proc="$OPTARG" ;;
        w) hi="$OPTARG" ;;
        c) lo="$OPTARG" ;;
        *) help ;;
        esac
done

lines=`ssh -q -l $USERNAME $HOSTNAME -C "ps -ef | grep '$proc' | grep -v grep | grep -v check_proc | wc -l"`
perf_data="$proc=$lines;$hi;$lo"

if [ -n "$lines" ]; then
        if [ "$lines" -eq "0" ]; then
                #echo "Warning: Not enough processes ($lines/$min) | $perf_data"
                echo "Critical: No process found matching $proc ($lines/$lo/$hi) | $perf_data"
                #exit 1
                exit 2
        elif  [ "$lines" -le "$lo" ]; then
                echo "Critical: Not enough processes found matching $proc ($lines/$lo/$hi) | $perf_data"
                exit 2
        elif  [ "$lines" -ge "$hi" ]; then
                echo "Warning: Too much process found matching $proc ($lines/$lo/$hi) | $perf_data"
                exit 1
        elif  [ "$lines" -gt "$lo" -a "$lines" -lt "$hi" ]; then
                echo "OK: $lines process(es) found matching $proc ($lines/$lo/$hi) | $perf_data"
                exit 0
        fi
 else
        echo "Unknown error"
        exit 3
fi
