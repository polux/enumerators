// Copyright (c) 2012, Google Inc. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

// Author: Paul Brauner (polux@google.com)

library enumerators;

import 'dart:collection';

part 'src/lazy_list.dart';

class Pair<A,B> {
  final A fst;
  final B snd;
  Pair(this.fst, this.snd);
  Pair<A,B> setFst(A x) => new Pair<A,B>(x, snd);
  Pair<A,B> setSnd(B x) => new Pair<A,B>(fst, x);
  int get hashCode => 31 * fst.hashCode + snd.hashCode;
  bool operator ==(Pair<A,B> other) =>
      other is Pair<A,B>
      && fst == other.fst
      && snd == other.snd;
  toString() => "($fst, $snd)";
}

class _Instruction {}
class _IProd extends _Instruction {}
class _IMap extends _Instruction {
  final Function f;
  _IMap(this.f);
}
class _IEval extends _Instruction {
  final Finite fin;
  final int i;
  _IEval(this.fin, this.i);
  toString() => "eval($fin, $i)";
}

abstract class Finite<A> extends IterableBase<A> {
  Finite();
  factory Finite.empty() => new _FEmpty();
  factory Finite.singleton(A x) => new _FSingleton(x);

  /**
   * Union.
   */
  Finite<A> operator +(Finite<A> fin) => new _FSum(this, fin);

  /**
   * Cartesian product.
   */
  Finite<Pair> operator *(Finite fin) => new _FProd(this, fin);

  /**
   * [Finite] is a functor.
   */
  Finite map(f(A x)) => new _FMap(f, this);

  /**
   * [Finite] is an applicative functor.
   */
  Finite apply(Finite fin) =>
      (this * fin).map((pair) => (pair.fst as Function)(pair.snd));

  A operator [](int index) => _eval(this, index);

  static _eval(Finite finite, int index) {
    var instructions = <_Instruction>[new _IEval(finite, index)];
    var stack = [];
    while (instructions.length > 0) {
      _Instruction instr = instructions.removeLast();
      if (instr is _IEval) {
        final i = instr.i;
        final fin = instr.fin;
        if (fin is _FEmpty) {
          throw new RangeError(index);
        } else if (fin is _FSingleton) {
          if (i == 0)
            stack.add(fin.value);
          else
            throw new RangeError(index);
        } else if (fin is _FSum) {
          if (i < fin.fin1.length)
            instructions.add(new _IEval(fin.fin1, i));
          else
            instructions.add(new _IEval(fin.fin2, i - fin.fin1.length));
        } else if (fin is _FProd) {
          instructions.add(new _IProd());
          instructions.add(new _IEval(fin.fin1, i ~/ fin.fin2.length));
          instructions.add(new _IEval(fin.fin2, i % fin.fin2.length));
        } else if (fin is _FMap) {
          instructions.add(new _IMap(fin.f));
          instructions.add(new _IEval(fin.mapped, i));
        }
      } else if (instr is _IProd) {
        final v1 = stack.removeLast();
        final v2 = stack.removeLast();
        stack.add(new Pair(v1, v2));
      } else if (instr is _IMap) {
        final v = stack.removeLast();
        stack.add(instr.f(v));
      }
    }
    return stack[0];
  }

  String toString() {
    final strings = toLazyList().map((f) => f.toString()).toList();
    return "{${strings.join(", ")}}";
  }

  Iterator<A> get iterator => new _FiniteIterator<A>(this);

  LazyList<A> toLazyList() {
    aux(i) => (i == this.length)
        ? new LazyList.empty()
        : new LazyList.cons(this[i], () => aux(i+1));
    return aux(0);
  }

  // optimized Iterable methods

  bool get isEmpty => length == 0;

  A elementAt(int index) => this[index];

  A get first {
    if (isEmpty) {
      throw new StateError('Cannot access first element of an empty set.');
    }
    return this[0];
  }

  A get last {
    if (isEmpty) {
      throw new StateError('Cannot access last element of an empty set.');
    }
    return this[length - 1];
  }
}

class _FEmpty<A> extends Finite<A> {
  final int length = 0;
  final bool isEmpty = true;
  _FEmpty();
}

class _FSingleton<A> extends Finite<A> {
  final int length = 1;
  final bool isEmpty = false;
  final A value;
  _FSingleton(this.value);
}

class _FSum<A> extends Finite<A> {
  final int length;
  final Finite<A> fin1;
  final Finite<A> fin2;
  _FSum(fin1, fin2)
      : this.fin1 = fin1
      , this.fin2 = fin2
      , length = fin1.length + fin2.length;
}

class _FProd<A> extends Finite<A> {
  final int length;
  final Finite<A> fin1;
  final Finite<A> fin2;
  _FProd(fin1, fin2)
      : this.fin1 = fin1
      , this.fin2 = fin2
      , length = fin1.length * fin2.length;
}

class _FMap<A,B> extends Finite<B> {
  final int length;
  final Function f;
  final Finite<A> mapped;
  _FMap(B f(A x), Finite<A> mapped)
      : this.f = f
      , this.mapped = mapped
      , length = mapped.length;
}

class _FiniteIterator<A> extends Iterator<A> {
  final Finite<A> finite;
  int index = -1;
  A current = null;

  _FiniteIterator(this.finite);

  bool moveNext() {
    if (index == finite.length) return false;

    index++;
    if (index == finite.length) {
      current = null;
      return false;
    } else {
      current = finite[index];
      return true;
    }
  }
}

class Thunk<A> {
  A _cached;
  Function gen;
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
  factory Enumeration.fix(Enumeration f(Enumeration)) {
    final enum = new Enumeration(null);
    final result = f(enum);
    enum.thunk = result.thunk;
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
