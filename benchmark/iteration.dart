import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:enumerators/combinators.dart' as c;

class IterationBenchmark extends BenchmarkBase {
  final listsOfNats = c.listsOf(c.nats);

  const IterationBenchmark() : super("Iteration over lists of nats");

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