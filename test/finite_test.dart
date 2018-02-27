// Copyright (c) 2012, Google Inc. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

// Author: Paul Brauner (polux@google.com)

import 'package:enumerators/enumerators.dart';
import 'package:unittest/unittest.dart';

void testCardinalOfSum() {
  final empty = new Finite.empty();
  final a = new Finite.singleton('a');
  final b = new Finite.singleton('b');
  final c = new Finite.singleton('b');
  expect((empty + empty).length, equals(0));
  expect((empty + a).length, equals(1));
  expect((a + empty).length, equals(1));
  expect((a + b).length, equals(2));
  expect(((a + b) + c).length, equals(3));
  expect((a + (b + c)).length, equals(3));
}

void testCardinalOfProd() {
  final empty = new Finite.empty();
  final a = new Finite.singleton('a');
  final b = new Finite.singleton('b');
  final ab = a + b;
  expect((empty * empty).length, equals(0));
  expect((empty * a).length, equals(0));
  expect((a * empty).length, equals(0));
  expect((a * b).length, equals(1));
  expect((ab * a).length, equals(2));
  expect((a * ab).length, equals(2));
  expect((ab * ab).length, equals(4));
  expect(((ab * ab) * ab).length, equals(8));
  expect((ab * (ab * ab)).length, equals(8));
}

void testCardinalOfMap() {
  final empty = new Finite.empty();
  final a = new Finite.singleton(1);
  final b = new Finite.singleton(2);
  void checkUnchanged(Finite fin, Function f) {
    expect(fin.map(f).length, equals(fin.length));
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
  expect(empty.apply(one).length, equals(0));
  expect(empty.apply(one + two).length, equals(0));
  expect(fun1.apply(one).length, equals(1));
  expect(fun1.apply(one + two).length, equals(2));
  expect((fun1 + fun2).apply(one).length, equals(2));
  expect((fun1 + fun2).apply(one + two).length, equals(4));
}

void testIndexEmpty() {
  final empty = new Finite.empty();
  for (int i = 0; i < 100; i++) {
    expect(() => empty[i], throwsA(new isInstanceOf<RangeError>()));
  }
}

void testIndexSingleton() {
  final foo = new Finite.singleton('foo');
  expect(foo[0], equals('foo'));
  for (int i = 1; i < 100; i++) {
    expect(() => foo[i], throwsA(new isInstanceOf<RangeError>()));
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
      expect(() => sum[i], throwsA(new isInstanceOf<RangeError>()));
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
    expect(() => prod[i], throwsA(new isInstanceOf<RangeError>()));
  }
}

void testIndexMap() {
  final fin = new Finite.singleton(1) +
      new Finite.singleton(2) +
      new Finite.singleton(3);
  final finDoubled = fin.map((int n) => n * 2);
  expect(finDoubled[0], equals(2));
  expect(finDoubled[1], equals(4));
  expect(finDoubled[2], equals(6));
  for (int i = 3; i < 100; i++) {
    expect(() => finDoubled[i], throwsA(new isInstanceOf<RangeError>()));
  }
}

void testIndexApply() {
  final fs = new Finite.singleton((int n) => n * 2) +
      new Finite.singleton((int n) => n * 3);
  final xs = new Finite.singleton(1) + new Finite.singleton(2);
  final applied = fs.apply(xs);
  expect(applied[0], equals(2));
  expect(applied[1], equals(4));
  expect(applied[2], equals(3));
  expect(applied[3], equals(6));
  for (int i = 4; i < 100; i++) {
    expect(() => applied[i], throwsA(new isInstanceOf<RangeError>()));
  }
}

void testIterator1() {
  expect(new Finite.empty().toList(), equals([]));
}

void testIterator2() {
  final fin = new Finite.singleton(1) +
      new Finite.singleton(2) +
      new Finite.singleton(3);
  expect(fin.toList(), equals([1, 2, 3]));
}

void testIsEmpty() {
  final _42 = new Finite.singleton(42);
  expect(new Finite.empty().isEmpty, isTrue);
  expect(_42.isEmpty, isFalse);
  expect((_42 + _42).isEmpty, isFalse);
  expect((_42 * _42).isEmpty, isFalse);
  expect(_42.map((x) => x + 1).isEmpty, isFalse);
}

void testFirst() {
  final _42 = new Finite.singleton(42);
  final _43 = new Finite.singleton(43);
  expect(
      () => new Finite.empty().first, throwsA(new isInstanceOf<StateError>()));
  expect(_42.first, equals(42));
  expect((_42 + _43).first, equals(42));
  expect((_42 * _43).first, equals(new Pair(42, 43)));
  expect(_42.map((x) => x + 5).first, equals(47));
}

void testLast() {
  final _42 = new Finite.singleton(42);
  final _43 = new Finite.singleton(43);
  expect(
      () => new Finite.empty().last, throwsA(new isInstanceOf<StateError>()));
  expect(_42.last, equals(42));
  expect((_42 + _43).last, equals(43));
  expect((_42 * _43).last, equals(new Pair(42, 43)));
  expect(_42.map((x) => x + 5).last, equals(47));
}

void main() {
  test(
      'length(empty) == 0', () => expect(new Finite.empty().length, equals(0)));
  test('length(singleton(foo)) == 1',
      () => expect(new Finite.singleton('foo').length, equals(1)));
  test('length(a + b) = length(a) + length(b)', testCardinalOfSum);
  test('length(a * b) = length(a) * length(b)', testCardinalOfProd);
  test('length(a.map(f)) == length(a)', testCardinalOfMap);
  test('length(a.apply(b)) == length(a) * length(b)', testCardinalOfApply);
  test('empty[i] throws exception', testIndexEmpty);
  test('singleton[i] behaves as expected', testIndexSingleton);
  test('(a + b)[i] behaves as expected', testIndexSum);
  test('(a * b)[i] behaves as expected', testIndexProd);
  test('a.map(f)[i] behaves as expected', testIndexMap);
  test('a.apply(b)[i] behaves as expected', testIndexApply);
  test('{}.toList() == []', testIterator1);
  test('{1,2,3}.toList() == [1,2,3]', testIterator2);
  test('isEmpty behaves as expected', testIsEmpty);
  test('first behaves as expected', testFirst);
  test('last behaves as expected', testFirst);
}
