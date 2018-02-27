// Copyright (c) 2014, Google Inc. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

// Author: Paul Brauner (polux@google.com)

library finite;

import 'dart:collection';

import 'lazy_list.dart';
import 'pair.dart';

abstract class _EInstruction {
  static const EI_DONE = 0;
  static const EI_MAP = 1;
  static const EI_PAIR2 = 2;
  static const EI_PAIR1 = 3;

  // Ideally we would switch/case on runtimeType but it's to slow for now
  final int tag;

  _EInstruction._(this.tag);
}

class _EIDone extends _EInstruction {
  _EIDone() : super._(_EInstruction.EI_DONE);
}

class _EIMap extends _EInstruction {
  final fun;

  _EIMap(this.fun) : super._(_EInstruction.EI_MAP);
}

class _EIPair1 extends _EInstruction {
  final Finite fin2;
  final r;

  _EIPair1(this.fin2, this.r) : super._(_EInstruction.EI_PAIR1);
}

class _EIPair2 extends _EInstruction {
  final tag = _EInstruction.EI_PAIR2;
  final snd;

  _EIPair2(this.snd) : super._(_EInstruction.EI_PAIR2);
}

abstract class _LInstruction {
  static const LI_DONE = 0;
  static const LI_MAP = 1;
  static const LI_ADD1 = 2;
  static const LI_ADD2 = 3;
  static const LI_MULT1 = 4;
  static const LI_MULT2 = 5;

  // Ideally we would switch/case on runtimeType but it's to slow for now
  final int tag;

  _LInstruction._(this.tag);
}

class _LIDone extends _LInstruction {
  _LIDone() : super._(_LInstruction.LI_DONE);
}

class _LIMap extends _LInstruction {
  final Finite toUpdate;

  _LIMap(this.toUpdate) : super._(_LInstruction.LI_MAP);
}

class _LIAdd1 extends _LInstruction {
  final Finite toUpdate;
  final Finite fin;

  _LIAdd1(this.toUpdate, this.fin) : super._(_LInstruction.LI_ADD1);
}

class _LIAdd2 extends _LInstruction {
  final Finite toUpdate;
  final int val;

  _LIAdd2(this.toUpdate, this.val) : super._(_LInstruction.LI_ADD2);
}

class _LIMult1 extends _LInstruction {
  final Finite toUpdate;
  final Finite fin;

  _LIMult1(this.toUpdate, this.fin) : super._(_LInstruction.LI_MULT1);
}

class _LIMult2 extends _LInstruction {
  final Finite toUpdate;
  final int val;

  _LIMult2(this.toUpdate, this.val) : super._(_LInstruction.LI_MULT2);
}

abstract class Finite<A> extends IterableBase<A> {
  static const ADD = 0;
  static const EMPTY = 1;
  static const MULT = 2;
  static const SINGLETON = 3;
  static const MAP = 4;

  // Ideally we would switch/case on runtimeType but it's to slow for now
  final int tag;

  Finite._(this.tag);

  bool get _isEmpty => (tag == Finite.EMPTY);
  bool get _isSingleton => (tag == Finite.SINGLETON);
  bool get _isMap => (tag == Finite.MAP);

  static final Finite FINITE_EMPTY = new _EmptyFinite();

  factory Finite.empty() => FINITE_EMPTY;

  factory Finite.singleton(A x) => new _SingletonFinite<A>(x);

  /**
   * Union.
   */
  Finite<A> operator +(Finite<A> fin) {
    if (this is _EmptyFinite<A>) return fin;
    if (fin is _EmptyFinite<A>) return this;
    return new _AddFinite(this, fin);
  }

  /**
   * Cartesian product.
   */
  Finite<Pair<A, B>> times<B>(Finite<B> fin) {
    if (this._isEmpty) return new Finite.empty();
    if (fin._isEmpty) return new Finite.empty();
    if (this._isSingleton && fin._isSingleton) {
      _SingletonFinite self = this as _SingletonFinite<A>;
      _SingletonFinite other = fin as _SingletonFinite<B>;
      return new _SingletonFinite(new Pair(self.val, other.val));
    }
    return new _MultFinite(this, fin);
  }

  /**
   * Cartesian product.
   */
  Finite<Pair> operator *(Finite fin) => this.times(fin);

  /**
   * [Finite] is a functor.
   */
  Finite<B> map<B>(B f(A x)) {
    if (this._isEmpty) return new Finite.empty();
    if (this._isSingleton) {
      _SingletonFinite self = this as _SingletonFinite<A>;
      return new _SingletonFinite(f(self.val));
    }
    if (this._isMap) {
      _MapFinite self = this as _MapFinite<A, B>;
      return new _MapFinite(self.fin, (x) => f(self.fun(x)));
    }
    return new _MapFinite(this, f);
  }

  /**
   * [Finite] is an applicative functor.
   */
  Finite apply(Finite fin) =>
      (this * fin).map((pair) => (pair.fst as Function)(pair.snd));

  int _cachedLength;

  int get length {
    if (_cachedLength == null) {
      _cachedLength = _evalLength(this);
    }
    return _cachedLength;
  }

  static int _evalLength(Finite finite) {
    bool evalFin = true;
    final stack = <_LInstruction>[new _LIDone()];

    var val;
    var fin = finite;

    while (true) {
      if (evalFin) {
        if (fin._cachedLength != null) {
          val = fin._cachedLength;
          evalFin = false;
        } else {
          switch (fin.tag) {
            case EMPTY:
              val = fin._cachedLength = 0;
              evalFin = false;
              break;
            case SINGLETON:
              val = fin._cachedLength = 1;
              evalFin = false;
              break;
            case MAP:
              final mapFin = fin as _MapFinite;
              stack.add(new _LIMap(mapFin));
              fin = mapFin.fin;
              break;
            case ADD:
              final addFin = fin as _AddFinite;
              stack.add(new _LIAdd1(addFin.left, addFin.right));
              fin = addFin.left;
              break;
            case MULT:
              final multFin = fin as _MultFinite;
              stack.add(new _LIMult1(multFin.left, multFin.right));
              fin = multFin.left;
              break;
          }
        }
      } else {
        final instr = stack.removeLast();
        switch (instr.tag) {
          case _LInstruction.LI_DONE:
            return val;
          case _LInstruction.LI_ADD1:
            final addInstr = instr as _LIAdd1;
            fin = addInstr.fin;
            stack.add(new _LIAdd2(fin, val));
            addInstr.toUpdate._cachedLength = val;
            evalFin = true;
            break;
          case _LInstruction.LI_ADD2:
            final addInstr = instr as _LIAdd2;
            addInstr.toUpdate._cachedLength = val;
            val += addInstr.val;
            break;
          case _LInstruction.LI_MULT1:
            final multInstr = instr as _LIMult1;
            fin = multInstr.fin;
            stack.add(new _LIMult2(fin, val));
            multInstr.toUpdate._cachedLength = val;
            evalFin = true;
            break;
          case _LInstruction.LI_MULT2:
            final multInstr = instr as _LIMult2;
            multInstr.toUpdate._cachedLength = val;
            val *= multInstr.val;
            break;
          case _LInstruction.LI_MAP:
            final mapInstr = instr as _LIMap;
            mapInstr.toUpdate._cachedLength = val;
            break;
        }
      }
    }
  }

  A operator [](int index) => _eval(this, index);

  static A _eval<A>(Finite<A> finite, int index) {
    bool evalFin = true;
    final stack = <_EInstruction>[new _EIDone()];

    var val;
    var fin = finite;

    while (true) {
      if (evalFin) {
        switch (fin.tag) {
          case EMPTY:
            throw new RangeError(index);
            break;
          case SINGLETON:
            final singletonFin = fin as _SingletonFinite;
            if (index == 0) {
              val = singletonFin.val;
              evalFin = false;
            } else {
              throw new RangeError(index);
            }
            break;
          case ADD:
            final addFin = fin as _AddFinite;
            if (index < addFin.left.length) {
              fin = addFin.left;
            } else {
              final left = addFin.left;
              fin = addFin.right;
              index = index - left.length;
            }
            break;
          case MULT:
            final multFin = fin as _MultFinite;
            int q = index ~/ multFin.right.length;
            int r = index % multFin.right.length;
            index = q;
            stack.add(new _EIPair1(multFin.right, r));
            fin = multFin.left;
            break;
          case MAP:
            final mapFin = fin as _MapFinite;
            stack.add(new _EIMap(mapFin.fun));
            fin = mapFin.fin;
            break;
        }
      } else {
        final instr = stack.removeLast();
        switch (instr.tag) {
          case _EInstruction.EI_DONE:
            return val;
          case _EInstruction.EI_PAIR1:
            final pairInstr = instr as _EIPair1;
            fin = pairInstr.fin2;
            index = pairInstr.r;
            stack.add(new _EIPair2(val));
            evalFin = true;
            break;
          case _EInstruction.EI_PAIR2:
            final pairInstr = instr as _EIPair2;
            val = new Pair(pairInstr.snd, val);
            break;
          case _EInstruction.EI_MAP:
            final mapInstr = instr as _EIMap;
            val = mapInstr.fun(val);
            break;
        }
      }
    }
  }

  String toString() {
    final strings = toLazyList().map((f) => f.toString()).toList();
    return "{${strings.join(", ")}}";
  }

  Iterator<A> get iterator => new _FiniteIterator<A>(this);

  LazyList<A> toLazyList() {
    aux(i) => (i == this.length)
        ? new LazyList.empty()
        : new LazyList.cons(this[i], () => aux(i + 1));
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

class _EmptyFinite<A> extends Finite<A> {
  _EmptyFinite() : super._(Finite.EMPTY);
}

class _SingletonFinite<A> extends Finite<A> {
  final A val;

  _SingletonFinite(this.val) : super._(Finite.SINGLETON);
}

class _AddFinite<A> extends Finite<A> {
  final Finite<A> left;
  final Finite<A> right;

  _AddFinite(this.left, this.right) : super._(Finite.ADD);
}

class _MultFinite<A, B> extends Finite<Pair<A, B>> {
  final Finite<A> left;
  final Finite<B> right;

  _MultFinite(this.left, this.right) : super._(Finite.MULT);
}

class _MapFinite<A, B> extends Finite<B> {
  final Finite<A> fin;
  final Function fun;

  _MapFinite(this.fin, B fun(A x))
      : this.fun = fun,
        super._(Finite.MAP);
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
