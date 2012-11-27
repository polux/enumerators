#!/bin/bash

ROOT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"

dart --enable-checked-mode $ROOT_DIR/example/simple.dart \
&& dart --enable-checked-mode $ROOT_DIR/example/advanced.dart \
&& dart --enable-checked-mode $ROOT_DIR/test/finite_test.dart \
&& dart --enable-checked-mode $ROOT_DIR/test/enumerator_test.dart \
&& dart --enable-checked-mode $ROOT_DIR/test/combinators_test.dart
