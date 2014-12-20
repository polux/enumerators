// Copyright (c) 2014, Google Inc. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

// Author: Paul Brauner (polux@google.com)

library linked_list;

abstract class LList {
  bool isEmpty();

  List toList() {
    var res = [];
    var it = this;
    while (!it.isEmpty()) {
      Cons cons = it;
      res.add(cons.x);
      it = cons.xs;
    }
    return res;
  }
}

class Nil extends LList {
  toString() => "nil";
  isEmpty() => true;
}

class Cons extends LList {
  final x, xs;
  Cons(this.x, this.xs);
  toString() => "$x:$xs";
  isEmpty() => false;
}

final nil = new Nil();
cons(x, xs) => new Cons(x, xs);
