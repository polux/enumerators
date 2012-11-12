// Copyright 2012 Google Inc. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

// Author: Paul Brauner (polux@google.com)

import 'package:dart_enumerators/enumerators.dart' show Enumeration;
import 'package:dart_enumerators/combinators.dart' as c;
import 'package:unittest/unittest.dart';
import 'src/common.dart';

void testBools() {
  checkEquals(c.bools, [[true, false]]);
}

void testNats() {
  final expected = [];
  for (int n = 0; n < 500; n++) {
    expected.add([n]);
  }
  checkPrefixEquals(c.nats, expected);
}

void testInts() {
  final expected = [[0]];
  for (int n = 1; n < 500; n++) {
    expected.add([n, -n]);
  }
  checkPrefixEquals(c.ints, expected);
}

void testStrings() {
  final chars = "abcdefghijklmnopqrstuvwxyz".splitChars();
  final expected1 = chars;
  final expected2 = [];
  for (final c1 in chars) {
    for (final c2 in chars) {
      expected2.add("$c1$c2");
    }
  }
  final expected3 = [];
  for (final c1 in chars) {
    for (final c2 in chars) {
      for (final c3 in chars) {
        expected3.add("$c1$c2$c3");
      }
    }
  }
  final expected = [[''], expected1, expected2, expected3];
  checkPrefixEquals(c.strings, expected);
}

void testListsOfBools() {
  final enum = c.listsOf(c.bools);
  final t = true, f = false;
  final expected = [
    [[]],
    [[t], [f]],
    [[t, t], [t, f], [f, t], [f, f]],
    [[t, t, t], [t, t, f], [t, f, t], [t, f, f],
     [f, t, t], [f, t, f], [f, f, t], [f, f, f]]];
  checkPrefixEquals(enum, expected);
}

void testListsOfNats() {
  final enum = c.listsOf(c.nats);
  final expected = [
    [[]],
    [[0]],
    [[0, 0], [1]],
    [[0, 0, 0], [0, 1], [1, 0], [2]],
    [[0, 0, 0, 0], [0, 0, 1], [0, 1, 0], [0, 2],
     [1, 0, 0], [1, 1], [2, 0], [3]]];
  checkPrefixEquals(enum, expected);
}

main() {
  test('bools is { 0: [true, false] }', testBools);
  test('nats is { 0: [], 1: [0], 2: [1], ... }', testNats);
  test('ints is { 0: [0], 1: [1, -1], 2: [2, -2], ... }', testInts);
  /*
  test('strings is { 0: [""], 1: ["a".."z"], 2: ["aa", "ab", ...], ... }',
       testStrings);
  test('listsOf(bools) is { 0: [[]], 1: [[true], [false]], .. }',
       testListsOfBools);
  test('listsOf(nats) is { 0: [[0]], 1: [[0, 0], [1]], .. }',
       testListsOfNats);
       */
}
