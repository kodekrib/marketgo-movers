import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:movers/screens/app_info_screen.dart';
import 'package:movers/services/settings_service.dart';

void main() {
  testWidgets(
      'App Info shows configured identity and real installed build separately',
      (tester) async {
    SettingsService.current.value = const AppSettings(
        appName: 'Acme Dispatch',
        releaseVersion: '2.0.0',
        releaseDate: '2026-11-13',
        poweredBy: 'Acme Group',
        description: 'Delivering together');
    PackageInfo.setMockInitialValues(
        appName: 'Installed',
        packageName: 'test.app',
        version: '1.5.0',
        buildNumber: '42',
        buildSignature: '');
    await tester.pumpWidget(const MaterialApp(home: AppInfoScreen()));
    await tester.pumpAndSettle();
    expect(find.text('App Info'), findsOneWidget);
    expect(find.text('Acme Dispatch'), findsOneWidget);
    expect(find.text('1.5.0 (42)'), findsOneWidget);
    expect(find.text('2.0.0'), findsOneWidget);
    expect(find.text('2026-11-13'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Powered by Acme Group'), 200);
    expect(find.text('Powered by Acme Group'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    SettingsService.current.value = const AppSettings();
  });
}
