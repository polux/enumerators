#!/bin/bash

ROOT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"

dartanalyzer $ROOT_DIR/lib/*.dart \
dartanalyzer $ROOT_DIR/test/*.dart \
&& dart --enable-checked-mode $ROOT_DIR/example/simple.dart \
&& dart --enable-checked-mode $ROOT_DIR/example/advanced.dart \
&& dart --enable-checked-mode $ROOT_DIR/example/lambda.dart \
&& dart --enable-checked-mode $ROOT_DIR/test/finite_test.dart \
&& dart --enable-checked-mode $ROOT_DIR/test/enumerator_test.dart \
&& dart --enable-checked-mode $ROOT_DIR/test/combinators_test.dart
