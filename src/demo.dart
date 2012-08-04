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

/** demo **/

listsOfBools() {
  // definition of the booleans' enumerator
  final trueEnum = singleton(true);
  final falseEnum = singleton(false);
  final boolEnum = (trueEnum + falseEnum).pay();
  final testEnum = fix((e) => (trueEnum + e.map((x) => new Leaf(x))).pay());

  // definition of the lists of booleans' enumerator
  final nilEnum = singleton(new Nil());
  consEnum(e) =>
      singleton((x) => (xs) => new Cons(x, xs)).apply(boolEnum).apply(e);
  final listEnum = fix((e) => (nilEnum + consEnum(e)).pay());

  // the enumerator iterates over finite sets of lists of booleans, the first
  // set contains exactly the lists made of 1 constructor (i.e. nil), the
  // second set the lists made of 2 constructors (there aren't any), etc.
  var counter = 0;
  listEnum.parts.take(10).forEach((f) {
    print("all the lists made of $counter constructors: $f");
    counter++;
  });

  // we can access big lists pretty fast
  final trues = listEnum.parts[81][0];
  print("the first list made of 40 elements (81 constructors): $trues");

  // we can access the nth list of the enumeration very fast, even for big ns
  print("member 10^10 of the enumeration: ${listEnum[Math.pow(10,10)]}");
}

treesOfNaturals() {
  // enumeration of the naturals
  final zeroEnum = singleton(0);
  succEnum(e) => singleton((n) => n + 1).apply(e);
  final natEnum = fix((e) => (zeroEnum + succEnum(e)).pay());

  // enumeration of the trees of naturals
  final leafEnum = singleton((n) => new Leaf(n)).apply(natEnum);
  forkEnum(e) => singleton((l) => (r) => new Fork(l, r)).apply(e).apply(e);
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
  listsOfBools();
  print("");
  treesOfNaturals();
}
