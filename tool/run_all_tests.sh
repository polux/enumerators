#!/bin/bash

ROOT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"

results=`dart_analyzer --work=/tmp $ROOT_DIR/lib/*.dart 2>&1`

if [ -n "$results" ]; then
    echo "$results"
    exit 1
else
    echo "done"
fi

dart --enable-checked-mode $ROOT_DIR/example/simple.dart \
&& dart --enable-checked-mode $ROOT_DIR/example/advanced.dart \
&& dart --enable-checked-mode $ROOT_DIR/example/lambda.dart \
&& dart --enable-checked-mode $ROOT_DIR/test/finite_test.dart \
&& dart --enable-checked-mode $ROOT_DIR/test/enumerator_test.dart \
&& dart --enable-checked-mode $ROOT_DIR/test/combinators_test.dart
