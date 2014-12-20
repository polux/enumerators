// Copyright (c) 2014, Google Inc. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

// Author: Paul Brauner (polux@google.com)

library enumeration;

import 'dart:collection';

import 'finite.dart';
import 'lazy_list.dart';
import 'pair.dart';

class Thunk<A> {
  final Function gen;
  A _cached;

  Thunk(A gen()) : this.gen = gen;

  A get value {
    if (_cached == null) {
      _cached = gen();
    }
    return _cached;
  }
}

/**
 * An enumeration of finite parts of A.
 */
class Enumeration<A> extends IterableBase<A> {
  Thunk<LazyList<Finite<A>>> thunk;

  Enumeration(this.thunk);

  factory Enumeration.empty() =>
      new Enumeration(
          new Thunk(() => new LazyList.empty()));

  factory Enumeration.singleton(A x) =>
      new Enumeration(
          new Thunk(() => new LazyList.singleton(new Finite.singleton(x))));

  factory Enumeration.fix(Enumeration f(Enumeration e)) {
    final enumeration = new Enumeration(null);
    final result = f(enumeration);
    enumeration.thunk = result.thunk;
    return result;
  }

  LazyList<Finite<A>> get parts => thunk.value;

  A operator [](int i) {
    var ps = parts;
    var it = i;
    while (true) {
      if (ps.isEmpty) throw new RangeError(i);
      if (it < ps.head.length) return ps.head[it];
      it = it - ps.head.length;
      ps = ps.tail;
    }
  }

  Iterator<A> get iterator => parts.expand((f) => f).iterator;

  static LazyList<Finite> _zipPlus(LazyList<Finite> xs, LazyList<Finite> ys) =>
      (xs.isEmpty || ys.isEmpty)
          ? xs + ys
          : new LazyList.cons(xs.head + ys.head,
                              () => _zipPlus(xs.tail, ys.tail));

  /**
   * Disjoint union (it is up to the user to make sure that operands are
   * disjoint).
   */
  Enumeration<A> operator +(Enumeration<A> e) =>
      new Enumeration<A>(
          new Thunk(() => _zipPlus(this.parts, e.parts)));

  /**
   * [Enumeration] is a functor.
   */
  Enumeration map(f(A x)) =>
      new Enumeration(
          new Thunk(() => parts.map((p) => p.map(f))));

  /**
   * [: _reversals([1,2,3,...]) :] is [: [[1], [2,1], [3,2,1], ...] :].
   */
  static LazyList<LazyList> _reversals(LazyList l) {
    go(LazyList rev, LazyList xs) {
      if (xs.isEmpty) return new LazyList.empty();
      final newrev = new LazyList.cons(xs.head, () => rev);
      return new LazyList.cons(newrev, () => go(newrev, xs.tail));
    }
    return go(new LazyList.empty(), l);
  }

  static _prod(LazyList<Finite> xs, LazyList<LazyList<Finite>> yss) {
    if (xs.isEmpty || yss.isEmpty) return new LazyList.empty();

    goX(ry) =>
        xs.tail.tails().map((fs) => _conv(fs, ry));

    goY(LazyList<Finite> ry, LazyList<LazyList<Finite>> rys()) {
      return new LazyList.cons(
        _conv(xs, ry),
        () {
          final _rys = rys();
          return _rys.isEmpty
              ? goX(ry)
              : goY(_rys.head, () => _rys.tail);
        });
    };

    return goY(yss.head, () => yss.tail);
  }

  static _conv(LazyList<Finite> xs, LazyList<Finite> ys) {
    var result = new Finite.empty();
    if (ys.isEmpty) return result;
    while(true) {
      if (xs.isEmpty) return result;
      result = result + (xs.head * ys.head);
      ys = ys.tail;
      if (ys.isEmpty) return result;
      xs = xs.tail;
    }
  }

  /**
   * Cartesian product.
   */
  Enumeration<Pair> operator *(Enumeration<A> e) =>
      new Enumeration<Pair>(
          new Thunk(() =>
              _prod(this.parts, _reversals(e.parts))));


  /**
  * [Enumeration] is an applicative functor.
  */
  Enumeration apply(Enumeration e) =>
      (this * e).map((pair) => (pair.fst as Function)(pair.snd));

  /**
   * Pays for one recursive call.
   */
  Enumeration<A> pay() => new Enumeration<A>(
      new Thunk(() =>
          new LazyList.cons(new Finite.empty(), () => this.parts)));

  toString() => "Enum $parts";
}

// shortcuts

Enumeration empty() => new Enumeration.empty();

Enumeration singleton(x) => new Enumeration.singleton(x);

Enumeration fix(Enumeration f(Enumeration)) => new Enumeration.fix(f);

Enumeration apply(Function f, Enumeration arg1, [Enumeration arg2,
                  Enumeration arg3, Enumeration arg4, Enumeration arg5]) {
  if (arg2 == null) {
    return arg1.map(f);
  } else if (arg3 == null) {
    return (arg1 * arg2).map((pair) {
      return f(pair.fst, pair.snd);
    });
  } else if (arg4 == null) {
    return ((arg1 * arg2) * arg3).map((pair) {
      final a1 = pair.fst;
      return f(a1.fst, a1.snd, pair.snd);
    });
  } else if (arg5 == null) {
    return (((arg1 * arg2) * arg3) * arg4).map((pair) {
      final a1 = pair.fst;
      final a11 = a1.fst;
      return f(a11.fst, a11.snd, a1.snd, pair.snd);
    });
  } else {
    return ((((arg1 * arg2) * arg3) * arg4) * arg5).map((pair) {
      final a1 = pair.fst;
      final a11 = a1.fst;
      final a111 = a11.fst;
      return f(a111.fst, a111.snd, a11.snd, a1.snd, pair.snd);
    });
  }
}