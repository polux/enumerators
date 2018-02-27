// Copyright (c) 2014, Google Inc. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

// Author: Paul Brauner (polux@google.com)

import 'dart:math';
import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:enumerators/combinators.dart' as c;

class IterationBenchmark extends BenchmarkBase {
  final listsOfNats = c.listsOf(c.nats);

  IterationBenchmark() : super("Random access over lists of nats");

  static void main() {
    new IterationBenchmark().report();
  }

  void run() {
    for (final part in listsOfNats.parts.skip(500).take(20)) {
      part[part.length ~/ PI];
    }
  }
}

main() {
  IterationBenchmark.main();
}
