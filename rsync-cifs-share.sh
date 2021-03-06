#!/bin/bash

#-------------------------------------------------------------------------
# Copyright (c) Microsoft.  All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#--------------------------------------------------------------------------

# set bash script options
set -o nounset

# set variables for paths
sourcePath='/media/source'
destPath='/media/backup'
destHost='backupserver'
destUser='rsyncuser'
tmpPath='/var/tmp'
pidFile='/var/tmp/rsync-cifs.pid'

# test if rsync is still running from prior job
if [[ -f $pidFile ]]; then
    pid=$(cat $pidFile)
    rsynctest=$(ps -fp $pid | grep rsync)
    if [[ $rsynctest ]]; then
        echo "WARNING: Prior rsync cron job still running ... exiting" | logger -t rsync.cifs
        exit
    fi
fi

# write PID file for current process
echo $$ >$pidFile

# test access to CIFS source share
ls $sourcePath
if [[ $? != 0 ]]; then
    echo "ERROR: source path $sourcePath not accessible" | logger -t rsync.cifs
    exit
fi

# replicate files to destination rsync server VM
rsync --rsh="ssh" --rsync-path="rsync" --verbose --progress --temp-dir=$tmpPath -rlpgoDvh --delete $sourcePath $destUser@$destHost:$destPath
if [[ $? != 0 ]]; then
    echo "ERROR: rsync failed for $sourcePath to $destHost" | logger -t rsync.cifs
else
    echo "SUCCESS: rsync completed for $sourcePath to $destHost" | logger -t rsync.cifs
fi

# remove PID file for current process
rm $pidFile
