#!/bin/bash

ROOTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
OUTDIR=$ROOTDIR/continuous
TMPDIR=`mktemp -d`

cd $TMPDIR
git clone https://github.com/polux/enumerators
cd enumerators
pub install
rm -rf $OUTDIR
dartdoc -v --link-api --pkg=packages/ --out $OUTDIR lib/enumerators.dart lib/combinators.dart
#dartdoc -v --generate-app-cache --link-api --pkg=packages/ --out $OUTDIR lib/enumerators.dart lib/combinators.dart
rm -rf $TMPDIR
