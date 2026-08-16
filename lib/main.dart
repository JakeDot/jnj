import 'package:flutter/material.dart';

import 'services/storage_service.dart';
import 'views/main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storageService = await StorageService.init();

  runApp(JulesShellApp(storageService: storageService));
}

class JulesShellApp extends StatelessWidget {
  final StorageService storageService;

  const JulesShellApp({
    super.key,
    required this.storageService,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Jules Shell App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.cyanAccent,
        scaffoldBackgroundColor: const Color(0xFF1E1E2E),
        colorScheme: const ColorScheme.dark(
          primary: Colors.cyanAccent,
          secondary: Color(0xFF89B4FA),
          surface: Color(0xFF181825),
        ),
      ),
      home: MainScreen(storageService: storageService),
    );
  }
}
