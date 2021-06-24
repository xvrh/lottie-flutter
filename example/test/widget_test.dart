import 'package:flutter_test/flutter_test.dart';
import 'package:lottie_example/main_app.dart';

void main() {
  testWidgets('Main sample', (tester) async {
    await tester.pumpWidget(const App());
    await tester.pump();
  });
}
