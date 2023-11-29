import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wakelock/wakelock.dart';

import 'home_page.dart';
import 'settings_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Enable wakelock for whole app.
  // Doing this when only on song page properly would be very convoluted.
  Wakelock.enable();

  runApp(const Enekeskonyv());
}

class Enekeskonyv extends StatelessWidget {
  const Enekeskonyv({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<SettingsProvider>(
      create: (_) => SettingsProvider()..initialize(),
      child: Consumer<SettingsProvider>(builder: (context, settings, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Énekeskönyv',
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
                seedColor:
                    settings.book == Book.black ? Colors.amber : Colors.blue,
                brightness: settings.getCurrentAppBrightness(context),
                background: settings.isOledTheme &&
                        settings.getCurrentAppBrightness(context) ==
                            Brightness.dark
                    ? Colors.black
                    : null),
          ),
          home: const HomePage(),
        );
      }),
    );
  }
}
