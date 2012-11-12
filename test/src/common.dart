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

library common;

import 'package:dart_enumerators/enumerators.dart';
import 'package:unittest/unittest.dart';

Enumeration listToEnum(List<List> list) {
  return new Enumeration(() => _listToLazyList(list.map(_listToFinite)));
}

Finite _listToFinite(List list) {
  var result = new Finite.empty();
  for (final e in list) {
    result = result + new Finite.singleton(e);
  }
  return result;
}

LazyList _listToLazyList(List list) {
  LazyList aux(int i) =>
    (i >= list.length)
        ? new LazyList.empty()
        : new LazyList.cons(list[i], () => aux(i+1));
  return aux(0);
}


void checkPrefixEquals(Enumeration enum, List<List> prefix) {
  final enumPrefix = enum.parts
                         .take(prefix.length)
                         .toList()
                         .map(_finiteToList);
  expect(enumPrefix, equals(prefix));
}

void checkEquals(Enumeration enum, List<List> list) {
  final enumPrefix = enum.parts
                         .toList()
                         .map(_finiteToList);
  expect(enumPrefix, equals(list));
}

List _finiteToList(Finite finite) => finite.toLazyList().toList();
