import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movers/widgets/swipe_notification.dart';

void main() {
  for (final succeeds in [true, false]) {
    testWidgets('Swipe deletes only after server success: $succeeds',
        (tester) async {
      var deleted = false;
      var calls = 0;
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(
              body: StatefulBuilder(
                  builder: (context, setState) => deleted
                      ? const Text('Empty')
                      : SwipeNotification(
                          id: 1,
                          onDelete: () async {
                            calls++;
                            if (!succeeds) throw Exception('offline');
                          },
                          onDeleted: () => setState(() => deleted = true),
                          child: const SizedBox(
                              height: 80,
                              width: double.infinity,
                              child: Text('Notice')))))));
      await tester.drag(find.text('Notice'), const Offset(-700, 0));
      await tester.pumpAndSettle();
      expect(calls, 1);
      expect(deleted, succeeds);
      expect(find.text('Notice'), succeeds ? findsNothing : findsOneWidget);
    });
  }
}
