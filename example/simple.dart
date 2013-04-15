// Copyright (c) 2012, Google Inc. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

// Author: Paul Brauner (polux@google.com)

library simple;
import 'package:enumerators/combinators.dart' as c;

main() {
  // c.strings is an enumeration: a infinite list of finite parts
  // part 0 contains the strings of size 0, part 1 the strings of size 1, etc.
  final strings20 = c.strings.parts[20];

  // we have fast access to the cardinal of a part
  final n = (strings20.length * 0.123).toInt();

  // as well as fast access to the nth element of a part
  print("the ${n}th string of size 20: ${strings20[n]}");

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
