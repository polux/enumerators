#!/bin/bash

ROOT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"

dartanalyzer --no-hints $ROOT_DIR/lib/*.dart \
&& dartanalyzer --no-hints $ROOT_DIR/test/*.dart \
&& dartanalyzer --no-hints $ROOT_DIR/example/*.dart \
&& dart --enable-checked-mode $ROOT_DIR/example/simple.dart \
&& dart --enable-checked-mode $ROOT_DIR/example/advanced.dart \
&& dart --enable-checked-mode $ROOT_DIR/example/lambda.dart \
&& dart --enable-checked-mode $ROOT_DIR/test/finite_test.dart \
&& dart --enable-checked-mode $ROOT_DIR/test/enumerator_test.dart \
&& dart --enable-checked-mode $ROOT_DIR/test/combinators_test.dart
