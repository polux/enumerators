part of enumerators;

class _Instruction {}
class _IProd extends _Instruction {}
class _IMap extends _Instruction {
  final Function f;
  _IMap(this.f);
}
class _IEval extends _Instruction {
  final Finite fin;
  final int i;
  _IEval(this.fin, this.i);
  toString() => "eval($fin, $i)";
}

abstract class Finite<A> extends IterableBase<A> {
  Finite();
  factory Finite.empty() => new _FEmpty();
  factory Finite.singleton(A x) => new _FSingleton(x);

  /**
   * Union.
   */
  Finite<A> operator +(Finite<A> fin) => new _FSum(this, fin);

  /**
   * Cartesian product.
   */
  Finite<Pair> operator *(Finite fin) => new _FProd(this, fin);

  /**
   * [Finite] is a functor.
   */
  Finite map(f(A x)) => new _FMap(f, this);

  /**
   * [Finite] is an applicative functor.
   */
  Finite apply(Finite fin) =>
      (this * fin).map((pair) => (pair.fst as Function)(pair.snd));

  A operator [](int index) => _eval(this, index);

  static _eval(Finite finite, int index) {
    final instructions = <_Instruction>[new _IEval(finite, index)];
    final stack = [];
    while (instructions.length > 0) {
      _Instruction instr = instructions.removeLast();
      if (instr is _IEval) {
        final i = instr.i;
        final fin = instr.fin;
        if (fin is _FEmpty) {
          throw new RangeError(index);
        } else if (fin is _FSingleton) {
          if (i == 0)
            stack.add(fin.value);
          else
            throw new RangeError(index);
        } else if (fin is _FSum) {
          if (i < fin.fin1.length)
            instructions.add(new _IEval(fin.fin1, i));
          else
            instructions.add(new _IEval(fin.fin2, i - fin.fin1.length));
        } else if (fin is _FProd) {
          instructions.add(new _IProd());
          instructions.add(new _IEval(fin.fin1, i ~/ fin.fin2.length));
          instructions.add(new _IEval(fin.fin2, i % fin.fin2.length));
        } else if (fin is _FMap) {
          instructions.add(new _IMap(fin.f));
          instructions.add(new _IEval(fin.mapped, i));
        }
      } else if (instr is _IProd) {
        final v1 = stack.removeLast();
        final v2 = stack.removeLast();
        stack.add(new Pair(v1, v2));
      } else if (instr is _IMap) {
        final v = stack.removeLast();
        stack.add(instr.f(v));
      }
    }
    return stack[0];
  }

  String toString() {
    final strings = toLazyList().map((f) => f.toString()).toList();
    return "{${strings.join(", ")}}";
  }

  Iterator<A> get iterator => new _FiniteIterator<A>(this);

  LazyList<A> toLazyList() {
    aux(i) => (i == this.length)
        ? new LazyList.empty()
        : new LazyList.cons(this[i], () => aux(i+1));
    return aux(0);
  }

  // optimized Iterable methods

  bool get isEmpty => length == 0;

  A elementAt(int index) => this[index];

  A get first {
    if (isEmpty) {
      throw new StateError('Cannot access first element of an empty set.');
    }
    return this[0];
  }

  A get last {
    if (isEmpty) {
      throw new StateError('Cannot access last element of an empty set.');
    }
    return this[length - 1];
  }
}

class _FEmpty<A> extends Finite<A> {
  final int length = 0;
  final bool isEmpty = true;
  _FEmpty();
}

class _FSingleton<A> extends Finite<A> {
  final int length = 1;
  final bool isEmpty = false;
  final A value;
  _FSingleton(this.value);
}

class _FSum<A> extends Finite<A> {
  final int length;
  final Finite<A> fin1;
  final Finite<A> fin2;
  _FSum(fin1, fin2)
      : this.fin1 = fin1
      , this.fin2 = fin2
      , length = fin1.length + fin2.length;
}

class _FProd<A> extends Finite<A> {
  final int length;
  final Finite<A> fin1;
  final Finite<A> fin2;
  _FProd(fin1, fin2)
      : this.fin1 = fin1
      , this.fin2 = fin2
      , length = fin1.length * fin2.length;
}

class _FMap<A,B> extends Finite<B> {
  final int length;
  final Function f;
  final Finite<A> mapped;
  _FMap(B f(A x), Finite<A> mapped)
      : this.f = f
      , this.mapped = mapped
      , length = mapped.length;
}

class _FiniteIterator<A> extends Iterator<A> {
  final Finite<A> finite;
  int index = -1;
  A current = null;

  _FiniteIterator(this.finite);

  bool moveNext() {
    if (index == finite.length) return false;

    index++;
    if (index == finite.length) {
      current = null;
      return false;
    } else {
      current = finite[index];
      return true;
    }
  }
}