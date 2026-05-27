import 'package:flutter/material.dart';

import 'package:myduesapp/features/dues/presentation/pages/home.dart';
import 'package:myduesapp/features/dues/presentation/pages/dues.dart';
import 'package:myduesapp/features/dues/presentation/pages/settings.dart';
import 'package:myduesapp/injection_container.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final seed = Colors.blue;

    return MaterialApp(
      title: 'MyDues',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: seed),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const MyHomePage(title: 'MyDues'),
        '/overview': (context) => const DuesPage(),
        '/settings': (context) => const SettingsPage(),
      },
    );
  }
}
