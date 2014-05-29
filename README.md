# Random Access Enumerations

[![Build Status](https://drone.io/github.com/polux/enumerators/status.png)](https://drone.io/github.com/polux/enumerators/latest)

A library which allows for randomized or exhaustive testing of Dart functions
by providing random access enumerations of Dart datatypes. It is heavily
inspired by Jonas Duregård's
[testing-feat](http://hackage.haskell.org/package/testing-feat).

Put simply, it allows to test things like `reverse(reverse(list)) == list` by
picking, say, 100 random lists of booleans for `list`
([quickcheck](http://hackage.haskell.org/package/QuickCheck) style), or by
enumerating all the lists of booleans up to a certain depth
([smallcheck](http://hackage.haskell.org/package/smallcheck) style). It is
however up to the user to provide the glorified while loops that constitute the
"quickcheck" and "smallcheck" functions of these libraries. The
[propcheck](http://pub.dartlang.org/packages/propcheck) library just does that.

## Documentation

The only documentation so far is this README and the [API reference](http://goo.gl/UZX3qD).

## Simple Usage

The `combinators.dart` library provides a predefined set of combinators for the
most common use cases:

```dart
import 'package:enumerators/combinators.dart' as 'c';

main() {
  // c.strings is an enumeration: a infinite list of finite parts
  // part 0 contains the strings of size 0, part 1 the strings of size 1,
  // etc.
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

  // setsOf is a combinator: it takes an Enumeration and returns an
  // Enumeration
  print("a set of strings: ${c.setsOf(c.strings)[123456789]}");

  // we can arbitrarily nest combinators
  print("a map from nats to lists of ints: "
        "${c.mapsOf(c.nats, c.listsOf(c.ints))[123456789]}");
}
```

Output:

```
the 2451162314110757454221410304th string of size 20: dfdwbglqwbgmgvzcwrqm
the 71468th string: dart
the ints of size 200: {200, -200}
a set of strings: {e, , n, m, v, ab, u, ac, f, t}
a map from nats to lists of ints: {1: [], 4: [0, 0, 0, -1, 1, 0], 5: [], 6: [-1]}
```

## Advanced Usage

The `enumerators.dart` library provides lower-level primitives for building
enumerations of user-defined datatypes.

```dart
import 'package:enumerators/enumerators.dart';

// we define linked lists as "Nil" and "Cons", as well as two curryfied
// shorthands "nil" and "cons" for their constructors

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

// here starts the real demo

main() {
  // we define an enumerator of booleans
  final trueEnum = singleton(true);
  final falseEnum = singleton(false);
  final boolEnum = (trueEnum + falseEnum).pay();

  // we define an enumerator of lists of booleans
  final nilEnum = singleton(nil());
  consEnum(e) => singleton(cons).apply(boolEnum).apply(e);
  final listEnum = fix((e) => (nilEnum + consEnum(e)).pay());

  // listEnum is made of finite sets of lists of booleans (parts), the
  // first part contains exactly the lists made of 1 constructor
  // (i.e. nil), the second part the lists made of 2 constructors (there
  // aren't any), etc.
  var counter = 0;
  for (final f in listEnum.parts.take(10)) {
    print("all the lists made of $counter constructors: $f");
    counter++;
  }

  // we can access big parts pretty fast
  final trues = listEnum.parts[81][0];
  print("the first list made of 40 elements (81 constructors): $trues");

  // an enumeration can be iterated over as a whole,
  // as a concatenation of its parts
  counter = 0;
  for (final l in listEnum.take(10)) {
    print("list of booleans #$counter: $l");
    counter++;
  }

  // we can access the nth list of the enumeration very fast, even for
  // big ns
  print("member 10^10 of the enumeration: ${listEnum[Math.pow(10,10)]}");
}
```

Output:

```
all the lists made of 0 constructors: {}
all the lists made of 1 constructors: {nil}
all the lists made of 2 constructors: {}
all the lists made of 3 constructors: {true:nil, false:nil}
all the lists made of 4 constructors: {}
all the lists made of 5 constructors: {true:true:nil, true:false:nil, false:true:nil, false:false:nil}
all the lists made of 6 constructors: {}
all the lists made of 7 constructors: {true:true:true:nil, true:true:false:nil, true:false:true:nil, true:false:false:nil, false:true:true:nil, false:true:false:nil, false:false:true:nil, false:false:false:nil}
all the lists made of 8 constructors: {}
all the lists made of 9 constructors: {true:true:true:true:nil, true:true:true:false:nil, true:true:false:true:nil, true:true:false:false:nil, true:false:true:true:nil, true:false:true:false:nil, true:false:false:true:nil, true:false:false:false:nil, false:true:true:true:nil, false:true:true:false:nil, false:true:false:true:nil, false:true:false:false:nil, false:false:true:true:nil, false:false:true:false:nil, false:false:false:true:nil, false:false:false:false:nil}
the first list made of 40 elements (81 constructors): true:true:true:true:true:true:true:true:true:true:true:true:true:true:true:true:true:true:true:true:true:true:true:true:true:true:true:true:true:true:true:true:true:true:true:true:true:true:true:true:nil
list of booleans #0: nil
list of booleans #1: true:nil
list of booleans #2: false:nil
list of booleans #3: true:true:nil
list of booleans #4: true:false:nil
list of booleans #5: false:true:nil
list of booleans #6: false:false:nil
list of booleans #7: true:true:true:nil
list of booleans #8: true:true:false:nil
list of booleans #9: true:false:true:nil
member 10^10 of the enumeration: true:true:false:true:false:true:false:true:true:true:true:true:true:false:true:false:false:false:false:false:true:true:false:true:true:true:true:true:true:true:true:true:false:nil
```

The file `example/advanced.dart` contains the demo above as well as an
enumerator of trees of naturals.
