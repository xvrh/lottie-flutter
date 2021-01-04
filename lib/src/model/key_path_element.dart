import '../value/lottie_value_callback.dart';
import 'key_path.dart';

/// Any item that can be a part of a {@link KeyPath} should implement this.
abstract class KeyPathElement {
  /// Called recursively during keypath resolution.
  ///
  /// The overridden method should just call:
  ///        MiscUtils.resolveKeyPath(keyPath, depth, accumulator, currentPartialKeyPath, this);
  ///
  /// @param keyPath The full keypath being resolved.
  /// @param depth The current depth that this element should be checked at in the keypath.
  /// @param accumulator A list of fully resolved keypaths. If this element fully matches the
  ///                    keypath then it should add itself to this list.
  /// @param currentPartialKeyPath A keypath that contains all parent element of this one.
  ///                              This element should create a copy of this and append itself
  ///                              with KeyPath#addKey when it adds itself to the accumulator
  ///                              or propagates resolution to its children.
  void resolveKeyPath(KeyPath keyPath, int depth, List<KeyPath> accumulator,
      KeyPath currentPartialKeyPath);

  /// The overridden method should handle appropriate properties and set value callbacks on their
  /// animations.
  void addValueCallback<T>(T property, LottieValueCallback<T>? callback);
}
