// Copyright (c) 2012, Google Inc. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

// Author: Paul Brauner (polux@google.com)

import 'package:dart_enumerators/enumerators.dart';
import 'package:unittest/unittest.dart';

void testCardinalOfSum() {
  final empty = new Finite.empty();
  final a = new Finite.singleton('a');
  final b = new Finite.singleton('b');
  final c = new Finite.singleton('b');
  expect((empty + empty).card, equals(0));
  expect((empty + a).card, equals(1));
  expect((a + empty).card, equals(1));
  expect((a + b).card, equals(2));
  expect(((a + b) + c).card, equals(3));
  expect((a + (b + c)).card, equals(3));
}

void testCardinalOfProd() {
  final empty = new Finite.empty();
  final a = new Finite.singleton('a');
  final b = new Finite.singleton('b');
  final ab = a + b;
  expect((empty * empty).card, equals(0));
  expect((empty * a).card, equals(0));
  expect((a * empty).card, equals(0));
  expect((a * b).card, equals(1));
  expect((ab * a).card, equals(2));
  expect((a * ab).card, equals(2));
  expect((ab * ab).card, equals(4));
  expect(((ab * ab) * ab).card, equals(8));
  expect((ab * (ab * ab)).card, equals(8));
}

void testCardinalOfMap() {
  final empty = new Finite.empty();
  final a = new Finite.singleton(1);
  final b = new Finite.singleton(2);
  void checkUnchanged(Finite fin, Function f) {
    expect(fin.map(f).card, equals(fin.card));
  }
  checkUnchanged(empty, (int n) => n + 1);
  checkUnchanged(a, (int n) => n + 1);
  checkUnchanged(a + b, (int n) => n + 1);
  checkUnchanged((a + b) * a, (Pair p) => p.fst + p.snd);
}

void testCardinalOfApply() {
  final empty = new Finite.empty();
  final fun1 = new Finite.singleton((int n) => n + 1);
  final fun2 = new Finite.singleton((int n) => n + 2);
  final one = new Finite.singleton(1);
  final two = new Finite.singleton(2);
  expect(empty.apply(one).card, equals(0));
  expect(empty.apply(one + two).card, equals(0));
  expect(fun1.apply(one).card, equals(1));
  expect(fun1.apply(one +  two).card, equals(2));
  expect((fun1 + fun2).apply(one).card, equals(2));
  expect((fun1 + fun2).apply(one + two).card, equals(4));
}

void testIndexEmpty() {
  final empty = new Finite.empty();
  for (int i = 0; i < 100; i++) {
    expectThrow(() => empty[i], (e) => e is RangeError);
  }
}

void testIndexSingleton() {
  final foo = new Finite.singleton('foo');
  expect(foo[0], equals('foo'));
  for (int i = 1; i < 100; i++) {
    expectThrow(() => foo[i], (e) => e is RangeError);
  }
}

void testIndexSum() {
  final foo = new Finite.singleton('foo');
  final bar = new Finite.singleton('bar');
  final baz = new Finite.singleton('baz');

  final sum1 = (foo + bar) + baz;
  final sum2 = foo + (bar + baz);

  for (final sum in [sum1, sum2]) {
    expect(sum[0], equals('foo'));
    expect(sum[1], equals('bar'));
    expect(sum[2], equals('baz'));
    for (int i = 3; i < 100; i++) {
      expectThrow(() => sum[i], (e) => e is RangeError);
    }
  }
}

void testIndexProd() {
  final foo = new Finite.singleton('foo');
  final bar = new Finite.singleton('bar');

  final prod = (foo + bar) * (foo + bar);

  expect(prod[0].fst, equals('foo'));
  expect(prod[0].snd, equals('foo'));
  expect(prod[1].fst, equals('foo'));
  expect(prod[1].snd, equals('bar'));
  expect(prod[2].fst, equals('bar'));
  expect(prod[2].snd, equals('foo'));
  expect(prod[3].fst, equals('bar'));
  expect(prod[3].snd, equals('bar'));
  for (int i = 4; i < 100; i++) {
    expectThrow(() => prod[i], (e) => e is RangeError);
  }
}

void testIndexMap() {
  final fin = new Finite.singleton(1)
            + new Finite.singleton(2)
            + new Finite.singleton(3);
  final finDoubled = fin.map((int n) => n * 2);
  expect(finDoubled[0], equals(2));
  expect(finDoubled[1], equals(4));
  expect(finDoubled[2], equals(6));
  for (int i = 3; i < 100; i++) {
    expectThrow(() => finDoubled[i], (e) => e is RangeError);
  }
}

void testIndexApply() {
  final fs = new Finite.singleton((int n) => n * 2)
           + new Finite.singleton((int n) => n * 3);
  final xs = new Finite.singleton(1)
           + new Finite.singleton(2);
  final applied = fs.apply(xs);
  expect(applied[0], equals(2));
  expect(applied[1], equals(4));
  expect(applied[2], equals(3));
  expect(applied[3], equals(6));
  for (int i = 4; i < 100; i++) {
    expectThrow(() => applied[i], (e) => e is RangeError);
  }
}

void main() {
  test('card(empty) == 0',
       () => expect(new Finite.empty().card, equals(0)));
  test('card(singleton(foo)) == 1',
       () => expect(new Finite.singleton('foo').card, equals(1)));
  test('card(a + b) = card(a) + card(b)',
       testCardinalOfSum);
  test('card(a * b) = card(a) * card(b)',
       testCardinalOfProd);
  test('card(a.map(f)) == card(a)',
       testCardinalOfMap);
  test('card(a.apply(b)) == card(a) * card(b)',
       testCardinalOfApply);
  test('empty[i] throws exception',
       testIndexEmpty);
  test('singleton[i] behaves as expected',
       testIndexSingleton);
  test('(a + b)[i] behaves as expected',
       testIndexSum);
  test('(a * b)[i] behaves as expected',
       testIndexProd);
  test('a.map(f)[i] behaves as expected',
       testIndexMap);
  test('a.apply(b)[i] behaves as expected',
       testIndexApply);
}
