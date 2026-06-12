import 'package:flutter/material.dart';

import 'package:myduesapp/features/dues/presentation/widgets/app_navigation.dart';

class AppDrawer extends StatelessWidget {
  final String current;

  const AppDrawer({super.key, required this.current});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget item(AppNavigationDestination destination) {
      final route = destination.route;
      final selected = current == route;
      return ListTile(
        leading: Icon(selected ? destination.selectedIcon : destination.icon),
        title: Text(destination.label),
        selected: selected,
        selectedTileColor: theme.colorScheme.primaryContainer,
        selectedColor: theme.colorScheme.onPrimaryContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      'assets/app_icon.png',
                      width: 40,
                      height: 40,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'MyDues',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'Dues management',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            const SizedBox(height: 8),
            for (final destination in appNavigationDestinations) ...[
              item(destination),
              const SizedBox(height: 4),
            ],
          ],
        ),
      ),
    );
  }
}
