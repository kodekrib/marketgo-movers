import 'package:flutter_test/flutter_test.dart';

import 'package:movers/app.dart';

void main() {
  testWidgets('Movers app renders home shell', (WidgetTester tester) async {
    await tester.pumpWidget(const MoversApp());

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Activity'), findsOneWidget);
    expect(find.text('Account'), findsOneWidget);
  });
}