// Copyright (c) 2012, Google Inc. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'package:enumerators/enumerators.dart' as e;

e.Finite singleton(x) => new e.Finite.singleton(x);
e.Finite empty() => new e.Finite.empty();

abstract class Term {
  String pretty(int n);
  String toString() => pretty(0);
  e.Finite<Term> expand(int n);
}

class Lam extends Term {
  final Term t;
  Lam(this.t);
  String pretty(int n) => "\\x$n -> ${t.pretty(n+1)}";
  e.Finite<Term> expand(int n) => t.expand(n+1).map(lam);
}

class App extends Term {
  final Term t1, t2;
  App(this.t1, this.t2);
  String pretty(int n) => "(${t1.pretty(n)}) (${t2.pretty(n)})";
  e.Finite<Term> expand(int n) =>
      singleton(app).apply(t1.expand(n)).apply(t2.expand(n));
}

class LVar extends Term {
  final int index;
  LVar(this.index);
  String pretty(int n) => "x${n - index - 1}";
  e.Finite<Term> expand(int n) => singleton(this);
}

class Hole extends Term {
  String pretty(_) => "*";
  e.Finite<Term> expand(int n) {
    var res = empty();
    for (int i = 0; i < n; i++) {
      res = res + singleton(lvar(i));
    }
    return res;
  }
}

typedef Term Term2Term(Term);

Term lam(Term t) => new Lam(t);
Term2Term app(Term t1) => (Term t2) => new App(t1, t2);
Term lvar(int i) => new LVar(i);
final Term hole = new Hole();

final holes = e.singleton(hole);
apps(t) => e.singleton(app).apply(t).apply(t);
lams(t) => t.map(lam);
final skeletons = e.fix((t) => (holes + apps(t) + lams(t)).pay());
final e.Enumeration<e.Finite<Term>> preterms =
    skeletons.map((t) => t.expand(0));

Term term(int i) {
  e.LazyList<e.Finite<Term>> fs = preterms.toLazyList();
  while (true) {
    final e.Finite<Term> f = fs.head;
    if (i < f.length) return f[i];
    i -= f.length;
    fs = fs.tail;
  }
}

main() {
  print(term(123456));
}
