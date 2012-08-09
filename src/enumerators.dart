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

Function compose(Function f1, Function f2) =>
    (x) => f1(f2(x));

/**
 * A finite set.
 */
class Finite<A> {
   final int card;
   final Function indexer;

   Finite(this.card, this.indexer);

   factory Finite.empty() => new Finite(0, (i) { throw "index out of range"; });

   factory Finite.singleton(A x) => new Finite(1, (i) {
     if (i == 0) return x;
     else throw "index out of range";
   });

   Finite<A> setCard(int newCard) => new Finite<A>(newCard, indexer);
   Finite<A> setIndexer(Function newIndexer) => new Finite<A>(card, newIndexer);

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

   A operator [](int index) => indexer(index);

   /**
    * Union.
    */
   Finite<A> operator +(Finite<A> fin) =>
       new Finite<A>(
           this.card + fin.card,
           (int i) => i < this.card ? this[i] : fin[i - this.card]);

   /**
    * Cartesian product.
    */
   Finite<Pair> operator *(Finite fin) =>
       new Finite<Pair>(
           this.card * fin.card,
           (int i) {
             int q = i ~/ fin.card;
             int r = i % fin.card;
             return new Pair(this[q], fin[r]);
           });

   /**
    * [Finite] is a functor.
    */
   Finite map(f(A x)) => this.setIndexer(compose(f, indexer));

   /**
    * [Finite] is an applicative functor.
    */
   Finite apply(Finite fin) => (this * fin).map((pair) => pair.fst(pair.snd));
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

  get head() {
    if (_cachedHead == null) _force();
    return _cachedHead;
  }

  get tail() {
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

  _index(LazyList<Finite<A>> ps, int i) {
    if (ps.isEmpty()) throw "index out of range";
    if (i < ps.head.card) return ps.head[i];
    return _index(ps.tail, i - ps.head.card);
  }

  A operator [](int i) => _index(parts, i);

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
      (LazyList<Finite> ys) {
          // a much simpler def would be "union (zipWith (*) xs ys)"
          // but according to the paper this introduces memory leaks
          final xsCards = xs.map((f) => f.card);
          final ysCards = ys.map((f) => f.card);
          final cardsProducts = xsCards.zipWith((c1, c2) => c1 * c2, ysCards);
          final newCard = cardsProducts.foldLeft(0, (c1, c2) => c1 + c2);

          newIndexer(i) {
            final unionOfProducts =
                xs.zipWith((f1, f2) => f1 * f2, ys)
                  .foldLeft(new Finite.empty(), (f1, f2) => f1 + f2);
            return unionOfProducts[i];
          }

          return new Finite(newCard, newIndexer);
      };

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
      (this * e).map((pair) => pair.fst(pair.snd));

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
