import 'package:flutter/material.dart';

import 'package:myduesapp/features/dues/presentation/widgets/app_drawer.dart';
import 'package:myduesapp/features/dues/presentation/widgets/app_navigation.dart';

class AppScaffold extends StatelessWidget {
  final String currentRoute;
  final Widget title;
  final Widget body;
  final List<Widget>? actions;
  final FloatingActionButton? floatingActionButton;

  const AppScaffold({
    super.key,
    required this.currentRoute,
    required this.title,
    required this.body,
    this.actions,
    this.floatingActionButton,
  });

  int get _selectedIndex {
    final index = appNavigationDestinations.indexWhere(
      (destination) => destination.route == currentRoute,
    );
    return index < 0 ? 0 : index;
  }

  void _selectDestination(BuildContext context, int index) {
    final destination = appNavigationDestinations[index];
    if (destination.route == currentRoute) return;
    Navigator.pushReplacementNamed(context, destination.route);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: title, actions: actions),
      drawer: AppDrawer(current: currentRoute),
      body: body,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => _selectDestination(context, index),
        destinations: [
          for (final destination in appNavigationDestinations)
            NavigationDestination(
              icon: Icon(destination.icon),
              selectedIcon: Icon(destination.selectedIcon),
              label: destination.label,
            ),
        ],
      ),
    );
  }
}
