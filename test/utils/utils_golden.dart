import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart';
import 'package:meta/meta.dart';
import 'pixel_match.dart';

final bool _updateGolden = Platform.environment['LOTTIE_UPDATE_GOLDEN'] != null;

class _GoldenMatcher extends Matcher {
  final String goldenPath;

  _GoldenMatcher(this.goldenPath);

  @override
  Description describe(Description description) {
    return description.addDescriptionOf('Golden($goldenPath)');
  }

  @override
  bool matches(covariant List<int> item, Map matchState) {
    var goldenFile = File(goldenPath);

    if (_updateGolden) {
      goldenFile.parent.createSync(recursive: true);
      goldenFile.writeAsBytesSync(item);
      return true;
    } else {
      if (!goldenFile.existsSync()) return false;

      var difference = _compareImages(item, goldenFile.readAsBytesSync());
      if (difference == null) {
        return true;
      } else {
        matchState['comparison'] = difference;
        return false;
      }
    }
  }

  @override
  Description describeMismatch(
      item, Description mismatchDescription, Map matchState, bool verbose) {
    var difference = matchState['comparison'] as ImageDifference;
    mismatchDescription.replace(difference.toString());
    return mismatchDescription;
  }
}

_GoldenMatcher equalsGolden(String goldenPath) {
  return _GoldenMatcher(goldenPath);
}

ImageDifference _compareImages(List<int> actualBytes, List<int> expectedBytes) {
  var actual = decodeImage(actualBytes);
  var expected = decodeImage(expectedBytes);

  if (expected.width != actual.width || expected.height != actual.height) {
    return SizeDifference(
        expected.width, expected.height, actual.width, actual.height);
  }

  var output = Uint8List(actual.data.buffer.lengthInBytes);

  num threshold = 0.1;
  var count = pixelMatch(
      Uint8List.view(expected.data.buffer), Uint8List.view(actual.data.buffer),
      width: expected.width, height: expected.height, threshold: threshold);
  if (count > 0) {
    return ContentDifference(
        count,
        PngEncoder()
            .encodeImage(Image.fromBytes(actual.width, actual.height, output)),
        usedThreshold: threshold);
  }
  return null;
}

class ImageDifference {}

class SizeDifference implements ImageDifference {
  final int expectedWidth, expectedHeight, actualWidth, actualHeight;

  SizeDifference(this.expectedWidth, this.expectedHeight, this.actualWidth,
      this.actualHeight);

  @override
  String toString() =>
      'Size is different: expected ${expectedWidth}x$expectedHeight, actual ${actualWidth}x$actualHeight';
}

class ContentDifference implements ImageDifference {
  final int differenceCount;
  final List<int> pngDiff;
  final num usedThreshold;

  ContentDifference(this.differenceCount, this.pngDiff,
      {@required this.usedThreshold});

  String get _base64Png =>
      Uri.dataFromBytes(pngDiff, mimeType: 'image/png').toString();

  @override
  String toString() =>
      'Image content has $differenceCount different pixels.\n\nDiff: $_base64Png';
}
