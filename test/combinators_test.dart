// Copyright (c) 2012, Google Inc. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

// Author: Paul Brauner (polux@google.com)

import 'package:enumerators/combinators.dart' as c;
import 'package:rational/rational.dart';
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
  final chars = const ["a","b","c","d","e","f","g","h","i","j","k","l","m",
                       "n","o","p","q","r","s","t","u","v","w","x","y","z"];
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
  final enumeration = c.listsOf(c.bools);
  final t = true, f = false;
  final expected = [
    [[]],
    [[t], [f]],
    [[t, t], [t, f], [f, t], [f, f]],
    [[t, t, t], [t, t, f], [t, f, t], [t, f, f],
     [f, t, t], [f, t, f], [f, f, t], [f, f, f]]];
  checkPrefixEquals(enumeration, expected);
}

void testListsOfNats() {
  final enumeration = c.listsOf(c.nats);
  final expected = [
    [[]],
    [[0]],
    [[0, 0], [1]],
    [[0, 0, 0], [0, 1], [1, 0], [2]],
    [[0, 0, 0, 0], [0, 0, 1], [0, 1, 0], [0, 2],
     [1, 0, 0], [1, 1], [2, 0], [3]]];
  checkPrefixEquals(enumeration, expected);
}

void testPositiveRationalsArePositive() {
  c.positiveRationals
   .take(1000)
   .forEach((r) => expect(r >= new Rational(0), isTrue));
}

void testRationalsAreAllDifferent() {
  final rats = new Set<Rational>();
  c.positiveRationals
   .take(1000)
   .forEach(rats.add);
  expect(rats.length, equals(1000));
}

main() {
  test('bools is { 0: [true, false] }', testBools);
  test('nats is { 0: [], 1: [0], 2: [1], ... }', testNats);
  test('ints is { 0: [0], 1: [1, -1], 2: [2, -2], ... }', testInts);
  test('strings is { 0: [""], 1: ["a".."z"], 2: ["aa", "ab", ...], ... }',
       testStrings);
  test('listsOf(bools) is { 0: [[]], 1: [[true], [false]], .. }',
       testListsOfBools);
  test('listsOf(nats) is { 0: [[0]], 1: [[0, 0], [1]], .. }',
       testListsOfNats);
  test('positive rationals are positive', testPositiveRationalsArePositive);
  test('rationals are all different', testRationalsAreAllDifferent);
}
