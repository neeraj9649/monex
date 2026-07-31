import 'package:flutter/material.dart';

class AppRouteItem {
  const AppRouteItem({
    required this.label,
    required this.path,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final String path;
  final IconData icon;
  final IconData selectedIcon;
}

class AppRouteIndex {
  static const destinations = [
    AppRouteItem(
      label: 'Dashboard',
      path: '/dashboard',
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard_rounded,
    ),
    AppRouteItem(
      label: 'Transactions',
      path: '/transactions',
      icon: Icons.receipt_long_outlined,
      selectedIcon: Icons.receipt_long_rounded,
    ),
    AppRouteItem(
      label: 'Add Transaction',
      path: '/add',
      icon: Icons.add_circle_outline,
      selectedIcon: Icons.add_circle_rounded,
    ),
    AppRouteItem(
      label: 'Accounts & Payments',
      path: '/accounts',
      icon: Icons.account_balance_wallet_outlined,
      selectedIcon: Icons.account_balance_wallet_rounded,
    ),
    AppRouteItem(
      label: 'Categories',
      path: '/categories',
      icon: Icons.category_outlined,
      selectedIcon: Icons.category_rounded,
    ),
    AppRouteItem(
      label: 'Loans',
      path: '/loans',
      icon: Icons.payments_outlined,
      selectedIcon: Icons.payments_rounded,
    ),
    AppRouteItem(
      label: 'Reports',
      path: '/reports',
      icon: Icons.bar_chart_outlined,
      selectedIcon: Icons.bar_chart_rounded,
    ),
    AppRouteItem(
      label: 'Personal Expenses',
      path: '/personal-expenses',
      icon: Icons.person_outline,
      selectedIcon: Icons.person_rounded,
    ),
    AppRouteItem(
      label: 'Company Expenses',
      path: '/company-expenses',
      icon: Icons.business_center_outlined,
      selectedIcon: Icons.business_center_rounded,
    ),
    AppRouteItem(
      label: 'Income',
      path: '/income',
      icon: Icons.trending_up_outlined,
      selectedIcon: Icons.trending_up_rounded,
    ),
    AppRouteItem(
      label: 'Budgets',
      path: '/budgets',
      icon: Icons.savings_outlined,
      selectedIcon: Icons.savings_rounded,
    ),
    AppRouteItem(
      label: 'People',
      path: '/people',
      icon: Icons.group_outlined,
      selectedIcon: Icons.group_rounded,
    ),
    AppRouteItem(
      label: 'Money I Owe',
      path: '/payables',
      icon: Icons.call_received,
      selectedIcon: Icons.call_received,
    ),
    AppRouteItem(
      label: 'Owed To Me',
      path: '/receivables',
      icon: Icons.call_made,
      selectedIcon: Icons.call_made,
    ),
    AppRouteItem(
      label: 'Documents',
      path: '/documents',
      icon: Icons.folder_outlined,
      selectedIcon: Icons.folder_rounded,
    ),
    AppRouteItem(
      label: 'Bank Imports',
      path: '/sms-imports',
      icon: Icons.sms_outlined,
      selectedIcon: Icons.sms_rounded,
    ),
    AppRouteItem(
      label: 'Reminders',
      path: '/reminders',
      icon: Icons.notifications_outlined,
      selectedIcon: Icons.notifications_rounded,
    ),
    AppRouteItem(
      label: 'Profile',
      path: '/profile',
      icon: Icons.account_circle_outlined,
      selectedIcon: Icons.account_circle_rounded,
    ),
    AppRouteItem(
      label: 'Settings',
      path: '/settings',
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings_rounded,
    ),
  ];

  static const bottomDestinations = [
    AppRouteItem(
      label: 'Home',
      path: '/dashboard',
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard_rounded,
    ),
    AppRouteItem(
      label: 'Ledger',
      path: '/transactions',
      icon: Icons.receipt_long_outlined,
      selectedIcon: Icons.receipt_long_rounded,
    ),
    AppRouteItem(
      label: 'Add',
      path: '/add',
      icon: Icons.add_circle_outline,
      selectedIcon: Icons.add_circle_rounded,
    ),
    AppRouteItem(
      label: 'Reports',
      path: '/reports',
      icon: Icons.bar_chart_outlined,
      selectedIcon: Icons.bar_chart_rounded,
    ),
    AppRouteItem(
      label: 'More',
      path: '/settings',
      icon: Icons.more_horiz_rounded,
      selectedIcon: Icons.more_horiz_rounded,
    ),
  ];

  static int fromLocation(String path) {
    final index = destinations.indexWhere((item) => path.startsWith(item.path));
    return index < 0 ? 0 : index;
  }

  static int bottomIndexFromLocation(String path) {
    final index = bottomDestinations.indexWhere(
      (item) => path.startsWith(item.path),
    );
    return index < 0 ? 0 : index;
  }
}
