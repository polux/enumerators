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

library combinators;

import 'package:dart_enumerators/enumerators.dart';

/* public API */

final Enumeration<bool> bools = _mkBools();
final Enumeration<String> strings = _mkStrings();
final Enumeration<int> nats = _mkNats();
final Enumeration<int> ints = _mkInts();

Enumeration<List> listsOf(Enumeration enum) {
  final nils = singleton(_nil());
  consesOf(e) => singleton(_cons).apply(enum).apply(e);
  final llists = fix((e) => (nils + consesOf(e).pay()));
  return llists.map((ll) => ll.toList());
}

Enumeration<Set> setsOf(Enumeration enum) {
  // bijection from lists of nats to sets of values
  bij(list) {
    var res = new Set();
    int sum = -1;
    for (final x in list) {
      sum += 1 + x;
      res.add(enum[sum]);
    }
    return res;
  }
  return listsOf(nats).map(bij);
}

Enumeration<Map> mapsOf(Enumeration keys, Enumeration values) {
  // bijection from lists of (nat x value) to maps of (key x value)
  bij(assocs) {
    var res = new Map();
    int sum = -1;
    for (final assoc in assocs) {
      sum += 1 + assoc.fst;
      res[keys[sum]] = assoc.snd;
    }
    return res;
  }
  return listsOf(nats * values).map(bij);

}

/* implementation */

abstract class _LList {
  abstract bool isEmpty();

  List toList() {
    var res = [];
    var it = this;
    while (!it.isEmpty()) {
      _Cons cons = it;
      res.add(cons.x);
      it = cons.xs;
    }
    return res;
  }
}

class _Nil extends _LList {
  toString() => "nil";
  isEmpty() => true;
}

class _Cons extends _LList {
  final x, xs;
  _Cons(this.x, this.xs);
  toString() => "$x:$xs";
  isEmpty() => false;
}

_nil() => new _Nil();
_cons(x) => (xs) => new _Cons(x,xs);

_foldLeft(list, zero, plus) {
  var result = zero;
  for (final x in list) {
    result = plus(result, x);
  }
  return result;
}

Map _toMap(List<Pair> assocs) {
  var res = new Map();
  for (final assoc in assocs) {
    res[assoc.fst] = assoc.snd;
  }
  return res;
}

Enumeration<bool> _mkBools() {
  return singleton(true) + singleton(false);
}

Enumeration<int> _mkNats() {
  final zeros = singleton(0);
  succOf(e) => e.map((n) => n + 1);
  return fix((e) => zeros + succOf(e).pay());
}

Enumeration<int> _mkInts() {
  final natsPlusOne = nats.map((n) => n + 1);
  return singleton(0) + (natsPlusOne + natsPlusOne.map((n) => -n)).pay();
}

Enumeration<String> _mkStrings() {
  final cs = "abcdefghijklmnopqrstuvwxyz".splitChars();
  final chars = _foldLeft(cs.map(singleton), empty(), (e1, e2) => e1 + e2);
  final charsLists = listsOf(chars);
  return charsLists.map(Strings.concatAll);
}
