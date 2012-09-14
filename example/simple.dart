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

#library('simple');

#import('package:dart_enumerators/enumerators.dart');
#import('package:dart_enumerators/combinators.dart');

main() {
  // ideally, Combinators is a module but the VM doesn't support lazy
  // initialization of toplevel variables yet
  final c = new Combinators();

  // c.strings is an enumeration: a infinite list of finite parts
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
