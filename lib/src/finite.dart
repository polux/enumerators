part of enumerators;

abstract class _Instruction {
  // Ideally we would switch/case on runtimeType but it's to slow for now
  int get tag;

  static const DONE = 0;
  static const MAP = 1;
  static const PAIR2 = 2;
  static const PAIR1 = 3;
}

class _IDone implements _Instruction {
  final tag = _Instruction.DONE;
}

class _IMap implements _Instruction {
  final tag = _Instruction.MAP;
  final fun;
  _IMap(this.fun);
}

class _IPair2 implements _Instruction {
  final tag = _Instruction.PAIR2;
  final snd;
  _IPair2(this.snd);
}

class _IPair1 implements _Instruction {
  final tag = _Instruction.PAIR1;
  final Finite fin2;
  final r;
  _IPair1(this.fin2, this.r);
}

abstract class _Operation {
  // Ideally we would switch/case on runtimeType but it's to slow for now
  int get tag;

  static const ADD = 0;
  static const EMPTY = 1;
  static const MULT = 2;
  static const SINGLETON = 3;
  static const MAP = 4;
}

class _OAdd implements _Operation {
  final tag = _Operation.ADD;
  final Finite fin1;
  final Finite fin2;
  _OAdd(this.fin1, this.fin2);
}

class _OEmpty implements _Operation {
  final tag = _Operation.EMPTY;
}

class _OMult implements _Operation {
  final tag = _Operation.MULT;
  final Finite fin1;
  final Finite fin2;
  _OMult(this.fin1, this.fin2);
}

class _OSingleton implements _Operation {
  final tag = _Operation.SINGLETON;
  final val;
  _OSingleton(this.val);
}

class _OMap implements _Operation {
  final tag = _Operation.MAP;
  final Finite fin;
  final Function fun;
  _OMap(this.fin, this.fun);
}

class Finite<A> extends IterableBase<A> {
  final int length;
  final _Operation op;

  Finite._(this.length, this.op);

  factory Finite.empty() => new Finite._(0, new _OEmpty());
  factory Finite.singleton(A x) => new Finite._(1, new _OSingleton(x));

  /**
   * Union.
   */
  Finite<A> operator +(Finite<A> fin) =>
      new Finite._(this.length + fin.length, new _OAdd(this, fin));

  /**
   * Cartesian product.
   */
  Finite<Pair> operator *(Finite fin) =>
      new Finite._(this.length * fin.length, new _OMult(this, fin));

  /**
   * [Finite] is a functor.
   */
  Finite map(f(A x)) => new Finite._(this.length, new _OMap(this, f));

  /**
   * [Finite] is an applicative functor.
   */
  Finite apply(Finite fin) =>
      (this * fin).map((pair) => (pair.fst as Function)(pair.snd));

  A operator [](int index) => _eval(this, index);

  static _eval(Finite finite, int index) {
    bool evalOp = true;

    var val;
    final stack = <_Instruction>[new _IDone()];
    var op = finite.op;

    while (true) {
      if (evalOp) {
        switch(op.tag) {
          case _Operation.ADD:
            if (index < op.fin1.length) {
              op = op.fin1.op;
            } else {
              final f1 = op.fin1;
              op = op.fin2.op;
              index = index - f1.length;
            }
            break;
          case _Operation.EMPTY:
            throw new RangeError(index);
            break;
          case _Operation.MULT:
            int q = index ~/ op.fin2.length;
            int r = index % op.fin2.length;
            index = q;
            stack.add(new _IPair1(op.fin2, r));
            op = op.fin1.op;
            break;
          case _Operation.SINGLETON:
            if (index == 0) {
              val = op.val;
              evalOp = false;
            } else {
              throw new RangeError(index);
            }
            break;
          case _Operation.MAP:
            stack.add(new _IMap(op.fun));
            op = op.fin.op;
            break;
        }
      } else {
        final instr = stack.removeLast();
        switch (instr.tag) {
          case _Instruction.DONE:
            return val;
          case _Instruction.MAP:
            val = instr.fun(val);
            break;
          case _Instruction.PAIR2:
            val = new Pair(instr.snd, val);
            break;
          case _Instruction.PAIR1:
            op = instr.fin2.op;
            index = instr.r;
            stack.add(new _IPair2(val));
            evalOp = true;
            break;
        }
      }
    }
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