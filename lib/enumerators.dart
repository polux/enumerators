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

#library('enumerators');

class Pair<A,B> {
  final A fst;
  final B snd;
  Pair(this.fst, this.snd);
  Pair<A,B> setFst(A x) => new Pair<A,B>(x, snd);
  Pair<A,B> setSnd(B x) => new Pair<A,B>(fst, x);
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
  abstract get card;

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
          throw "index out of range";
        } else if (fin is _FSingleton) {
          if (i == 0)
            stack.addLast(fin.value);
          else
            throw "index out of range";
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
    return "{${Strings.join(strings, ", ")}}";
  }

  LazyList<A> toLazyList() {
    aux(i) => (i == this.card)
        ? new LazyList.empty()
        : new LazyList(() => new Pair(this[i], aux(i+1)));
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

/**
 * A lazy list, possibly infinite.
 */
class LazyList<A> {
  final Function gen;
  A _cachedHead;
  LazyList<A> _cachedTail;

  LazyList(Pair<A, LazyList<A>> gen()) : this.gen = gen;
  factory LazyList.empty() => new LazyList(null);
  factory LazyList.singleton(A x) =>
      new LazyList(() => new Pair(x, new LazyList.empty()));
  factory LazyList.repeat(A x) =>
      new LazyList(() => new Pair(x, new LazyList.repeat(x)));

  bool isEmpty() => gen === null;

  void _force() {
    final pair = gen();
    _cachedHead = pair.fst;
    _cachedTail = pair.snd;
  }

  get head {
    if (_cachedHead == null) _force();
    return _cachedHead;
  }

  get tail {
    if (_cachedTail == null) _force();
    return _cachedTail;
  }

  void forEach(f(A x)) {
    LazyList<A> s = this;
    while (!s.isEmpty()) {
      f(s.head);
      s = s.tail;
    }
  }

  LazyList take(int length) {
    aux(LazyList rest, int n) => (n == 0 || rest.isEmpty())
        ? new LazyList.empty()
        : new LazyList(() => new Pair(rest.head, aux(rest.tail, n - 1)));
    return aux(this, length);
  }

  /**
   * [s] appended to [this].
   */
  LazyList operator +(LazyList s) => this.isEmpty()
      ? s
      : new LazyList(() => new Pair(head, tail + s));

  /**
   * Concatenates this, Assuming [: A = Stream<Stream<B>> :].
   */
  LazyList concat() => this.isEmpty()
      ? new LazyList.empty()
      : new LazyList(() => (this.head + this.tail.concat()).gen());

  /**
   * Cartesian product.
   */
  LazyList operator *(LazyList s) =>
      this.map((x) => s.map((y) => new Pair(x,y))).concat();

  /**
   * [LazyList] is a functor.
   */
  LazyList map(f(A x)) => this.isEmpty()
      ? new LazyList.empty()
      : new LazyList(() => new Pair(f(head), tail.map(f)));

  /**
   * [LazyList] is an applicative functor.
   */
  LazyList apply(LazyList s) => (this * s).map((pair) => pair.fst(pair.snd));

  /**
   * [: [a,b,c,d].zipWith(f, [x,y,z]) :] is [: [f(a,z), f(b,y), f(c,z)] :].
   */
  LazyList zipWith(f(x,y), LazyList ys) => (this.isEmpty() || ys.isEmpty())
      ? new LazyList.empty()
      : new LazyList(() =>
          new Pair(f(this.head, ys.head), this.tail.zipWith(f, ys.tail)));

  /**
   * [: [a,b,c].foldLeft(zero, +) :] is [: zero + a + b + c :].
   */
  foldLeft(zero, plus) {
    var result = zero;
    this.forEach((x) { result = plus(result, x); });
    return result;
  }

  LazyList<LazyList> tails() => this.isEmpty()
      ? new LazyList.singleton(new LazyList.empty())
      : new LazyList(() => new Pair(this, this.tail.tails()));

  /**
   * Linear indexing.
   */
  A operator[](int index) {
    getAt(LazyList l, int i) {
      if (l.isEmpty()) throw "index out of range";
      if (i == 0) return l.head;
      return getAt(l.tail, i - 1);
    }
    return getAt(this, index);
  }

  List<A> toList() {
    final res = [];
    this.forEach((A x) { res.add(x); });
    return res;
  }

  String toString() => toList().toString();
}

/**
 * An enumeration of finite parts of A.
 */
class Enumeration<A> {
  // morally final, but Enumeration.fix needs to reset it
  LazyList<Finite<A>> parts;

  Enumeration(this.parts);
  factory Enumeration._fromGen(Pair<Finite<A>, LazyList<Finite<A>>> gen()) =>
      new Enumeration(new LazyList(gen));
  factory Enumeration.empty() => new Enumeration(new LazyList.empty());
  factory Enumeration.singleton(A x) =>
      new Enumeration(new LazyList.singleton(new Finite.singleton(x)));
  factory Enumeration.fix(Enumeration f(Enumeration)) {
    final enum = new Enumeration(null);
    final result = f(enum);
    enum.parts = result.parts;
    return result;
  }

  A operator [](int i) {
    var ps = parts;
    var it = i;
    while (true) {
      if (ps.isEmpty()) throw "index out of range";
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
          : new LazyList(() =>
                new Pair(xs.head + ys.head, _zipPlus(xs.tail, ys.tail)));

  /**
   * Disjoint union (it is up to the user to make sure that operands are
   * disjoint).
   */
  Enumeration<A> operator +(Enumeration<A> e) =>
      new Enumeration<A>._fromGen(() => _zipPlus(this.parts, e.parts).gen());

  /**
   * [Enumeration] is a functor.
   */
  Enumeration map(f(A x)) =>
      new Enumeration._fromGen(() => parts.map((p) => p.map(f)).gen());

  /**
   * [: _reversals([1,2,3,...]) :] is [: [[1], [2,1], [3,2,1], ...] :].
   */
  static LazyList<LazyList> _reversals(LazyList l) {
    go(LazyList rev, LazyList xs) {
      if (xs.isEmpty()) return new LazyList.empty();
      final newrev = new LazyList(() => new Pair(xs.head, rev));
      return new LazyList(() => new Pair(newrev, go(newrev, xs.tail)));
    }
    return go(new LazyList.empty(), l);
  }

  static _prod(LazyList<Finite> xs, LazyList<LazyList<Finite>> yss) {
    if (xs.isEmpty() || yss.isEmpty()) return new LazyList.empty();

    goX(ry) =>
        xs.tail.tails().map((fs) => _conv(fs)(ry));

    goY(LazyList<Finite> ry(), LazyList<LazyList<Finite>> rys()) =>
        new LazyList(() {
          final _ry = ry();
          final _rys = rys();
          return new Pair(
            _conv(xs)(_ry),
            _rys.isEmpty() ? goX(_ry) : goY(() => _rys.head, () => _rys.tail));
        });

    return goY(() => yss.head, () => yss.tail);
  }

  static _conv(LazyList<Finite> xs) =>
      (LazyList<Finite> ys) =>
          xs.zipWith((f1, f2) => f1 * f2, ys)
            .foldLeft(new Finite.empty(), (f1, f2) => f1 + f2);

  /**
   * Cartesian product.
   */
  Enumeration<Pair> operator *(Enumeration<A> e) =>
      new Enumeration<Pair>._fromGen(() =>
          _prod(this.parts, _reversals(e.parts)).gen());


  /**
  * [Enumeration] is an applicative functor.
  */
  Enumeration apply(Enumeration e) =>
      (this * e).map((pair) => (pair.fst as Function)(pair.snd));

  /**
   * Pays for one recursive call.
   */
  Enumeration<A> pay() => new Enumeration<A>._fromGen(
      () => new Pair(new Finite.empty(), this.parts));

  toString() => "Enum $parts";
}

// shortcuts

Enumeration empty() => new Enumeration.empty();
Enumeration singleton(x) => new Enumeration.singleton(x);
Enumeration fix(Enumeration f(Enumeration)) => new Enumeration.fix(f);
