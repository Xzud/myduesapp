import 'package:flutter/material.dart';

class AppNavigationDestination {
  final String route;
  final String label;
  final IconData icon;
  final IconData selectedIcon;

  const AppNavigationDestination({
    required this.route,
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });
}

const appNavigationDestinations = [
  AppNavigationDestination(
    route: '/',
    label: 'Home',
    icon: Icons.home_outlined,
    selectedIcon: Icons.home_rounded,
  ),
  AppNavigationDestination(
    route: '/create',
    label: 'Create',
    icon: Icons.add_circle_outline_rounded,
    selectedIcon: Icons.add_circle_rounded,
  ),
  AppNavigationDestination(
    route: '/overview',
    label: 'Overview',
    icon: Icons.view_list_outlined,
    selectedIcon: Icons.view_list_rounded,
  ),
  AppNavigationDestination(
    route: '/all-dues',
    label: 'All Dues',
    icon: Icons.receipt_long_outlined,
    selectedIcon: Icons.receipt_long_rounded,
  ),
  AppNavigationDestination(
    route: '/settings',
    label: 'Settings',
    icon: Icons.settings_outlined,
    selectedIcon: Icons.settings_rounded,
  ),
];
