// Copyright (c) 2012, Google Inc. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

// Author: Paul Brauner (polux@google.com)

library combinators;

import 'package:enumerators/enumerators.dart';
import 'package:rational/rational.dart';

import 'src/linked_list.dart';

/* public API */

const _ALPHABET = const [
  "a",
  "b",
  "c",
  "d",
  "e",
  "f",
  "g",
  "h",
  "i",
  "j",
  "k",
  "l",
  "m",
  "n",
  "o",
  "p",
  "q",
  "r",
  "s",
  "t",
  "u",
  "v",
  "w",
  "x",
  "y",
  "z"
];

final Enumeration<bool> bools = _mkBools();

/// Strings made out of the english alphabet.
final Enumeration<String> strings = stringsFrom(_ALPHABET);

final Enumeration<int> nats = _mkNats();

final Enumeration<int> ints = _mkInts();

final Enumeration<Rational> positiveRationals = _mkPositiveRationals();

final Enumeration<Rational> rationals = _mkRationals();

/// Strings made out of [characters].
Enumeration<String> stringsFrom(List<String> characters) {
  final chars = characters.map(singleton).fold(empty(), (e1, e2) => e1 + e2);
  final charsLists = listsOf(chars);
  return charsLists.map((cs) => cs.join());
}

Enumeration<List<A>> listsOf<A>(Enumeration<A> enumeration) {
  final nils = singleton(nil);
  consesOf(e) => apply(cons, enumeration, e);
  final linkedLists = fix((e) => (nils + consesOf(e).pay()));
  return linkedLists.map((linkedList) => linkedList.toList());
}

Enumeration<Set<A>> setsOf<A>(Enumeration<A> enumeration) {
  // bijection from lists of nats to sets of values
  Set<A> bij(List<int> list) {
    var res = new Set<A>();
    int sum = -1;
    for (final x in list) {
      sum += 1 + x;
      res.add(enumeration[sum]);
    }
    return res;
  }

  return listsOf(nats).map(bij);
}

Enumeration<Map<K, V>> mapsOf<K, V>(
    Enumeration<K> keys, Enumeration<V> values) {
  // bijection from lists of (nat x value) to maps of (key x value)
  Map<K, V> bij(List<Pair<int, V>> assocs) {
    var res = new Map();
    int sum = -1;
    for (final assoc in assocs) {
      sum += 1 + assoc.fst;
      res[keys[sum]] = assoc.snd;
    }
    return res;
  }

  return listsOf(nats.times(values)).map(bij);
}

Enumeration<List> productsOf(List<Enumeration> enumerations) {
  var products = singleton(nil);
  for (final enumeration in enumerations.reversed) {
    products = apply(cons, enumeration, products);
  }
  return products.map((linkedList) => linkedList.toList());
}

/* implementation */

Enumeration<bool> _mkBools() {
  return singleton(true) + singleton(false);
}

Enumeration<int> _mkNats() {
  mkList(int n) =>
      new LazyList.cons(new Finite.singleton(n), () => mkList(n + 1));
  return new Enumeration(new Thunk(() => mkList(0)));
}

Enumeration<int> _mkInts() {
  mkList(int n) => new LazyList.cons(
      new Finite.singleton(n) + new Finite.singleton(-n), () => mkList(n + 1));
  return new Enumeration(new Thunk(
      () => new LazyList.cons(new Finite.singleton(0), () => mkList(1))));
}

Enumeration<Rational> _mkRationals() {
  return singleton(new Rational(0)) +
      (positiveRationals + positiveRationals.map((r) => -r)).pay();
}

Rational _unGcd(List<bool> path) {
  var numerator = 1;
  var denominator = 1;
  for (final b in path) {
    if (b)
      denominator += numerator;
    else
      numerator += denominator;
  }
  return new Rational(numerator, denominator);
}

Enumeration<Rational> _mkPositiveRationals() {
  return listsOf(bools).map(_unGcd);
}
