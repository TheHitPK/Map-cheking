import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/format.dart';
import '../../../core/models.dart';
import '../../../core/widgets/common.dart';
import '../data/supervisor_api.dart';
import '../data/supervisor_models.dart';
import 'employee_editor_page.dart';
import 'supervisor_shell.dart';

class EmployeesPage extends ConsumerStatefulWidget {
  const EmployeesPage({super.key});

  @override
  ConsumerState<EmployeesPage> createState() => _EmployeesPageState();
}

class _EmployeesPageState extends ConsumerState<EmployeesPage> {
  String _query = '';

  Future<void> _open([Employee? e]) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => EmployeeEditorPage(employee: e), fullscreenDialog: e == null),
    );
    if (saved ?? false) {
      ref.invalidate(employeesProvider);
      ref.invalidate(shiftsProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final employees = ref.watch(employeesProvider);
    final shifts = {for (final s in ref.watch(shiftsProvider).value ?? const <Shift>[]) s.employeeId: s};
    final sites = <int, String>{for (final w in ref.watch(worksitesProvider).value ?? const <Worksite>[]) w.id: w.name};
    return Scaffold(
      appBar: const SupervisorAppBar(title: 'Personal'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _open,
        icon: const Icon(Icons.person_add_alt_outlined),
        label: const Text('Nuevo empleado'),
      ),
      body: switch (employees) {
        AsyncData(:final value) => Column(children: [
            MaxWidth(
              width: 900,
              child: Padding(
                padding: const EdgeInsets.all(Space.lg),
                child: TextField(
                  decoration: const InputDecoration(labelText: 'Buscar por nombre o cédula', prefixIcon: Icon(Icons.search)),
                  onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
                ),
              ),
            ),
            Expanded(child: _list(value, shifts, sites)),
          ]),
        AsyncError(:final error) => ErrorState(message: '$error', onRetry: () => ref.invalidate(employeesProvider)),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }

  Widget _list(List<Employee> all, Map<int, Shift> shifts, Map<int, String> sites) {
    final list = all
        .where((e) => _query.isEmpty || e.fullName.toLowerCase().contains(_query) || e.document.toLowerCase().contains(_query))
        .toList();
    if (list.isEmpty) {
      return EmptyState(
        icon: Icons.groups_outlined,
        title: _query.isEmpty ? 'Aún no hay empleados' : 'Sin resultados',
        message: _query.isEmpty ? 'Registre a sus trabajadores y asígneles obra y horario.' : null,
      );
    }
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(shiftsProvider);
        await ref.refresh(employeesProvider.future).then((_) {});
      },
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(Space.lg, 0, Space.lg, 96),
        itemCount: list.length,
        separatorBuilder: (_, _) => const SizedBox(height: Space.sm),
        itemBuilder: (_, i) {
          final e = list[i];
          final s = shifts[e.id];
          final schedule = !e.isWorker
              ? 'Supervisor'
              : s == null
                  ? 'Sin horario asignado'
                  : '${sites[s.worksiteId] ?? 'Obra'} · ${Fmt.hhmm(s.start)}–${Fmt.hhmm(s.end)} · ${Fmt.days(s.days)}';
          return MaxWidth(
            width: 900,
            child: Card(
              clipBehavior: Clip.antiAlias,
              child: ListTile(
                leading: CircleAvatar(child: Icon(e.isWorker ? Icons.engineering_outlined : Icons.admin_panel_settings_outlined)),
                title: Text(e.fullName),
                subtitle: Text('${e.document} · $schedule'),
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  if (!e.active) const StatusBadge(label: 'Inactivo', icon: Icons.block, tone: Tone.neutral, dense: true),
                  if (e.active && e.isWorker && s == null)
                    const StatusBadge(label: 'Sin horario', icon: Icons.warning_amber_outlined, tone: Tone.warning, dense: true),
                  const Icon(Icons.chevron_right),
                ]),
                onTap: () => _open(e),
              ),
            ),
          );
        },
      ),
    );
  }
}
