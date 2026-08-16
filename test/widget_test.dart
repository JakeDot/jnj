import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app/main.dart';
import 'package:app/services/storage_service.dart';

void main() {
  testWidgets('JulesShellApp renders title, navigation, and terminal interface', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final storageService = await StorageService.init();

    await tester.pumpWidget(JulesShellApp(storageService: storageService));
    await tester.pumpAndSettle();

    expect(find.text('Jules Shell'), findsOneWidget);
    expect(find.text('Windows & Android'), findsOneWidget);

    // Verify presence of Terminal tab / input prompt
    expect(find.byType(TextField), findsOneWidget);
    expect(find.textContaining('Welcome to Jules Shell Terminal'), findsOneWidget);
  });

  testWidgets('Navigation switches between Terminal, Dashboard, GitHub, and Settings views', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final storageService = await StorageService.init();

    await tester.pumpWidget(JulesShellApp(storageService: storageService));
    await tester.pumpAndSettle();

    // Tap Dashboard tab
    await tester.tap(find.byIcon(Icons.dashboard_customize));
    await tester.pumpAndSettle();
    expect(find.text('Filter Status: '), findsOneWidget);

    // Tap GitHub tab
    await tester.tap(find.byIcon(Icons.share_outlined));
    await tester.pumpAndSettle();
    expect(find.textContaining('Paste GitHub URL'), findsOneWidget);

    // Tap Settings tab
    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();
    expect(find.text('Jules API Key & Security'), findsOneWidget);
  });
}
