part of symbol_table;

/// Represents the visibility of a symbol.
///
/// Symbols may be [public], [protected], or [private].
/// The significance of a symbol's visibility is semantic and specific to the interpreter/compiler;
/// this package attaches no specific meaning to it.
///
/// [Visibility] instances can be compared using the `<`, `<=`, `>`, and `>=` operators.
/// The evaluation of the aforementioned operators is logical;
/// for example, a [private] symbol is *less visible* than a [public] symbol,
/// so [private] < [public].
///
/// In a nutshell: [private] < [protected] < [public].
class Visibility implements Comparable<Visibility> {
  static const Visibility private = const Visibility._(0);
  static const Visibility protected = const Visibility._(1);
  static const Visibility public = const Visibility._(2);
  final int _n;
  const Visibility._(this._n);

  bool operator >(Visibility other) => _n > other._n;
  bool operator >=(Visibility other) => _n >= other._n;
  bool operator <(Visibility other) => _n < other._n;
  bool operator <=(Visibility other) => _n <= other._n;

  @override
  int compareTo(Visibility other) {
    return _n.compareTo(other._n);
  }
}
