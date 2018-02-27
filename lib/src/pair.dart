// Copyright (c) 2014, Google Inc. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

// Author: Paul Brauner (polux@google.com)

library pair;

class Pair<A, B> {
  final A fst;
  final B snd;

  Pair(this.fst, this.snd);

  Pair<A, B> setFst(A x) => new Pair<A, B>(x, snd);

  Pair<A, B> setSnd(B x) => new Pair<A, B>(fst, x);

  int get hashCode => 31 * fst.hashCode + snd.hashCode;

  bool operator ==(Object other) {
    return (other is Pair<A, B>) && (fst == other.fst) && (snd == other.snd);
  }

  toString() => "($fst, $snd)";
}
