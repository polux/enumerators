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

#import('combinators.dart');

finiteFromList(l) => new Finite(l.length, (i) => l[i]);
lazyListFromList(l) {
  aux(i) => (i == l.length) 
      ? new LazyList.empty()
      : new LazyList(() => new Pair(l[i], aux(i+1)));
  return aux(0);
}

interface Nat {}
class Z implements Nat { const Z(); toString() => "Z"; }
class S implements Nat { Nat pred; S(this.pred); toString() => "S($pred)"; }

final z = const Z();
s(x) => new S(x);
pair(x) => (y) => new Pair(x,y);

void main() {
  final f1 = finiteFromList([z,s(z),s(s(z))]);
  final f2 = finiteFromList([4,5,6]);
  print(f1 + f2);
  print((f1 * f1 * f2 * f1 * f2 * f1 * f2 * f1 * f1)[100]);
  print(f1.map(pair).apply(f2));
  final s1 = lazyListFromList([1,2,3]);
  print(s1);
  print(s1 + s1);
  print(s1 * s1 * s1);
  print(lazyListFromList([s1,s1,s1]).concat());
  final e = new Enumeration(lazyListFromList([f1,f1.map(s)]));
  print(e);
  for (int i = 0; i < 6; i++) print(e[i]);
  final e2 = new Enumeration(lazyListFromList([f1.map(s), f1, f1 + f1]));
  print(e + e2);
  print(e2 + e);
  print((e + e).map(s));
  print(lazyListFromList([1,2,3]).foldLeft(0, (a,b) => a + b));
  print(new LazyList.repeat(1).map((n) => n+1).take(10));
  print(lazyListFromList([1,2,3,4,5]).tails());
  print((e * e2).parts.take(10));
}