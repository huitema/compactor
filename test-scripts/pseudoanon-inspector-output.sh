#!/bin/sh
# 
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, you can obtain one at https://mozilla.org/MPL/2.0/.
#
# Check the inspector pseudo-anonymises report contents.

COMP=./compactor
INSP=./inspector

DEFAULTS="--defaultsfile $srcdir/test-scripts/test.defaults"

DATAFILE=./knot-live.raw.pcap
INFOFILE=$srcdir/test-scripts/knot-live.anon.info

command -v diff > /dev/null 2>&1 || { echo "No diff, skipping test." >&2; exit 77; }
command -v grep > /dev/null 2>&1 || { echo "No grep, skipping test." >&2; exit 77; }

#set -x

tmpdir=`mktemp -d -t "pseudoanon-inspector-output.XXXXXX"`

cleanup()
{
    rm -rf $tmpdir
    exit $1
}

trap "cleanup 1" HUP INT TERM

# Run the converter.
$COMP -c /dev/null -S 192.168.1.1 -S ::1 -o $tmpdir/out.cbor $DATAFILE
if [ $? -ne 0 ]; then
    cleanup 1
fi

# -I. Expect only .info to be produced.
$INSP $DEFAULTS --info-only -P test -p -o $tmpdir/out.pcap $tmpdir/out.cbor
if [ $? -ne 0 ]; then
    cleanup 1
fi

grep -v "Collector ID" $tmpdir/out.pcap.info > $tmpdir/out.pcap.anon.info
if [ $? -ne 0 ]; then
    cleanup 1
fi

test -f $tmpdir/out.pcap.anon.info -a ! \( -f $tmpdir/out.pcap \) &&
    diff -q $tmpdir/out.pcap.anon.info $INFOFILE
cleanup $?
