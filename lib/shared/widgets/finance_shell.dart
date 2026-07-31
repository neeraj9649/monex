import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/responsive/breakpoints.dart';
import '../../routing/app_routes.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_shadows.dart';
import '../../theme/app_spacing.dart';
import '../providers/finance_providers.dart';

class FinanceShell extends ConsumerWidget {
  const FinanceShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMobile = Breakpoints.isMobile(context);
    final path = GoRouterState.of(context).uri.path;
    final state = ref.watch(financeControllerProvider);

    return Scaffold(
      appBar: isMobile
          ? AppBar(
              leading: Builder(
                builder: (context) => IconButton(
                  tooltip: 'Open navigation',
                  onPressed: () => Scaffold.of(context).openDrawer(),
                  icon: const Icon(Icons.menu_rounded),
                ),
              ),
              titleSpacing: 0,
              title: const _BrandTitle(compact: true),
              actions: [
                IconButton(
                  tooltip: 'Search',
                  onPressed: () => context.go('/search'),
                  icon: const Icon(Icons.search_rounded),
                ),
                IconButton(
                  tooltip: 'Profile',
                  onPressed: () => context.go('/profile'),
                  icon: const Icon(Icons.account_circle_outlined),
                ),
              ],
            )
          : null,
      drawer: isMobile
          ? Drawer(
              child: _AppMenu(
                selectedPath: path,
                founderName: state.profile.name,
                companyName: state.business.name,
                onNavigate: (route) {
                  Navigator.of(context).pop();
                  context.go(route.path);
                },
              ),
            )
          : null,
      body: Row(
        children: [
          if (!isMobile)
            _DesktopSidebar(
              selectedPath: path,
              founderName: state.profile.name,
              companyName: state.business.name,
              onNavigate: (route) => context.go(route.path),
            ),
          Expanded(
            child: Column(
              children: [
                if (!isMobile)
                  _TopBar(
                    selectedPath: path,
                    founderName: state.profile.name,
                    onSearch: () => context.go('/search'),
                    onProfile: () => context.go('/profile'),
                    onNotifications: () => context.go('/reminders'),
                  ),
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: isMobile
          ? NavigationBar(
              selectedIndex: AppRouteIndex.bottomIndexFromLocation(path),
              onDestinationSelected: (index) =>
                  context.go(AppRouteIndex.bottomDestinations[index].path),
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              destinations: AppRouteIndex.bottomDestinations
                  .map(
                    (item) => NavigationDestination(
                      icon: Tooltip(
                        message: item.label,
                        child: Icon(item.icon),
                      ),
                      selectedIcon: Tooltip(
                        message: item.label,
                        child: Icon(item.selectedIcon),
                      ),
                      label: item.label,
                    ),
                  )
                  .toList(),
            )
          : null,
      floatingActionButton: isMobile && path != '/add'
          ? FloatingActionButton.extended(
              onPressed: () => context.go('/add'),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add'),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

class _DesktopSidebar extends StatelessWidget {
  const _DesktopSidebar({
    required this.selectedPath,
    required this.founderName,
    required this.companyName,
    required this.onNavigate,
  });

  final String selectedPath;
  final String founderName;
  final String companyName;
  final ValueChanged<AppRouteItem> onNavigate;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: MediaQuery.sizeOf(context).width >= 1280 ? 292 : 252,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest.withValues(alpha: .96),
        border: Border(right: BorderSide(color: scheme.outlineVariant)),
      ),
      child: SafeArea(
        child: _AppMenu(
          selectedPath: selectedPath,
          founderName: founderName,
          companyName: companyName,
          onNavigate: onNavigate,
        ),
      ),
    );
  }
}

class _AppMenu extends StatelessWidget {
  const _AppMenu({
    required this.selectedPath,
    required this.founderName,
    required this.companyName,
    required this.onNavigate,
  });

  final String selectedPath;
  final String founderName;
  final String companyName;
  final ValueChanged<AppRouteItem> onNavigate;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _BrandTitle(),
              const SizedBox(height: 20),
              InkWell(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                onTap: () => onNavigate(
                  AppRouteIndex.destinations.firstWhere(
                    (route) => route.path == '/profile',
                  ),
                ),
                child: Ink(
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: scheme.outlineVariant),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 21,
                        backgroundColor: scheme.primaryContainer,
                        child: Text(
                          founderName.isEmpty ? 'F' : founderName[0],
                          style: TextStyle(
                            color: scheme.onPrimaryContainer,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              founderName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            Text(
                              companyName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: scheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => onNavigate(
                    AppRouteIndex.destinations.firstWhere(
                      (route) => route.path == '/add',
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_rounded, size: 20),
                      SizedBox(width: 8),
                      Text('Add transaction'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Divider(height: 1, color: scheme.outlineVariant),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
            children: [
              _SectionLabel('Workspace'),
              for (final route in AppRouteIndex.destinations.take(7))
                _MenuTile(
                  route: route,
                  selected: selectedPath.startsWith(route.path),
                  onTap: () => onNavigate(route),
                ),
              const SizedBox(height: 10),
              _SectionLabel('Money modules'),
              for (final route in AppRouteIndex.destinations.skip(7).take(8))
                _MenuTile(
                  route: route,
                  selected: selectedPath.startsWith(route.path),
                  onTap: () => onNavigate(route),
                ),
              const SizedBox(height: 10),
              _SectionLabel('Operations'),
              for (final route in AppRouteIndex.destinations.skip(15))
                _MenuTile(
                  route: route,
                  selected: selectedPath.startsWith(route.path),
                  onTap: () => onNavigate(route),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.route,
    required this.selected,
    required this.onTap,
  });

  final AppRouteItem route;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Tooltip(
        message: route.label,
        waitDuration: const Duration(milliseconds: 500),
        child: ListTile(
          dense: true,
          minLeadingWidth: 24,
          horizontalTitleGap: 12,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          selected: selected,
          selectedTileColor: scheme.primaryContainer.withValues(alpha: .74),
          leading: Icon(
            selected ? route.selectedIcon : route.icon,
            color: selected ? scheme.primary : scheme.onSurfaceVariant,
          ),
          title: Text(
            route.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
            ),
          ),
          trailing: selected
              ? Container(
                  width: 4,
                  height: 24,
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                )
              : null,
          onTap: onTap,
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.selectedPath,
    required this.founderName,
    required this.onSearch,
    required this.onProfile,
    required this.onNotifications,
  });

  final String selectedPath;
  final String founderName;
  final VoidCallback onSearch;
  final VoidCallback onProfile;
  final VoidCallback onNotifications;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final route = AppRouteIndex.destinations.firstWhere(
      (item) => selectedPath.startsWith(item.path),
      orElse: () => AppRouteIndex.destinations.first,
    );

    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x2),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: .92),
        border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Icon(route.selectedIcon, color: scheme.primary),
                const SizedBox(width: 10),
                Text(
                  route.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          _TopBarSearch(onTap: onSearch),
          const SizedBox(width: 10),
          _IconSurface(
            tooltip: 'Notifications',
            icon: Icons.notifications_none_rounded,
            onPressed: onNotifications,
          ),
          const SizedBox(width: 10),
          _IconSurface(
            tooltip: 'Profile',
            icon: Icons.account_circle_outlined,
            onPressed: onProfile,
          ),
          const SizedBox(width: 10),
          Text(
            founderName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ],
      ),
    );
  }
}

class _TopBarSearch extends StatelessWidget {
  const _TopBarSearch({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: 'Search',
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        onTap: onTap,
        child: Ink(
          width: 260,
          height: 42,
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(color: scheme.outlineVariant),
          ),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Row(
            children: [
              Icon(Icons.search_rounded, size: 19, color: scheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Search ledger, people, invoices',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconSurface extends StatelessWidget {
  const _IconSurface({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon),
        style: IconButton.styleFrom(
          backgroundColor: scheme.surfaceContainerLow,
          foregroundColor: scheme.onSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            side: BorderSide(color: scheme.outlineVariant),
          ),
        ),
      ),
    );
  }
}

class _BrandTitle extends StatelessWidget {
  const _BrandTitle({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: compact ? 32 : 38,
          width: compact ? 32 : 38,
          decoration: BoxDecoration(
            color: scheme.primary,
            borderRadius: BorderRadius.circular(AppRadius.md),
            boxShadow: AppShadows.soft(scheme.primary),
          ),
          child: Center(
            child: Text(
              'FF',
              style: TextStyle(
                color: scheme.onPrimary,
                fontSize: compact ? 12 : 14,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            'MONEX',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
        ),
      ],
    );
  }
}
