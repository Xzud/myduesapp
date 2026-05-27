import 'package:flutter/material.dart';

class AppDrawer extends StatelessWidget {
  final String current;

  const AppDrawer({super.key, required this.current});

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
            item(label: 'Create', icon: Icons.add_rounded, route: '/'),
            item(
              label: 'Overview',
              icon: Icons.view_list_rounded,
              route: '/overview',
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
