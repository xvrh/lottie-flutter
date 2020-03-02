import 'package:flutter_test/flutter_test.dart';
import 'package:lottie_example/main.dart';

void main() {
  testWidgets('Main sample', (tester) async {
    await tester.pumpWidget(App());
    await tester.pump();
  });
}
