// Copyright (c) 2012, Google Inc. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

// Author: Paul Brauner (polux@google.com)

library enumerators;

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

abstract class Finite<A> {
  get card;

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
            stack.addLast(fin.value);
          else
            throw new RangeError(index);
        } else if (fin is _FSum) {
          if (i < fin.fin1.card)
            instructions.addLast(new _IEval(fin.fin1, i));
          else
            instructions.addLast(new _IEval(fin.fin2, i - fin.fin1.card));
        } else if (fin is _FProd) {
          instructions.addLast(new _IProd());
          instructions.addLast(new _IEval(fin.fin1, i ~/ fin.fin2.card));
          instructions.addLast(new _IEval(fin.fin2, i % fin.fin2.card));
        } else if (fin is _FMap) {
          instructions.addLast(new _IMap(fin.f));
          instructions.addLast(new _IEval(fin.mapped, i));
        }
      } else if (instr is _IProd) {
        final v1 = stack.removeLast();
        final v2 = stack.removeLast();
        stack.addLast(new Pair(v1, v2));
      } else if (instr is _IMap) {
        final v = stack.removeLast();
        stack.addLast(instr.f(v));
      }
    }
    return stack[0];
  }

  String toString() {
    final strings = toLazyList().map((f) => f.toString()).toList();
    return "{${strings.join(", ")}}";
  }

  LazyList<A> toLazyList() {
    aux(i) => (i == this.card)
        ? new LazyList.empty()
        : new LazyList.cons(this[i], () => aux(i+1));
    return aux(0);
  }
}

class _FEmpty<A> extends Finite<A> {
  final int card = 0;
  _FEmpty();
}

class _FSingleton<A> extends Finite<A> {
  final int card = 1;
  final A value;
  _FSingleton(this.value);
}

class _FSum<A> extends Finite<A> {
  final int card;
  final Finite<A> fin1;
  final Finite<A> fin2;
  _FSum(fin1, fin2)
      : this.fin1 = fin1
      , this.fin2 = fin2
      , card = fin1.card + fin2.card;
}

class _FProd<A> extends Finite<A> {
  final int card;
  final Finite<A> fin1;
  final Finite<A> fin2;
  _FProd(fin1, fin2)
      : this.fin1 = fin1
      , this.fin2 = fin2
      , card = fin1.card * fin2.card;
}

class _FMap<A,B> extends Finite<B> {
  final int card;
  final Function f;
  final Finite<A> mapped;
  _FMap(B f(A x), Finite<A> mapped)
      : this.f = f
      , this.mapped = mapped
      , card = mapped.card;
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
class Enumeration<A> {
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
      if (ps.isEmpty()) throw new RangeError(i);
      if (it < ps.head.card) return ps.head[it];
      it = it - ps.head.card;
      ps = ps.tail;
    }
  }

  LazyList<A> toLazyList() =>
      parts.map((f) => f.toLazyList()).concat();

  static LazyList<Finite> _zipPlus(LazyList<Finite> xs, LazyList<Finite> ys) =>
      (xs.isEmpty() || ys.isEmpty())
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
      if (xs.isEmpty()) return new LazyList.empty();
      final newrev = new LazyList.cons(xs.head, () => rev);
      return new LazyList.cons(newrev, () => go(newrev, xs.tail));
    }
    return go(new LazyList.empty(), l);
  }

  static _prod(LazyList<Finite> xs, LazyList<LazyList<Finite>> yss) {
    if (xs.isEmpty() || yss.isEmpty()) return new LazyList.empty();

    goX(ry) =>
        xs.tail.tails().map((fs) => _conv(fs, ry));

    goY(LazyList<Finite> ry, LazyList<LazyList<Finite>> rys()) {
      return new LazyList.cons(
        _conv(xs, ry),
        () {
          final _rys = rys();
          return _rys.isEmpty()
              ? goX(ry)
              : goY(_rys.head, () => _rys.tail);
        });
    };

    return goY(yss.head, () => yss.tail);
  }

  static _conv(LazyList<Finite> xs, LazyList<Finite> ys) {
    var result = new Finite.empty();
    if (ys.isEmpty()) return result;
    while(true) {
      if (xs.isEmpty()) return result;
      result = result + (xs.head * ys.head);
      ys = ys.tail;
      if (ys.isEmpty()) return result;
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
