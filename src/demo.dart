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

#library('demo');
#import('enumerators.dart');
#import('combinators.dart');

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

/** demos **/

predefinedCombinators() {
  // ideally, Combinators is a module but the VM doesn't support lazy
  // initialization of toplevel variables yet
  final c = new Combinators();
  // strings is an enumeration: a infinite list of finite parts
  // part 0 contains the strings of size 0, part 1 the strings of size 1, etc.
  final strings = c.strings.parts[20];
  // we have fast access to the cardinal of a part
  final n = (strings.card * 0.123).toInt();
  // as well as fast access to the nth element of a part
  print("the ${n}th string of size 20: ${strings[n]}");
  // we quickly access the nth element of an enumeration seen as the
  // concatenation of its parts
  print("the 71468th string: ${c.strings[71468]}");
  // we can also print a part as a whole, but it might be huge
  print("the ints of size 200: ${c.ints.parts[200]}");
  // setsOf is a combinator: it takes an Enumeration and returns an Enumeration
  print("a set of strings: ${c.setsOf(c.strings)[123456789]}");
  // we can arbitrarily nest combinators
  print("a map from nats to lists of ints: "
        "${c.mapsOf(c.nats, c.listsOf(c.ints))[123456789]}");
}

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
  final trues = listEnum.parts[181][0];
  print("the first list made of 40 elements (81 constructors): $trues");

  // toLazyList() iterates over the enumeration as a whole, seen as a
  // concatenation of its parts
  counter = 0;
  listEnum.toLazyList().take(10).forEach((l) {
    print("list of booleans #$counter: $l");
    counter++;
  });

  // we can access the nth list of the enumeration very fast, even for big ns
  print("member 10^10 of the enumeration: ${listEnum[Math.pow(10,10)]}");
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
  final cardOf50 = treeEnum.parts[50].card;
  print("there are $cardOf50 trees of size 50");
  // the first tree of the 50th set is Leaf(48), which is boring, but at the
  // end of the set, we can get a pretty big one
  print("a deep tree: ${treeEnum.parts[50][cardOf50 - 1]}");

  // again, finding the nth member of the enumeration is fast, even for big ns
  print("a random tree: ${treeEnum[Math.pow(10,10)]}");
}

main() {
  predefinedCombinators();
  print("");
  listsOfBools();
  print("");
  treesOfNaturals();
}
