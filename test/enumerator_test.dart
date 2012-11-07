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

import 'package:dart_enumerators/enumerators.dart';
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

void main() {
  test('empty.parts is empty',
       () => expect(empty().parts.isEmpty(), isTrue));
  test('singleton is a singleton',
       () => checkEquals(singleton('foo'), [['foo']]));
  test('pay shifts an enumeration', testPay);
  test('+ behaves as expected', testPlus);
}
