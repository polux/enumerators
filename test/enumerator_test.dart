// Copyright (c) 2012, Google Inc. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

// Author: Paul Brauner (polux@google.com)

import 'package:enumerators/enumerators.dart';
import 'package:unittest/unittest.dart';
import 'src/common.dart';

void testPay() {
  checkEquals(empty().pay(), [[]]);

  final e        = [    [1,2], [], [3]];
  final expected = [[], [1,2], [], [3]];
  checkEquals(listToEnum(e).pay(), expected);
}

void testPlus() {
  final e1       = [[1,2], [3,4    ]     ];
  final e2       = [[],    [    5,6], [7]];
  final expected = [[1,2], [3,4,5,6], [7]];
  checkEquals(listToEnum(e1) + listToEnum(e2), expected);
}

void testMult() {
  p(x, y) => new Pair(x, y);
  final e1 = [[1], [2,3], [4]];
  final e2 = [[5,6], [7], [8]];

  checkEquals(empty() * listToEnum(e1), []);
  checkEquals(listToEnum(e1) * empty(), []);

  final expected = [[p(1, 5), p(1, 6)],
                    [p(1, 7), p(2, 5), p(2, 6), p(3, 5), p(3, 6)],
                    [p(1, 8), p(2, 7), p(3, 7), p(4, 5), p(4, 6)],
                    [p(2, 8), p(3, 8), p(4, 7)],
                    [p(4, 8)],
                    []];
  checkEquals(listToEnum(e1) * listToEnum(e2), expected);
}

void testMap() {
  final e = [[1,2], [3,4,5], [], [6,7]];
  final expected = [[2,3], [4,5,6], [], [7,8]];
  checkEquals(listToEnum(e).map((n) => n + 1), expected);
}

void testApply() {
  final f = [[(n) => n, (n) => n * 2], [(n) => n * 3]];
  final e = [[1,3], [5,7]];
  final expected = [[1, 3, 1 * 2, 3 * 2],
                    [5, 7, 5 * 2, 7 * 2, 1 * 3, 3 * 3],
                    [5 * 3, 7 * 3],
                    []];
  checkEquals(listToEnum(f).apply(listToEnum(e)), expected);
}

void testFix() {
  final en = fix((e) => singleton('foo') + e.pay());
  final expected = [];
  for (int i = 0; i < 100; i++) {
    expected.add(['foo']);
  }
  checkPrefixEquals(en, expected);
}

void testKnot() {
  final en = fix((e) => singleton('foo') + e.pay());
  expect(en.parts.tail, same(en.parts));
}

void main() {
  test('empty.parts is empty',
       () => expect(empty().parts.isEmpty, isTrue));
  test('singleton is a singleton',
       () => checkEquals(singleton('foo'), [['foo']]));
  test('pay shifts an enumeration', testPay);
  test('+ behaves as expected', testPlus);
  test('* behaves as expected', testMult);
  test('map behaves as expected', testMap);
  test('apply behaves as expected', testApply);
  test('fix e.(foo + e.pay) is foo foo foo ...', testFix);
  test('fix ties the knot', testKnot);
}
