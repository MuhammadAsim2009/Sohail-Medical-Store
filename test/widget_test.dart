import 'package:flutter_test/flutter_test.dart';

import 'package:pharmacy/main.dart';

void main() {
  testWidgets('App loads smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const PharmacyApp());

    // Verify that the app loads and shows the splash screen text.
    expect(find.text('New Sohail Medical Store'), findsOneWidget);
  });
}
