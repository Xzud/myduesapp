import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import 'package:myduesapp/core/theme.dart';
import 'package:myduesapp/core/notifications/notification_service.dart';
import 'package:myduesapp/features/dues/application/usecases/sync_due_reminders.dart';
import 'package:myduesapp/features/dues/application/usecases/sync_recurring_templates.dart';
import 'package:myduesapp/features/dues/presentation/pages/all_dues_showcase.dart';
import 'package:myduesapp/features/dues/presentation/pages/create.dart';
import 'package:myduesapp/features/dues/presentation/pages/dues.dart';
import 'package:myduesapp/features/dues/presentation/pages/home.dart';
import 'package:myduesapp/features/dues/presentation/pages/settings.dart';
import 'package:myduesapp/injection_container.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await init();
  try {
    await sl<SyncRecurringTemplates>().call();
    await sl<NotificationService>().initialize();
    await sl<SyncDueReminders>().call();
  } catch (e) {
    if (kDebugMode) {
      // ignore: avoid_print
      print('Reminder initialization failed: $e');
    }
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MyDues',
      theme: AppTheme.light(),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomePage(title: 'MyDues'),
        '/create': (context) => const CreatePage(title: 'Create'),
        '/overview': (context) => const DuesPage(),
        '/all-dues': (context) => const AllDuesShowcasePage(),
        '/settings': (context) => const SettingsPage(),
      },
    );
  }
}
