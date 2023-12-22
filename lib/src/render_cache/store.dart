abstract class Store<TEntry extends CacheEntry<TCacheKey>, TCacheKey> {
  final entries = <TCacheKey, TEntry>{};
  final handles = <Object, Handle<TEntry, TCacheKey>>{};

  bool shouldRemove(TEntry entry) => entry.handles.isEmpty;

  TEntry createEntry(TCacheKey key);

  void _clearUnused() {
    for (var entry in entries.entries.toList()) {
      var key = entry.key;
      var cache = entry.value;

      if (shouldRemove(cache)) {
        cache.dispose();
        var found = entries.remove(key);
        assert(found == cache);
      }
    }
  }

  Handle<TEntry, TCacheKey> acquire(Object user) {
    var handle = handles[user] ??= Handle<TEntry, TCacheKey>(this);
    return handle;
  }

  void release(Object user) {
    var handle = handles.remove(user);
    if (handle?._currentEntry case var currentEntry?) {
      var removed = currentEntry.handles.remove(handle);
      assert(removed);
      _clearUnused();
    }
  }
}

class Handle<TEntry extends CacheEntry<TCacheKey>, TCacheKey> {
  final Store<TEntry, TCacheKey> _cache;
  TEntry? _currentEntry;

  Handle(this._cache);

  TEntry withKey(TCacheKey key) {
    if (_currentEntry case var currentEntry? when currentEntry.key != key) {
      _currentEntry = null;
      currentEntry.handles.remove(this);
      _cache._clearUnused();
    }
    var entry = _cache.entries[key] ??= _cache.createEntry(key);
    entry.handles.add(this);
    _currentEntry = entry;
    return entry;
  }
}

abstract base class CacheEntry<TCacheKey> {
  final TCacheKey key;
  final handles = <Handle>{};

  CacheEntry(this.key);

  void dispose();
}
