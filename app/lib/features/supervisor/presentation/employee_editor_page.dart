import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/format.dart';
import '../../../core/widgets/common.dart';
import '../../../core/strings.dart';
import '../data/supervisor_api.dart';
import '../data/supervisor_models.dart';

/// New employee (data + password) or existing one (data, password reset and shift).
class EmployeeEditorPage extends ConsumerStatefulWidget {
  const EmployeeEditorPage({super.key, this.employee});

  final Employee? employee;

  @override
  ConsumerState<EmployeeEditorPage> createState() => _EmployeeEditorPageState();
}

class _EmployeeEditorPageState extends ConsumerState<EmployeeEditorPage> {
  final _form = GlobalKey<FormState>();
  late final _document = TextEditingController(text: widget.employee?.document);
  late final _name = TextEditingController(text: widget.employee?.fullName);
  final _password = TextEditingController();
  late final _rate = TextEditingController(
      text: widget.employee?.hourlyRateCents == null ? null : Fmt.decimal(widget.employee!.hourlyRateCents!));
  late String _role = widget.employee?.role ?? 'WORKER';
  late bool _active = widget.employee?.active ?? true;
  bool _saving = false;
  bool _changed = false;

  bool get _isNew => widget.employee == null;

  /// Only crew members are paid by the hour here; empty means "not set".
  int? get _rateCents => _role == 'WORKER' ? Fmt.parseCents(_rate.text) : widget.employee?.hourlyRateCents;

  @override
  void dispose() {
    for (final c in [_document, _name, _password, _rate]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    final api = ref.read(supervisorApiProvider);
    try {
      if (_isNew) {
        final e = await api.createEmployee({
          'document': _document.text.trim(),
          'fullName': _name.text.trim(),
          'role': _role,
          'password': _password.text,
          'hourlyRateCents': _rateCents,
        });
        if (!mounted) return;
        showMessage(context, S.memberCreated(e.isWorker));
        // Continue in edit mode so the shift can be assigned right away.
        await Navigator.of(context).pushReplacement(MaterialPageRoute<bool>(builder: (_) => EmployeeEditorPage(employee: e)));
        return;
      }
      await api.updateEmployee(widget.employee!.id,
          {'fullName': _name.text.trim(), 'role': _role, 'active': _active, 'hourlyRateCents': _rateCents});
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) showMessage(context, '$e', error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _resetPassword() async {
    final controller = TextEditingController();
    final pwd = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(S.newPassword),
        content: TextField(
          controller: controller,
          obscureText: true,
          autofocus: true,
          decoration: const InputDecoration(labelText: S.newPasswordLabel),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text(S.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, controller.text), child: const Text(S.savePassword)),
        ],
      ),
    );
    controller.dispose();
    if (pwd == null || !mounted) return;
    try {
      await ref.read(supervisorApiProvider).resetPassword(widget.employee!.id, pwd);
      if (mounted) showMessage(context, S.passwordUpdated);
    } catch (e) {
      if (mounted) showMessage(context, '$e', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.pop(context, _changed);
      },
      child: Scaffold(
        appBar: AppBar(title: Text(_isNew ? S.newCrewMember : widget.employee!.fullName)),
        body: ListView(padding: const EdgeInsets.all(Space.lg), children: [
          MaxWidth(
            width: 640,
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Form(
                key: _form,
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Text(S.details, style: t.textTheme.titleMedium),
                  const SizedBox(height: Space.md),
                  TextFormField(
                    controller: _document,
                    enabled: _isNew,
                    decoration: InputDecoration(
                      labelText: S.employeeId,
                      helperText: _isNew ? S.employeeIdHelp : null,
                    ),
                    validator: (v) => RegExp(r'^[A-Za-z0-9.-]{3,32}$').hasMatch(v?.trim() ?? '')
                        ? null
                        : S.employeeIdInvalid,
                  ),
                  const SizedBox(height: Space.lg),
                  TextFormField(
                    controller: _name,
                    decoration: const InputDecoration(labelText: S.fullName),
                    textCapitalization: TextCapitalization.words,
                    validator: (v) => (v?.trim().length ?? 0) < 3 ? S.fullNameRequired : null,
                  ),
                  const SizedBox(height: Space.lg),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'WORKER', icon: Icon(Icons.engineering_outlined), label: Text(S.crewMember)),
                      ButtonSegment(value: 'SUPERVISOR', icon: Icon(Icons.admin_panel_settings_outlined), label: Text(S.supervisor)),
                    ],
                    selected: {_role},
                    onSelectionChanged: (s) => setState(() => _role = s.first),
                  ),
                  if (_role == 'WORKER') ...[
                    const SizedBox(height: Space.lg),
                    TextFormField(
                      controller: _rate,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: S.hourlyRate,
                        prefixText: '\$ ',
                        suffixText: S.perHour,
                        helperText: S.hourlyRateHelp,
                      ),
                      validator: (v) => (v?.trim().isEmpty ?? true) || Fmt.parseCents(v!) != null ? null : S.hourlyRateInvalid,
                    ),
                  ],
                  if (_isNew) ...[
                    const SizedBox(height: Space.lg),
                    TextFormField(
                      controller: _password,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: S.initialPassword, helperText: S.passwordMin),
                      validator: (v) => (v?.length ?? 0) < 6 ? S.passwordMinError : null,
                    ),
                  ] else ...[
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _active,
                      onChanged: (v) => setState(() => _active = v),
                      title: const Text(S.active),
                      subtitle: const Text(S.activeHelp),
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(onPressed: _resetPassword, icon: const Icon(Icons.key_outlined), label: const Text(S.changePassword)),
                    ),
                  ],
                  const SizedBox(height: Space.lg),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(_isNew ? S.createMember : S.saveDetails),
                  ),
                ]),
              ),
              if (!_isNew && widget.employee!.isWorker) ...[
                const SizedBox(height: Space.xxl),
                const Divider(),
                const SizedBox(height: Space.lg),
                _ShiftEditor(employeeId: widget.employee!.id, onSaved: () => _changed = true),
              ],
            ]),
          ),
        ]),
      ),
    );
  }
}

class _ShiftEditor extends ConsumerStatefulWidget {
  const _ShiftEditor({required this.employeeId, required this.onSaved});

  final int employeeId;
  final VoidCallback onSaved;

  @override
  ConsumerState<_ShiftEditor> createState() => _ShiftEditorState();
}

class _ShiftEditorState extends ConsumerState<_ShiftEditor> {
  int? _worksiteId;
  TimeOfDay _start = const TimeOfDay(hour: 7, minute: 0);
  TimeOfDay _end = const TimeOfDay(hour: 16, minute: 0);
  Set<String> _days = Fmt.dayKeys.take(5).toSet();
  int _grace = 10;
  bool _loaded = false;
  bool _exists = false;
  bool _saving = false;

  static TimeOfDay _parse(String hhmmss) => TimeOfDay(hour: int.parse(hhmmss.substring(0, 2)), minute: int.parse(hhmmss.substring(3, 5)));

  static String _fmt(TimeOfDay t) => '${Fmt.two(t.hour)}:${Fmt.two(t.minute)}';

  void _load(List<Shift> shifts) {
    if (_loaded) return;
    _loaded = true;
    final s = shifts.where((s) => s.employeeId == widget.employeeId).firstOrNull;
    if (s == null) return;
    _exists = true;
    _worksiteId = s.worksiteId;
    _start = _parse(s.start);
    _end = _parse(s.end);
    _days = s.days.toSet();
    _grace = s.graceMinutes;
  }

  Future<void> _pick(bool start) async {
    final t = await showTimePicker(
      context: context,
      initialTime: start ? _start : _end,
    );
    if (t != null) setState(() => start ? _start = t : _end = t);
  }

  Future<void> _save() async {
    if (_worksiteId == null) return showMessage(context, S.selectSite, error: true);
    if (_days.isEmpty) return showMessage(context, S.selectDay, error: true);
    if (_start == _end) return showMessage(context, S.startEndDiffer, error: true);
    setState(() => _saving = true);
    try {
      await ref.read(supervisorApiProvider).assignShift(widget.employeeId, {
        'worksiteId': _worksiteId,
        'start': _fmt(_start),
        'end': _fmt(_end),
        'days': Fmt.dayKeys.where(_days.contains).toList(),
        'graceMinutes': _grace,
      });
      _exists = true;
      widget.onSaved();
      ref.invalidate(shiftsProvider);
      if (mounted) showMessage(context, S.scheduleSaved);
    } catch (e) {
      if (mounted) showMessage(context, '$e', error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _remove() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(S.removeScheduleQuestion),
        content: const Text(S.removeScheduleBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text(S.cancel)),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(S.remove),
          ),
        ],
      ),
    );
    if (!(ok ?? false)) return;
    try {
      await ref.read(supervisorApiProvider).removeShift(widget.employeeId);
      widget.onSaved();
      ref.invalidate(shiftsProvider);
      if (mounted) {
        setState(() => _exists = false);
        showMessage(context, S.scheduleRemoved);
      }
    } catch (e) {
      if (mounted) showMessage(context, '$e', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final shifts = ref.watch(shiftsProvider);
    final sites = (ref.watch(worksitesProvider).value ?? const []).where((w) => w.active || w.id == _worksiteId).toList();
    if (shifts is! AsyncData<List<Shift>>) {
      return shifts.hasError
          ? ErrorState(message: '${shifts.error}', onRetry: () => ref.invalidate(shiftsProvider))
          : const Center(child: CircularProgressIndicator());
    }
    _load(shifts.value);
    final overnight = _end.hour * 60 + _end.minute < _start.hour * 60 + _start.minute;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(S.siteAndSchedule, style: t.textTheme.titleMedium),
      const SizedBox(height: Space.md),
      DropdownButtonFormField<int>(
        initialValue: _worksiteId,
        isExpanded: true,
        decoration: const InputDecoration(labelText: S.jobSiteRequired, prefixIcon: Icon(Icons.location_city_outlined)),
        items: [for (final w in sites) DropdownMenuItem(value: w.id, child: Text(w.name))],
        onChanged: (v) => setState(() => _worksiteId = v),
      ),
      const SizedBox(height: Space.lg),
      Row(children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _pick(true),
            icon: const Icon(Icons.login),
            label: Text(S.startAt(_start.format(context))),
          ),
        ),
        const SizedBox(width: Space.md),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _pick(false),
            icon: const Icon(Icons.logout),
            label: Text(S.endAt(_end.format(context))),
          ),
        ),
      ]),
      if (overnight) ...[
        const SizedBox(height: Space.sm),
        const StatusBadge(label: S.overnight, icon: Icons.nightlight_outlined, tone: Tone.info, dense: true),
      ],
      const SizedBox(height: Space.lg),
      Text(S.workDays, style: t.textTheme.labelLarge),
      const SizedBox(height: Space.sm),
      Wrap(spacing: Space.sm, runSpacing: Space.sm, children: [
        for (var i = 0; i < 7; i++)
          FilterChip(
            label: Text(Fmt.dayNames[i].substring(0, 3)),
            tooltip: Fmt.dayNames[i],
            selected: _days.contains(Fmt.dayKeys[i]),
            onSelected: (on) => setState(() => on ? _days.add(Fmt.dayKeys[i]) : _days.remove(Fmt.dayKeys[i])),
          ),
      ]),
      const SizedBox(height: Space.lg),
      Text(S.grace(_grace), style: t.textTheme.labelLarge),
      Slider(
        value: _grace.toDouble(),
        min: 0,
        max: 60,
        divisions: 12,
        label: '$_grace min',
        semanticFormatterCallback: (v) => S.graceSemantics(v.round()),
        onChanged: (v) => setState(() => _grace = v.round()),
      ),
      Text(S.graceHelp,
          style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant)),
      const SizedBox(height: Space.lg),
      FilledButton.tonal(
        onPressed: _saving ? null : _save,
        child: _saving
            ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
            : const Text(S.saveSchedule),
      ),
      if (_exists) ...[
        const SizedBox(height: Space.xl),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _remove,
            style: TextButton.styleFrom(foregroundColor: t.colorScheme.error),
            icon: const Icon(Icons.event_busy_outlined),
            label: const Text(S.removeSchedule),
          ),
        ),
      ],
    ]);
  }
}
