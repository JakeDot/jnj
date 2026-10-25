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
    expect(find.text('anonymous \$ '), findsOneWidget);
  });

  testWidgets('Terminal toggles root mode prompt anonymous # on /root command', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final storageService = await StorageService.init();

    await tester.pumpWidget(JulesShellApp(storageService: storageService));
    await tester.pumpAndSettle();

    expect(find.text('anonymous \$ '), findsOneWidget);

    await tester.enterText(find.byType(TextField), '/root');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(find.text('anonymous # '), findsOneWidget);
  });

  testWidgets('Terminal displays custom configured account email in prompt label', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'jules_app_config': '{"firebaseUserId":"jakob@example.com"}',
    });
    final storageService = await StorageService.init();

    await tester.pumpWidget(JulesShellApp(storageService: storageService));
    await tester.pumpAndSettle();

    expect(find.text('jakob@example.com \$ '), findsOneWidget);
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
    expect(find.text('Google Jules AI API Configuration'), findsOneWidget);
  });
}
