#!/bin/bash

#########################################################################################
# DESC: docker entry point
#########################################################################################
# Copyright (c) Chris Ruettimann <chris@bitbull.ch>

# This software is licensed to you under the GNU General Public License.
# There is NO WARRANTY for this software, express or
# implied, including the implied warranties of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. You should have received a copy of GPLv2
# along with this software; if not, see
# http://www.gnu.org/licenses/gpl.txt

# HOW IT WORKS:
# 1) parse ENV
# 2) create benchmark vars
# 3) loop the benchmark
#
# INSTALL:
#   https://github.com/joe-speedboat/docker.nextcloud_benchmark

set -o pipefail

set +e

# Script trace mode
if [ "${DEBUG_MODE,,}" == "true" ]; then
    set -o xtrace
fi

NC_BENCH_CONF=/tmp/nc_benchmark.conf
NC_BENCH_SCRIPT=/usr/bin/nc_benchmark.sh

# picks a random value from $1 range, eg: IN=1-100 OUT=55
# if no range is given, it returns the IN value
range_handler() {
   IN="$1"
   echo "$1" | grep -q -- '.-.' 
   if [ $? -eq 0 ]
   then
      shuf -i $IN -n1
   elif [ "$IN" != "x" ]
   then
      echo $IN
   fi
}

echo "
####################### INPUT VARS ########################
NC_CLOUD=$NC_CLOUD
NC_USR=$NC_USR
NC_PW=$NC_PW
BENCH_COUNT=$BENCH_COUNT
TEST_BLOCK_SIZE_MB=$TEST_BLOCK_SIZE_MB
TEST_FILES_COUNT=$TEST_FILES_COUNT
SPEED_LIMIT_UP_MB=$SPEED_LIMIT_UP_MB
SPEED_LIMIT_DOWN_MB=$SPEED_LIMIT_DOWN_MB
###########################################################
"


TEST_BLOCK_SIZE_MB=$(range_handler $TEST_BLOCK_SIZE_MB)
TEST_FILES_COUNT=$(range_handler $TEST_FILES_COUNT)
SPEED_LIMIT_UP_MB=$(range_handler $SPEED_LIMIT_UP_MB)
SPEED_LIMIT_DOWN_MB=$(range_handler $SPEED_LIMIT_DOWN_MB)



for BENCH_RUN in $(seq 1 $BENCH_COUNT )
do

echo "
CLOUD=\"${CLOUD:=ony_idiots_try_to_do_this}\"
USR=\"${USR:=admin}\"
PW=\"${PW:=passowrd_is_mandatory___idiot}\"
BENCH_COUNT=\"${BENCH_COUNT:=9999999}\"
TEST_BLOCK_SIZE_MB=\"${TEST_BLOCK_SIZE_MB:=$(shuf -i 10-2048 -n1)}\"
TEST_FILES_COUNT=\"${TEST_FILES_COUNT_MB:=$(shuf -i 10-200 -n1)}\"
SPEED_LIMIT_UP=\"${SPEED_LIMIT_UP_MB:=$(shuf -i 1-20 -n1)M}\"
SPEED_LIMIT_DOWN=\"${SPEED_LIMIT_DOWN_MB:=$(shuf -i 1-20 -n1)M}\"
LOCAL_DIR=/tmp
BENCH_DIR=\"$(curl ifconfig.me | tr '.' '_')_$HOSTNAME\"
" > $NC_BENCH_CONF

   echo "####################### STARTING: $BENCH_RUN ######################"
   cat $NC_BENCH_CONF
   echo "#########################################################"
   echo "INFO: Testing connectivity"
   curl -k -s -L https://$CLOUD 2>&1 >/dev/null 
   if [ $? -eq 0 ]
   then
     $NC_BENCH_SCRIPT $NC_BENCH_CONF || true
   else
     echo "ERROR: I CANT REACH THIS NEXTCLOUD, SO I WAIT A MOMENT"
   fi   
   SLEEP=$(shuf -i 5-15 -n1)
   echo SLEEPING $SLEEP seconds
   sleep $SLEEP
done

