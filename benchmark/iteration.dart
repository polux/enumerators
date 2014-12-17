// Copyright (c) 2014, Google Inc. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

// Author: Paul Brauner (polux@google.com)

import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:enumerators/combinators.dart' as c;

class IterationBenchmark extends BenchmarkBase {
  final listsOfNats = c.listsOf(c.nats);

  IterationBenchmark() : super("Iteration over lists of nats");

  static void main() {
    new IterationBenchmark().report();
  }

  void run() {
    for (final part in listsOfNats.parts.take(10)) {
      for (final list in part) {
      }
    }
  }
}

main() {
  IterationBenchmark.main();
}