// Copyright (c) 2012, Google Inc. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

// Author: Paul Brauner (polux@google.com)

library combinators;

import 'package:enumerators/enumerators.dart';
import 'package:rational/rational.dart';

/* public API */

final Enumeration<bool> bools = _mkBools();
final Enumeration<String> strings = _mkStrings();
final Enumeration<int> nats = _mkNats();
final Enumeration<int> ints = _mkInts();
final Enumeration<Rational> positiveRationals = _mkPositiveRationals();
final Enumeration<Rational> rationals = _mkRationals();

Enumeration<List> listsOf(Enumeration enumeration) {
  final nils = singleton(_nil());
  consesOf(e) => singleton(_cons).apply(enumeration).apply(e);
  final llists = fix((e) => (nils + consesOf(e).pay()));
  return llists.map((ll) => ll.toList());
}

Enumeration<Set> setsOf(Enumeration enumeration) {
  // bijection from lists of nats to sets of values
  bij(list) {
    var res = new Set();
    int sum = -1;
    for (final x in list) {
      sum += 1 + x;
      res.add(enumeration[sum]);
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
  bool isEmpty();

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
  mkList(int n) => new LazyList.cons(
      new Finite.singleton(n), () => mkList(n+1));
  return new Enumeration(new Thunk(() => mkList(0)));
}

Enumeration<int> _mkInts() {
  mkList(int n) => new LazyList.cons(
      new Finite.singleton(n) + new Finite.singleton(-n),
      () => mkList(n+1));
  return new Enumeration(new Thunk(() =>
      new LazyList.cons(new Finite.singleton(0), () => mkList(1))));
}

Enumeration<String> _mkStrings() {
  final cs = const ["a","b","c","d","e","f","g","h","i","j","k","l","m",
                    "n","o","p","q","r","s","t","u","v","w","x","y","z"];
  final chars = cs.map(singleton).fold(empty(), (e1, e2) => e1 + e2);
  final charsLists = listsOf(chars);
  return charsLists.map((cs) => cs.join());
}

Enumeration<Rational> _mkRationals() {
  return singleton(new Rational(0))
       + (positiveRationals + positiveRationals.map((r) => -r)).pay();
}

Rational _unGcd(List<bool> path) {
  var numerator = 1;
  var denominator = 1;
  for (final b in path) {
    if (b) denominator += numerator;
    else numerator += denominator;
  }
  return new Rational(numerator, denominator);
}

Enumeration<Rational> _mkPositiveRationals() {
  return listsOf(bools).map(_unGcd);
}