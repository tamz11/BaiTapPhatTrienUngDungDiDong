import 'package:flutter_test/flutter_test.dart';

import 'package:th3/main.dart';

void main() {
  testWidgets('Render TH3 app shell', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump();

    expect(find.textContaining('TH3 -'), findsOneWidget);
  });
}
