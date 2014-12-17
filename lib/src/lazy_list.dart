// Copyright (c) 2012, Google Inc. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

// Author: Paul Brauner (polux@google.com)

library lazy_list;

import 'dart:collection';

import 'pair.dart';

/**
 * A lazy list, possibly infinite.
 */
abstract class LazyList<A> extends IterableBase<A> {
  LazyList._();
  factory LazyList.empty() => new _Empty();
  factory LazyList.cons(A head, LazyList<A> gen()) => new _Cons(head, gen);
  factory LazyList.singleton(A elem) => new _Cons(elem, () => new LazyList.empty());

  A get head;
  LazyList<A> get tail;

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

  static int counter = 0;

  String toString() => toList().toString();

  LazyList _lazyPlus(LazyList gen());

  // methods from Iterable

  Iterator<A> get iterator => new _LazyListIterator<A>(this);
}

class _Empty<A> extends LazyList<A> {
  _Empty() : super._();
  final bool isEmpty = true;
  get head {
    throw new UnsupportedError("empty lazy lists don't have heads");
  }
  get tail {
    throw new UnsupportedError("empty lazy lists don't have tails");
  }
  LazyList operator +(LazyList s) => s;
  LazyList concat() => this;
  LazyList map(f(A x)) => this;
  LazyList<LazyList> tails() => new LazyList.singleton(new LazyList.empty());
  operator[](int index) {
    throw new RangeError(index);
  }
  LazyList _lazyPlus(LazyList gen()) => gen();
}

class _Cons<A> extends LazyList<A> {
  final A head;
  final Function gen;
  LazyList<A> _cachedTail;

  _Cons(this.head, this.gen) : super._();

  final bool isEmpty = false;

  get tail {
    if (_cachedTail == null) {
      _cachedTail = gen();
    }
    return _cachedTail;
  }

  LazyList operator +(LazyList s) =>
    new LazyList.cons(head, () => tail + s);

  LazyList _lazyPlus(LazyList gen()) =>
    new LazyList.cons(head, () => tail._lazyPlus(gen));

  LazyList concat() {
    // TODO(polux): Get rid of this little dance to convice the analyzer that
    // head is a LazyList when it doesn't complain anymore about the sanest
    // LazyList headAsList = this.head.
    final untypedHead = this.head;
    LazyList headAsList = untypedHead;
    return headAsList._lazyPlus(() => this.tail.concat());
  }

  LazyList map(f(A x)) =>
    new LazyList.cons(f(head), () => tail.map(f));

  LazyList<LazyList> tails() =>
    new LazyList.cons(this, () => this.tail.tails());

  A operator[](int index) =>
    (index == 0) ? head
                 : tail[index - 1];
}

class _LazyListIterator<A> extends Iterator<A> {
  LazyList<A> list;
  A current = null;
  _LazyListIterator(this.list);

  bool moveNext() {
    if (list.isEmpty) return false;
    else {
      current = list.head;
      list = list.tail;
      return true;
    }
  }
}