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

import 'package:dart_enumerators/combinators.dart' as c;
import 'package:unittest/unittest.dart';

void checkNats() {
  for (int n = 0; n < 500; n++) {
    expect(c.nats.parts[n].card, equals(1),
           reason: "part $n hasn't the expected cardinal");
    expect(c.nats.parts[n][0], equals(n),
           "c.nats.parts[$n][0] isn't ${n}");
  }
}

void checkInts() {
  expect(c.ints.parts[0].card, equals(1));
  expect(c.ints.parts[0][0], equals(0));
  for (int n = 1; n < 500; n++) {
    expect(c.ints.parts[n].card, equals(2),
           reason: "part $n hasn't the expected cardinal");
    expect(c.ints.parts[n][0], equals(n),
           "c.ints.parts[$n][0] isn't ${n - 1}");
    expect(c.ints.parts[n][1], equals(-n),
           "c.ints.parts[$n][1] isn't ${1 - n}");
  }
}

main() {
  test('nats is { 0: [], 1: [0], 2: [1], ... }', checkNats);
  test('ints is { 0: [0], 1: [1, -1], 2: [2, -2], ... }', checkInts);
}
