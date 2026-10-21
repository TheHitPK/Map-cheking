import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_controller.dart';
import 'employees_page.dart';
import 'reports_page.dart';
import 'today_page.dart';
import 'worksites_page.dart';

/// Adaptive navigation: bottom bar on phones, side rail from 840 dp (tablets, web).
class SupervisorShell extends ConsumerStatefulWidget {
  const SupervisorShell({super.key});

  @override
  ConsumerState<SupervisorShell> createState() => _SupervisorShellState();
}

class _SupervisorShellState extends ConsumerState<SupervisorShell> {
  int _index = 0;

  static const _destinations = [
    (icon: Icons.today_outlined, selected: Icons.today, label: 'Hoy'),
    (icon: Icons.location_city_outlined, selected: Icons.location_city, label: 'Obras'),
    (icon: Icons.groups_outlined, selected: Icons.groups, label: 'Personal'),
    (icon: Icons.assessment_outlined, selected: Icons.assessment, label: 'Reportes'),
  ];

  static const _pages = [TodayPage(), WorksitesPage(), EmployeesPage(), ReportsPage()];

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Cerrar sesión?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Cerrar sesión')),
        ],
      ),
    );
    if (ok ?? false) await ref.read(authProvider.notifier).logout();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final wide = width >= 840;
    final name = ref.watch(authProvider).value?.fullName ?? '';
    final body = IndexedStack(index: _index, children: _pages);
    if (!wide) {
      return Scaffold(
        body: body,
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: [
            for (final d in _destinations)
              NavigationDestination(icon: Icon(d.icon), selectedIcon: Icon(d.selected), label: d.label),
          ],
        ),
      );
    }
    return Scaffold(
      body: Row(children: [
        NavigationRail(
          extended: width >= 1200,
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          labelType: width >= 1200 ? NavigationRailLabelType.none : NavigationRailLabelType.all,
          leading: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Icon(Icons.admin_panel_settings_outlined, size: 32, color: Theme.of(context).colorScheme.primary),
          ),
          trailing: Expanded(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Tooltip(
                  message: 'Cerrar sesión ($name)',
                  child: IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
                ),
              ),
            ),
          ),
          destinations: [
            for (final d in _destinations)
              NavigationRailDestination(icon: Icon(d.icon), selectedIcon: Icon(d.selected), label: Text(d.label)),
          ],
        ),
        const VerticalDivider(width: 1),
        Expanded(child: body),
      ]),
    );
  }
}

/// App bar used by every supervisor page; on phones it also carries the logout action.
class SupervisorAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const SupervisorAppBar({super.key, required this.title, this.actions = const []});

  final String title;
  final List<Widget> actions;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wide = MediaQuery.sizeOf(context).width >= 840;
    return AppBar(
      title: Text(title),
      actions: [
        ...actions,
        if (!wide)
          PopupMenuButton<void>(
            tooltip: 'Más opciones',
            itemBuilder: (_) => [
              PopupMenuItem(
                onTap: () => ref.read(authProvider.notifier).logout(),
                child: const ListTile(leading: Icon(Icons.logout), title: Text('Cerrar sesión'), contentPadding: EdgeInsets.zero),
              ),
            ],
          ),
      ],
    );
  }
}
