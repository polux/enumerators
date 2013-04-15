// Copyright (c) 2012, Google Inc. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

// Author: Paul Brauner (polux@google.com)

library advanced;

import 'package:enumerators/enumerators.dart';

/** datatypes **/

class LList {}
class Nil extends LList {
  toString() => "nil";
}
class Cons extends LList {
  final x, xs;
  Cons(this.x, this.xs);
  toString() => "$x:$xs";
}

nil() => new Nil();
cons(x) => (xs) => new Cons(x,xs);

class Tree {}
class Leaf extends Tree {
  final x;
  Leaf(this.x);
  toString() => "Leaf($x)";
}
class Fork extends Tree {
  final l, r;
  Fork(this.l, this.r);
  toString() => "Fork($l, $r)";
}

leaf(x) => new Leaf(x);
fork(t1) => (t2) => new Fork(t1, t2);

/** utils **/

// the VM's Math.pow doesn't support big ints yet
int pow(n, p) {
  int res = 1;
  for (int i = 0; i < p; i++) {
    res *= n;
  }
  return res;
}

/** demos **/

listsOfBools() {
  // we define an enumerator of booleans
  final trueEnum = singleton(true);
  final falseEnum = singleton(false);
  final boolEnum = (trueEnum + falseEnum).pay();

  // we define an enumerator of list of booleans
  final nilEnum = singleton(nil());
  consEnum(e) => singleton(cons).apply(boolEnum).apply(e);
  final listEnum = fix((e) => (nilEnum + consEnum(e)).pay());

  // listEnum is made of finite sets of lists of booleans (parts), the first
  // part contains exactly the lists made of 1 constructor (i.e. nil), the
  // second part the lists made of 2 constructors (there aren't any), etc.
  var counter = 0;
  listEnum.parts.take(10).forEach((f) {
    print("all the lists made of $counter constructors: $f");
    counter++;
  });

  // we can access big parts pretty fast
  final trues = listEnum.parts[81][0];
  print("the first list made of 40 elements (81 constructors): $trues");

  // toLazyList() iterates over the enumeration as a whole, seen as a
  // concatenation of its parts
  counter = 0;
  listEnum.take(10).forEach((l) {
    print("list of booleans #$counter: $l");
    counter++;
  });

  // we can access the nth list of the enumeration very fast, even for big ns
  print("member 10^500 of the enumeration: ${listEnum[pow(10,500)]}");
}

treesOfNaturals() {
  // enumeration of the naturals
  final zeroEnum = singleton(0);
  succEnum(e) => singleton((n) => n + 1).apply(e);
  final natEnum = fix((e) => (zeroEnum + succEnum(e)).pay());

  // enumeration of the trees of naturals
  final leafEnum = singleton(leaf).apply(natEnum);
  forkEnum(e) => singleton(fork).apply(e).apply(e);
  final treeEnum = fix((e) => (leafEnum + forkEnum(e)).pay());

  // the set made of naturals of size 15 is {15}
  print("the 15th natural: ${natEnum[15]}");

  // remember that a natural n is "of size" n
  var counter = 0;
  treeEnum.parts.take(10).forEach((f) {
    print("all the trees of size $counter: $f");
    counter++;
  });

  // computation of a part's cardinality is fast
  final cardOf50 = treeEnum.parts[50].length;
  print("there are $cardOf50 trees of size 50");
  // the first tree of the 50th set is Leaf(48), which is boring, but at the
  // middle of the set, we can get a pretty deep one
  print("a deep tree: ${treeEnum.parts[50][cardOf50 ~/ 2]}");

  // again, finding the nth member of the enumeration is fast, even for big ns
  print("a random tree: ${treeEnum[pow(10,100)]}");
}

main() {
  listsOfBools();
  print("");
  treesOfNaturals();
}
