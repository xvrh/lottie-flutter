import 'key_path_element.dart';

/// Defines which content to target.
/// The keypath can contain wildcards ('*') with match exactly 1 item.
/// or globstars ('**') which match 0 or more items.
///
/// For example, if your content were arranged like this:
/// Gabriel (Shape Layer)
///     Body (Shape Group)
///         Left Hand (Shape)
///             Fill (Fill)
///             Transform (Transform)
///         ...
/// Brandon (Shape Layer)
///     Body (Shape Group)
///         Left Hand (Shape)
///             Fill (Fill)
///             Transform (Transform)
///         ...
///
///
/// You could:
///     Match Gabriel left hand fill:
///        new KeyPath("Gabriel", "Body", "Left Hand", "Fill");
///     Match Gabriel and Brandon's left hand fill:
///        new KeyPath("*", "Body", Left Hand", "Fill");
///     Match anything with the name Fill:
///        new KeyPath("**", "Fill");
///
///
/// NOTE: Content that are part of merge paths or repeaters cannot currently be resolved with
/// a {@link KeyPath}. This may be fixed in the future.
class KeyPath {
  final List<String> keys;
  KeyPathElement? _resolvedElement;

  KeyPath(List<String> keys) : keys = keys.toList();

  /// Copy constructor. Copies keys as well.
  KeyPath.copy(KeyPath keyPath)
      : keys = keyPath.keys.toList(),
        _resolvedElement = keyPath._resolvedElement;

  /// Returns a new KeyPath with the key added.
  /// This is used during keypath resolution. Children normally don't know about all of their parent
  /// elements so this is used to keep track of the fully qualified keypath.
  /// This returns a key keypath because during resolution, the full keypath element tree is walked
  /// and if this modified the original copy, it would remain after popping back up the element tree.
  //@CheckResult
  KeyPath addKey(String key) {
    var newKeyPath = KeyPath.copy(this);
    newKeyPath.keys.add(key);
    return newKeyPath;
  }

  /// Return a new KeyPath with the element resolved to the specified {@link KeyPathElement}.
  KeyPath resolve(KeyPathElement element) {
    var keyPath = KeyPath.copy(this);
    keyPath._resolvedElement = element;
    return keyPath;
  }

  /// Returns a {@link KeyPathElement} that this has been resolved to. KeyPaths get resolved with
  /// resolveKeyPath on LottieDrawable.
  KeyPathElement? get resolvedElement {
    return _resolvedElement;
  }

  /// Returns whether they key matches at the specified depth.
  bool matches(String? key, int depth) {
    if (isContainer(key)) {
      // This is an artificial layer we programatically create.
      return true;
    }
    if (depth >= keys.length) {
      return false;
    }
    if (keys[depth] == key || keys[depth] == '**' || keys[depth] == '*') {
      return true;
    }
    return false;
  }

  /// For a given key and depth, returns how much the depth should be incremented by when
  /// resolving a keypath to children.
  ///
  /// This can be 0 or 2 when there is a globstar and the next key either matches or doesn't match
  /// the current key.
  int incrementDepthBy(String? key, int depth) {
    if (isContainer(key)) {
      // If it's a container then we added programatically and it isn't a part of the keypath.
      return 0;
    }
    if (keys[depth] != '**') {
      // If it's not a globstar then it is part of the keypath.
      return 1;
    }
    if (depth == keys.length - 1) {
      // The last key is a globstar.
      return 0;
    }
    if (keys[depth + 1] == key) {
      // We are a globstar and the next key is our current key so consume both.
      return 2;
    }
    return 0;
  }

  /// Returns whether the key at specified depth is fully specific enough to match the full set of
  /// keys in this keypath.
  bool fullyResolvesTo(String? key, int depth) {
    if (depth >= keys.length) {
      return false;
    }
    var isLastDepth = depth == keys.length - 1;
    var keyAtDepth = keys[depth];
    var isGlobstar = keyAtDepth == '**';

    if (!isGlobstar) {
      var matches = keyAtDepth == key || keyAtDepth == '*';
      return (isLastDepth ||
              (depth == keys.length - 2 && endsWithGlobstar())) &&
          matches;
    }

    var isGlobstarButNextKeyMatches = !isLastDepth && keys[depth + 1] == key;
    if (isGlobstarButNextKeyMatches) {
      return depth == keys.length - 2 ||
          (depth == keys.length - 3 && endsWithGlobstar());
    }

    if (isLastDepth) {
      return true;
    }
    if (depth + 1 < keys.length - 1) {
      // We are a globstar but there is more than 1 key after the globstar we we can't fully match.
      return false;
    }
    // Return whether the next key (which we now know is the last one) is the same as the current
    // key.
    return keys[depth + 1] == key;
  }

  /// Returns whether the keypath resolution should propagate to children. Some keypaths resolve
  /// to content other than leaf contents (such as a layer or content group transform) so sometimes
  /// this will return false.
  bool propagateToChildren(String? key, int depth) {
    if ('__container' == key) {
      return true;
    }
    return depth < keys.length - 1 || keys[depth] == '**';
  }

  /// We artificially create some container groups (like a root ContentGroup for the entire animation
  /// and for the contents of a ShapeLayer).
  bool isContainer(String? key) {
    return '__container' == key;
  }

  bool endsWithGlobstar() {
    return keys[keys.length - 1] == '**';
  }

  String keysToString() {
    return keys.toString();
  }

  @override
  String toString() {
    return 'KeyPath{keys=$keys,resolved=${resolvedElement != null}}';
  }
}
