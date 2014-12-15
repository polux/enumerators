part of enumerators;

class Pair<A,B> {
  final A fst;
  final B snd;

  Pair(this.fst, this.snd);

  Pair<A,B> setFst(A x) => new Pair<A,B>(x, snd);

  Pair<A,B> setSnd(B x) => new Pair<A,B>(fst, x);

  int get hashCode => 31 * fst.hashCode + snd.hashCode;

  bool operator ==(Pair<A,B> other) {
    return (other is Pair<A,B>)
        && (fst == other.fst)
        && (snd == other.snd);
  }

  toString() => "($fst, $snd)";
}
