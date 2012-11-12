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

library enumerators;

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
    return "{${Strings.join(strings, ", ")}}";
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

/**
 * A lazy list, possibly infinite.
 */
abstract class LazyList<A> {
  LazyList._();
  factory LazyList.empty() => new _Empty();
  factory LazyList.cons(A head, LazyList<A> gen()) => new _Cons(head, gen);
  factory LazyList.singleton(A elem) => new _Cons(elem, () => new LazyList.empty());

  bool isEmpty();
  A get head;
  LazyList<A> get tail;

  LazyList take(int length);

  /**
   * [s] appended to [this].
   */
  LazyList operator +(LazyList s);

  /**
   * Concatenates this, Assuming [: A = Stream<Stream<B>> :].
   */
  LazyList concat();

  /**
   * [LazyList] is a functor.
   */
  LazyList map(f(A x));

  /**
   * [: [a,b,c,d].zipWith(f, [x,y,z]) :] is [: [f(a,z), f(b,y), f(c,z)] :].
   */
  LazyList zipWith(f(x,y), LazyList ys);

  /**
   * Linear indexing.
   */
  A operator[](int index);

  LazyList<LazyList> tails();

  /**
   * Cartesian product.
   */
  LazyList operator *(LazyList s) =>
      this.map((x) => s.map((y) => new Pair(x,y))).concat();

  /**
   * [LazyList] is an applicative functor.
   */
  LazyList apply(LazyList s) => (this * s).map((pair) => pair.fst(pair.snd));

  void forEach(f(A x)) {
    LazyList<A> s = this;
    while (!s.isEmpty()) {
      f(s.head);
      s = s.tail;
    }
  }

  /**
   * [: [a,b,c].foldLeft(zero, +) :] is [: zero + a + b + c :].
   */
  foldLeft(zero, plus) {
    var result = zero;
    this.forEach((x) { result = plus(result, x); });
    return result;
  }

  List<A> toList() {
    final res = [];
    this.forEach((A x) { res.add(x); });
    return res;
  }

  String toString() => toList().toString();

  LazyList _lazyPlus(LazyList gen());
}

class _Empty<A> extends LazyList<A> {
  _Empty() : super._();
  bool isEmpty() => true;
  get head => throw new UnsupportedError("empty lazy lists don't have heads");
  get tail => throw new UnsupportedError("empty lazy lists don't have tails");
  LazyList take(int length) => this;
  LazyList operator +(LazyList s) => s;
  LazyList concat() => this;
  LazyList map(f(A x)) => this;
  LazyList zipWith(f(x,y), LazyList ys) => this;
  LazyList<LazyList> tails() => new LazyList.singleton(new LazyList.empty());
  operator[](int index) => throw new RangeError(index);
  LazyList _lazyPlus(LazyList gen()) => gen();
}

class _Cons<A> extends LazyList<A> {
  final A head;
  final Function gen;
  LazyList<A> _cachedTail;

  _Cons(this.head, this.gen) : super._();

  bool isEmpty() => false;

  get tail {
    if (_cachedTail == null) {
      _cachedTail = gen();
    }
    return _cachedTail;
  }

  LazyList take(int n) =>
    (n == 0) ? new LazyList.empty()
             : new LazyList.cons(head, () => tail.take(n - 1));

  LazyList operator +(LazyList s) =>
    new LazyList.cons(head, () => tail + s);

  LazyList _lazyPlus(LazyList gen()) =>
    new LazyList.cons(head, gen);

  LazyList concat() => this.head._lazyPlus(() => this.tail.concat());

  LazyList map(f(A x)) =>
    new LazyList.cons(f(head), () => tail.map(f));

  LazyList zipWith(f(x,y), LazyList ys) =>
    ys.isEmpty()
      ? new LazyList.empty()
      : new LazyList.cons(f(this.head, ys.head),
                          () => this.tail.zipWith(f, ys.tail));

  LazyList<LazyList> tails() =>
    new LazyList.cons(this, () => this.tail.tails());

  A operator[](int index) =>
    (index == 0) ? head
                 : tail[index - 1];
}

/**
 * An enumeration of finite parts of A.
 */
class Enumeration<A> {
  Function gen;
  LazyList<Finite<A>> _parts;

  Enumeration(LazyList<Finite<A>> gen()) : this.gen = gen;
  factory Enumeration.empty() => new Enumeration(() => new LazyList.empty());
  factory Enumeration.singleton(A x) =>
      new Enumeration(() => new LazyList.singleton(new Finite.singleton(x)));
  factory Enumeration.fix(Enumeration f(Enumeration)) {
    final enum = new Enumeration(null);
    final result = f(enum);
    enum.gen = result.gen;
    return result;
  }

  LazyList<Finite<A>> get parts {
    if (_parts == null) {
      _parts = gen();
    }
    return _parts;
  }

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

  static debug(x) { print("here"); return x; }

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
      new Enumeration<A>(() => _zipPlus(this.parts, e.parts));

  /**
   * [Enumeration] is a functor.
   */
  Enumeration map(f(A x)) =>
      new Enumeration(() => parts.map((p) => p.map(f)));

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
        xs.tail.tails().map((fs) => _conv(fs)(ry));

    goY(LazyList<Finite> ry(), LazyList<LazyList<Finite>> rys()) {
      final _ry = ry();
      return new LazyList.cons(
        _conv(xs)(_ry),
        () {
          final _rys = rys();
          return _rys.isEmpty()
              ? goX(_ry)
              : goY(() => _rys.head, () => _rys.tail);
        });
    };

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
      new Enumeration<Pair>(() =>
          _prod(this.parts, _reversals(e.parts)));


  /**
  * [Enumeration] is an applicative functor.
  */
  Enumeration apply(Enumeration e) =>
      (this * e).map((pair) => (pair.fst as Function)(pair.snd));

  /**
   * Pays for one recursive call.
   */
  Enumeration<A> pay() => new Enumeration<A>(
      () => new LazyList.cons(new Finite.empty(), () => this.parts));

  toString() => "Enum $parts";
}

// shortcuts

Enumeration empty() => new Enumeration.empty();
Enumeration singleton(x) => new Enumeration.singleton(x);
Enumeration fix(Enumeration f(Enumeration)) => new Enumeration.fix(f);
