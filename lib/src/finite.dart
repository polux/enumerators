part of enumerators;

class _Instruction {}

class _IDone implements _Instruction {
}

class _IMap implements _Instruction {
  final fun;
  _IMap(this.fun);
}

class _IPair2 implements _Instruction {
  final snd;
  _IPair2(this.snd);
}

class _IPair1 implements _Instruction {
  final Finite fin2;
  final r;
  _IPair1(this.fin2, this.r);
}

class _Operation {}

class _OAdd implements _Operation {
  final Finite fin1;
  final Finite fin2;
  _OAdd(this.fin1, this.fin2);
}

class _OEmpty implements _Operation {
}

class _OMult implements _Operation {
  final Finite fin1;
  final Finite fin2;
  _OMult(this.fin1, this.fin2);
}

class _OSingleton implements _Operation {
  final val;
  _OSingleton(this.val);
}

class _OMap implements _Operation {
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
        if (op is _OAdd) {
          if (index < op.fin1.length) {
            op = op.fin1.op;
          } else {
            final f1 = op.fin1;
            op = op.fin2.op;
            index = index - f1.length;
          }
        } else if (op is _OEmpty) {
          throw new RangeError(index);
        } else if (op is _OMult) {
          int q = index ~/ op.fin2.length;
          int r = index % op.fin2.length;
          index = q;
          stack.add(new _IPair1(op.fin2, r));
          op = op.fin1.op;
        } else if (op is _OSingleton) {
          if (index == 0) {
            val = op.val;
            evalOp = false;
          } else {
            throw new RangeError(index);
          }
        } else if (op is _OMap) {
          stack.add(new _IMap(op.fun));
          op = op.fin.op;
        }
      } else {
        final instr = stack.removeLast();
        if (instr is _IDone) {
          return val;
        } else if (instr is _IMap) {
          val = instr.fun(val);
        } else if (instr is _IPair2) {
          val = new Pair(instr.snd, val);
        } else if (instr is _IPair1) {
          op = instr.fin2.op;
          index = instr.r;
          stack.add(new _IPair2(val));
          evalOp = true;
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