import 'package:flutter/material.dart';
import 'lib/error_dialog.dart';
import 'lib/settings_provider.dart';

void main() {
  runApp(const ErrorDemoApp());
}

class ErrorDemoApp extends StatelessWidget {
  const ErrorDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Error Dialog Demo',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: const ErrorDemoScreen(),
    );
  }
}

class ErrorDemoScreen extends StatelessWidget {
  const ErrorDemoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock settings provider for demonstration
    final settings = MockSettingsProvider();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Error Handling Demo'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Javított hibakezelés bemutató',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const Text(
              'Ez a példa bemutatja az új hibajelentő dialógust',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () => _showErrorDialog(context, settings),
              child: const Text('Hibaüzenet megjelenítése'),
            ),
          ],
        ),
      ),
    );
  }

  void _showErrorDialog(BuildContext context, MockSettingsProvider settings) {
    ErrorDialog.show(
      context: context,
      title: 'Példa alkalmazáshiba',
      message: 'Ez egy példa hibaüzenet, amely bemutatja az új hibakezelő rendszer működését. A felhasználó választhat, hogy szeretné-e látni a technikai részleteket, vagy hibajelentést szeretne küldeni.',
      settings: settings,
      error: Exception('Példa kivétel objektum'),
      stackTrace: StackTrace.current,
    );
  }
}

class MockSettingsProvider extends SettingsProvider {
  @override
  late final packageInfo = MockPackageInfo();
}

class MockPackageInfo {
  final String version = '3.2.0';
  final String buildNumber = '55';
}