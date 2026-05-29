import 'package:flutter/material.dart';

import 'package:myduesapp/features/dues/presentation/pages/all_dues_showcase.dart';

class AppDrawer extends StatelessWidget {
  final String current;

  const AppDrawer({super.key, required this.current});

  void _openAllDues(BuildContext context) {
    Navigator.pop(context);
    if (current == '/all-dues') return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (context) => const AllDuesShowcasePage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget item({
      required String label,
      required IconData icon,
      required String route,
    }) {
      final selected = current == route;
      return ListTile(
        leading: Icon(icon),
        title: Text(label),
        selected: selected,
        onTap: () {
          Navigator.pop(context);
          if (selected) return;
          Navigator.pushReplacementNamed(context, route);
        },
      );
    }

    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Text(
                'MyDues',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
            const Divider(height: 1),
            item(label: 'Create', icon: Icons.add_rounded, route: '/create'),
            item(
              label: 'Overview',
              icon: Icons.view_list_rounded,
              route: '/overview',
            ),
            ListTile(
              leading: const Icon(Icons.receipt_long_rounded),
              title: const Text('All Dues'),
              selected: current == '/all-dues',
              onTap: () => _openAllDues(context),
            ),
            item(
              label: 'Settings',
              icon: Icons.settings_rounded,
              route: '/settings',
            ),
          ],
        ),
      ),
    );
  }
}
