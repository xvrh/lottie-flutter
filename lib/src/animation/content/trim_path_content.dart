import '../../model/content/shape_trim_path.dart';
import '../../model/layer/base_layer.dart';
import '../keyframe/base_keyframe_animation.dart';
import 'content.dart';

class TrimPathContent implements Content {
  @override
  final String? name;
  final bool hidden;
  final _listeners = <void Function()>[];
  final ShapeTrimPathType? type;
  final BaseKeyframeAnimation<Object, double> start;
  final BaseKeyframeAnimation<Object, double> end;
  final BaseKeyframeAnimation<Object, double> offset;

  TrimPathContent(BaseLayer layer, ShapeTrimPath trimPath)
    : name = trimPath.name,
      hidden = trimPath.hidden,
      type = trimPath.type,
      start = trimPath.start.createAnimation(),
      end = trimPath.end.createAnimation(),
      offset = trimPath.offset.createAnimation() {
    layer.addAnimation(start);
    layer.addAnimation(end);
    layer.addAnimation(offset);

    start.addUpdateListener(_onValueChanged);
    end.addUpdateListener(_onValueChanged);
    offset.addUpdateListener(_onValueChanged);
  }

  void _onValueChanged() {
    for (var i = 0; i < _listeners.length; i++) {
      _listeners[i]();
    }
  }

  @override
  void setContents(List<Content> contentsBefore, List<Content> contentsAfter) {
    // Do nothing.
  }

  void addListener(void Function() listener) {
    _listeners.add(listener);
  }
}
