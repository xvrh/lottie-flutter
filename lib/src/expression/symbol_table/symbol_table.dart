library symbol_table;

part 'variable.dart';
part 'visibility.dart';

/// A hierarchical mechanism to hold a set of variables, which supports scoping and constant variables.
class SymbolTable<T> {
  final List<SymbolTable<T>> _children = [];
  final Map<String, Variable<T>> _lookupCache = {};
  final Map<String, int> _names = {};
  final List<Variable<T>> _variables = [];
  int _depth = 0;
  T _context;
  SymbolTable<T> _parent, _root;

  /// Initializes an empty symbol table.
  ///
  /// You can optionally provide a [Map] of starter [values].
  SymbolTable({Map<String, T> values: const {}}) {
    if (values?.isNotEmpty == true) {
      values.forEach((k, v) {
        _variables.add(new Variable<T>._(k, this, value: v));
      });
    }
  }

  /// Returns the nearest context this symbol table belongs to. Returns `null` if none was set within the entire tree.
  ///
  /// This can be used to bind values to a `this` scope within a compiler.
  T get context {
    SymbolTable<T> search = this;

    while (search != null) {
      if (search._context != null) return search._context;
      search = search._parent;
    }

    return null;
  }

  /// Sets a local context for values within this scope to be resolved against.
  void set context(T value) {
    _context = value;
  }

  /// The depth of this symbol table within the tree. At the root, this is `0`.
  int get depth => _depth;

  /// Returns `true` if this scope has no parent.
  bool get isRoot => _parent == null;

  /// Gets the parent of this symbol table.
  SymbolTable<T> get parent => _parent;

  /// Resolves the symbol table at the very root of the hierarchy.
  ///
  /// This value is memoized to speed up future lookups.
  SymbolTable<T> get root {
    if (_root != null) return _root;

    SymbolTable<T> out = this;

    while (out._parent != null) out = out._parent;

    return _root = out;
  }

  /// Retrieves every variable within this scope and its ancestors.
  ///
  /// Variable names will not be repeated; this produces the effect of
  /// shadowed variables.
  ///
  /// This list is unmodifiable.
  List<Variable<T>> get allVariables {
    List<String> distinct = [];
    List<Variable<T>> out = [];

    void crawl(SymbolTable<T> table) {
      for (var v in table._variables) {
        if (!distinct.contains(v.name)) {
          distinct.add(v.name);
          out.add(v);
        }
      }

      if (table._parent != null) crawl(table._parent);
    }

    crawl(this);
    return new List<Variable<T>>.unmodifiable(out);
  }

  /// Helper for calling [allVariablesWithVisibility] to fetch all public variables.
  List<Variable<T>> get allPublicVariables {
    return allVariablesWithVisibility(Visibility.public);
  }

  /// Use [allVariablesWithVisibility] instead.
  @deprecated
  List<Variable<T>> allVariablesOfVisibility(Visibility visibility) {
    return allVariablesWithVisibility(visibility);
  }

  /// Retrieves every variable of the given [visibility] within this scope and its ancestors.
  ///
  /// Variable names will not be repeated; this produces the effect of
  /// shadowed variables.
  ///
  /// Use this to "export" symbols out of a library or class.
  ///
  /// This list is unmodifiable.
  List<Variable<T>> allVariablesWithVisibility(Visibility visibility) {
    List<String> distinct = [];
    List<Variable<T>> out = [];

    void crawl(SymbolTable<T> table) {
      for (var v in table._variables) {
        if (!distinct.contains(v.name) && v.visibility == visibility) {
          distinct.add(v.name);
          out.add(v);
        }
      }

      if (table._parent != null) crawl(table._parent);
    }

    crawl(this);
    return new List<Variable<T>>.unmodifiable(out);
  }

  Variable<T> operator [](String name) => resolve(name);

  void operator []=(String name, T value) {
    assign(name, value);
  }

  void _wipeLookupCache(String key) {
    _lookupCache.remove(key);
    _children.forEach((c) => c._wipeLookupCache(key));
  }

  /// Use [create] instead.
  @deprecated
  Variable<T> add(String name, {T value, bool constant}) {
    return create(name, value: value, constant: constant);
  }

  /// Create a new variable *within this scope*.
  ///
  /// You may optionally provide a [value], or mark the variable as [constant].
  Variable<T> create(String name, {T value, bool constant}) {
    // Check if it exists first.
    if (_variables.any((v) => v.name == name))
      throw new StateError(
          'A symbol named "$name" already exists within the current context.');

    _wipeLookupCache(name);
    Variable<T> v = new Variable._(name, this, value: value);
    if (constant == true) v.lock();
    _variables.add(v);
    return v;
  }

  /// Use [assign] instead.
  @deprecated
  Variable<T> put(String name, T value) {
    return assign(name, value);
  }

  /// Assigns a [value] to the variable with the given [name], or creates a new variable.
  ///
  /// You cannot use this method to assign constants.
  ///
  /// Returns the variable whose value was just assigned.
  Variable<T> assign(String name, T value) {
    return resolveOrCreate(name)..value = value;
  }

  /// Removes the variable with the given [name] from this scope, or an ancestor.
  ///
  /// Returns the deleted variable, or `null`.
  ///
  /// *Note: This may cause [resolve] calls in [fork]ed scopes to return `null`.*
  /// *Note: There is a difference between symbol tables created via [fork], [createdChild], and [clone].*
  Variable<T> remove(String name) {
    SymbolTable<T> search = this;

    while (search != null) {
      var variable = search._variables
          .firstWhere((v) => v.name == name, orElse: () => null);

      if (variable != null) {
        search._wipeLookupCache(name);
        search._variables.remove(variable);
        return variable;
      }

      search = search._parent;
    }

    return null;
  }

  /// Finds the variable with the given name, either within this scope or an ancestor.
  ///
  /// Returns `null` if none has been found.
  Variable<T> resolve(String name) {
    var v = _lookupCache.putIfAbsent(name, () {
      var variable =
          _variables.firstWhere((v) => v.name == name, orElse: () => null);

      if (variable != null)
        return variable;
      else if (_parent != null)
        return _parent.resolve(name);
      else
        return null;
    });

    if (v == null) {
      _lookupCache.remove(name);
      return null;
    } else
      return v;
  }

  /// Finds the variable with the given name, either within this scope or an ancestor.
  /// Creates a new variable if none was found.
  ///
  /// If a new variable is created, you may optionally give it a [value].
  /// You can also mark the new variable as a [constant].
  Variable<T> resolveOrCreate(String name, {T value, bool constant}) {
    var resolved = resolve(name);
    if (resolved != null) return resolved;
    return create(name, value: value, constant: constant);
  }

  /// Creates a child scope within this one.
  ///
  /// You may optionally provide starter [values].
  SymbolTable<T> createChild({Map<String, T> values: const {}}) {
    var child = new SymbolTable(values: values);
    child
      .._depth = _depth + 1
      .._parent = this
      .._root = _root;
    _children.add(child);
    return child;
  }

  /// Creates a scope identical to this one, but with no children.
  ///
  /// The [parent] scope will see the new scope as a child.
  SymbolTable<T> clone() {
    var table = new SymbolTable<T>();
    table._variables.addAll(_variables);
    table
      .._depth = _depth
      .._parent = _parent
      .._root = _root;
    _parent?._children?.add(table);
    return table;
  }

  /// Creates a *forked* scope, derived from this one.
  /// You may provide starter [values].
  ///
  /// As opposed to [createChild], all variables in the resulting forked
  /// scope will be *copies* of those in this class. This makes forked
  /// scopes useful for implementations of concepts like closure functions,
  /// where the current values of variables are trapped.
  ///
  /// The forked scope is essentially orphaned and stands alone; although its
  /// [parent] getter will point to the parent of the original scope, the parent
  /// will not be aware of the new scope's existence.
  SymbolTable<T> fork({Map<String, T> values: const {}}) {
    var table = new SymbolTable<T>();
    table
      .._depth = _depth
      .._parent = _parent
      .._root = _root;

    table._variables.addAll(_variables.map((Variable<T> v) {
      Variable<T> variable = new Variable._(v.name, this, value: v.value);
      variable.visibility = v.visibility;

      if (v.isImmutable) variable.lock();
      return variable;
    }));

    return table;
  }

  /// Returns a variation on the input [name] that is guaranteed to never be repeated within this scope.
  ///
  /// The variation will the input [name], but with a numerical suffix appended.
  /// Ex. `foo1`, `bar24`
  String uniqueName(String name) {
    int count = 0;
    SymbolTable search = this;

    while (search != null) {
      if (search._names.containsKey(name)) count += search._names[name];
      search = search._parent;
    }

    _names.putIfAbsent(name, () => 0);
    _names[name]++;
    return '$name$count';
  }
}
