#!/bin/bash

##########################################################
#
# PLUGIN TO CHECK FREE DISK SPACE
# USING CHECK_BY_SSH
#
#   Copyright (C) 2015 Eduardo Dimas (https://github.com/eddimas/nagios-plugins)
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
# THE SCRIPT NEEDS A WORKING CHECK_BY_SSH CONNECTION AND NEEDS TO RUN ON THE CLIENT TO CHECK IT
#
##########################################################

PROGNAME=`basename $0`
VERSION="Version 1.1,"
AUTHOR="2015, Eduardo Dimas (https://github.com/eddimas/nagios-plugins)"

TEMP_FILE="/tmp/$PROGNAME.$RANDOM.log"
COMMAND1='free -tb'
COMMAND2='free -tm'

help() {
cat << END
Usage :
        $PROGNAME -l [STRING] -H [STRING] -w [VALUE] -c [VALUE]

        OPTION          DESCRIPTION
        ----------------------------------
        -h              Help
        -l [STRING]      Remote user
        -H [STRING]     Host name
        -w [VALUE]      Sets a warning level for memory usage. 
                          Default is: 80
        -c [VALUE]      Sets a critical level for memory usage.
                          Default is: 90

        ----------------------------------
Note : [VALUE] must be an integer.
END
}

if [ $# -ne 8 ]
then
        help;
        exit 3;
fi

while getopts "l:H:w:c:" OPT
do
        case $OPT in
        l) USERNAME="$OPTARG" ;;
        H) HOSTNAME="$OPTARG" ;;
        w) warn="$OPTARG" ;;
        c) crit="$OPTARG" ;;
        *) help ;;
        esac
done

SSH_COMMAND="`ssh -q -l $USERNAME $HOSTNAME -C $COMMAND2`"
echo "$SSH_COMMAND"  > $TEMP_FILE

swapTotal_m=`grep Total $TEMP_FILE  | sed -r 's/\ +/\ /g' | cut -d \  -f 2`
swapUsed_m=`grep Total $TEMP_FILE  | sed -r 's/\ +/\ /g' | cut -d \  -f 3`
memTotal_m=`grep Mem $TEMP_FILE  | sed -r 's/\ +/\ /g' | cut -d \  -f 2`
memUsed_m=`grep Mem $TEMP_FILE  | sed -r 's/\ +/\ /g' | cut -d \  -f 3`

if [ "$swapTotal_m" -gt 0 ]; then
 swapUsedPrc=$((($swapUsed_m*100)/$swapTotal_m))
else
 wapUsedPrc=0
fi

if [ "$memTotal_m" -gt 0 ]; then
 memUsedPrc=$((($memUsed_m*100)/$memTotal_m))
else
 memUsedPrc=0
fi

  swapUsedWarn=$((($swapTotal_m/100)*$warn))
  swapUsedCrit=$((($swapTotal_m/100)*$crit))

  memUsedWarn=$((($memTotal_m/100)*$warn))
  memUsedCrit=$((($memTotal_m/100)*$crit))

rm $TEMP_FILE

#Memory usage: 937.71MiB (93.55%) of 1002.40MiB (warning threshold is set to 900MiB), Application memory usage: 210.57MiB (22.11%) of 952.28MiB, Cache usage: 688.96MiB (68.73%) of 1002.40MiB (critical threshold is set to 500MiB), Swap usage: 0.00MiB (0.00%) of 894.99MiB | MemUsed=983260200.96B;943718400;1048576000;0;1051095040 AppMemUsed=220798648.32B;838860800;943718400;0;998540288 CacheUsed=722426920.96B;419430400;524288000;0;1051095040 SwapUsed=0B;734003200;838860800;0;938467328 
#${perf[@]};$WARN;$CRIT;0;;
data="Virtual Memory: $swapUsed_m MB ($swapUsedPrc%) of $swapTotal_m MB - Physical Memory: $memUsed_m MB ($memUsedPrc%) of $memTotal_m MB, Virtual Memory: $swapUsed_m MB ($swapUsedPrc%) of $swapTotal_m MB"
perf="'Virtual_Memory'=${swapUsed_m}MB;${swapUsedWarn};${swapUsedCrit};0;${swapTotal_m} 'Physical_Memory'=${memUsed_m}MB;;;0;${memTotal_m}"

if [ "$swapUsedPrc" -ge "$crit" ]; then
    echo "CRITICAL: $data | $perf"
    $(exit 2)
  elif [ "$swapUsedPrc" -ge "$warn" ]; then
    echo "WARNING: $data | $perf"
    $(exit 1)
  else
    echo "OK: $data | $perf"
    $(exit 0)
fi
