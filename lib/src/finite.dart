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

  _LIMult1(this.toUpdate, this.fin): super._(_LInstruction.LI_MULT1);
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

  factory Finite.empty() => new _EmptyFinite();

  factory Finite.singleton(A x) => new _SingletonFinite(x);

  /**
   * Union.
   */
  Finite<A> operator +(Finite<A> fin) => new _AddFinite(this, fin);

  /**
   * Cartesian product.
   */
  Finite<Pair> operator *(Finite fin) => new _MultFinite(this, fin);

  /**
   * [Finite] is a functor.
   */
  Finite map(f(A x)) => new _MapFinite(this, f);

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
          switch(fin.tag) {
            case EMPTY:
              val = fin._cachedLength = 0;
              evalFin = false;
              break;
            case SINGLETON:
              val = fin._cachedLength = 1;
              evalFin = false;
              break;
            case MAP:
              stack.add(new _LIMap(fin));
              fin = fin.fin;
              break;
            case ADD:
              stack.add(new _LIAdd1(fin.left, fin.right));
              fin = fin.left;
              break;
            case MULT:
              stack.add(new _LIMult1(fin.left, fin.right));
              fin = fin.left;
              break;
          }
        }
      } else {
        final instr = stack.removeLast();
        switch (instr.tag) {
          case _LInstruction.LI_DONE:
            return val;
          case _LInstruction.LI_MAP:
            instr.toUpdate._cachedLength = val;
            break;
          case _LInstruction.LI_ADD1:
            fin = instr.fin;
            stack.add(new _LIAdd2(fin, val));
            instr.toUpdate._cachedLength = val;
            evalFin = true;
            break;
          case _LInstruction.LI_ADD2:
            instr.toUpdate._cachedLength = val;
            val += instr.val;
            break;
          case _LInstruction.LI_MULT1:
            fin = instr.fin;
            stack.add(new _LIMult2(fin, val));
            instr.toUpdate._cachedLength = val;
            evalFin = true;
            break;
          case _LInstruction.LI_MULT2:
            instr.toUpdate._cachedLength = val;
            val *= instr.val;
            break;
        }
      }
    }
  }

  A operator [](int index) => _eval(this, index);

  static Object _eval(Finite finite, int index) {
    bool evalFin = true;
    final stack = <_EInstruction>[new _EIDone()];

    var val;
    var fin = finite;

    while (true) {
      if (evalFin) {
        switch(fin.tag) {
          case ADD:
            if (index < fin.left.length) {
              fin = fin.left;
            } else {
              final left = fin.left;
              fin = fin.right;
              index = index - left.length;
            }
            break;
          case EMPTY:
            throw new RangeError(index);
            break;
          case MULT:
            int q = index ~/ fin.right.length;
            int r = index % fin.right.length;
            index = q;
            stack.add(new _EIPair1(fin.right, r));
            fin = fin.left;
            break;
          case SINGLETON:
            if (index == 0) {
              val = fin.val;
              evalFin = false;
            } else {
              throw new RangeError(index);
            }
            break;
          case MAP:
            stack.add(new _EIMap(fin.fun));
            fin = fin.fin;
            break;
        }
      } else {
        final instr = stack.removeLast();
        switch (instr.tag) {
          case _EInstruction.EI_DONE:
            return val;
          case _EInstruction.EI_MAP:
            val = instr.fun(val);
            break;
          case _EInstruction.EI_PAIR2:
            val = new Pair(instr.snd, val);
            break;
          case _EInstruction.EI_PAIR1:
            fin = instr.fin2;
            index = instr.r;
            stack.add(new _EIPair2(val));
            evalFin = true;
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

class _MultFinite<A> extends Finite<A> {
  final Finite<A> left;
  final Finite<A> right;

  _MultFinite(this.left, this.right) : super._(Finite.MULT);
}

class _MapFinite<A> extends Finite<A> {
  final Finite<A> fin;
  final Function fun;

  _MapFinite(this.fin, fun(A x)) : super._(Finite.MAP), this.fun = fun;
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