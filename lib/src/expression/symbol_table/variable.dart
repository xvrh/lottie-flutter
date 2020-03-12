part of symbol_table;

/// Holds an immutable symbol, the value of which is set once and only once.
@deprecated
class Constant<T> extends Variable<T> {
  Constant(String name, T value) : super._(name, null, value: value) {
    lock();
  }
}

/// Holds a symbol, the value of which may change or be marked immutable.
class Variable<T> {
  final String name;
  final SymbolTable<T> symbolTable;
  Visibility visibility = Visibility.public;
  bool _locked = false;
  T _value;

  Variable._(this.name, this.symbolTable, {T value}) {
    _value = value;
  }

  /// If `true`, then the value of this variable cannot be overwritten.
  bool get isImmutable => _locked;

  /// This flag has no meaning within the context of this library, but if you
  /// are implementing some sort of interpreter, you may consider acting based on
  /// whether a variable is private.
  @deprecated
  bool get isPrivate => visibility == Visibility.private;

  T get value => _value;

  void set value(T value) {
    if (_locked)
      throw new StateError(
          'The value of constant "$name" cannot be overwritten.');
    _value = value;
  }

  /// Locks this symbol, and prevents its [value] from being overwritten.
  void lock() {
    _locked = true;
  }

  /// Marks this symbol as private.
  @deprecated
  void markAsPrivate() {
    visibility = Visibility.private;
  }
}
