// Copyright (c) 2012, Google Inc. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

// Author: Paul Brauner (polux@google.com)

library common;

import 'package:dart_enumerators/enumerators.dart';
import 'package:unittest/unittest.dart';

Enumeration listToEnum(List<List> list) {
  return new Enumeration(
      new Thunk(
          () => _listToLazyList(list.map(_listToFinite))));
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
