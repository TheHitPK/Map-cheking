import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'chofer_controller.dart';

/// The only driver screen: line, (first time) unit + PIN, and the big button.
class ChoferScreen extends ConsumerStatefulWidget {
  const ChoferScreen({super.key});

  @override
  ConsumerState<ChoferScreen> createState() => _ChoferScreenState();
}

class _ChoferScreenState extends ConsumerState<ChoferScreen> {
  final _veh = TextEditingController();
  final _pin = TextEditingController();

  @override
  void dispose() {
    _veh.dispose();
    _pin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(choferProvider);
    final c = ref.read(choferProvider.notifier);
    final theme = Theme.of(context);

    if (s.loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    // Keeps the service alive when the driver leaves the app with the back button.
    return WithForegroundTask(
      child: Scaffold(
        appBar: AppBar(title: const Text('TransMcbo Chofer')),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              DropdownButtonFormField<String>(
                initialValue: s.lines.any((l) => l.id == s.line) ? s.line : null,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Línea', border: OutlineInputBorder()),
                items: [for (final l in s.lines) DropdownMenuItem(value: l.id, child: Text(l.name))],
                onChanged: s.inService ? null : (v) => v == null ? null : c.selectLine(v),
              ),
              const SizedBox(height: 16),
              if (s.veh == null) ...[
                TextField(
                  controller: _veh,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(labelText: 'Número de unidad', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _pin,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(labelText: 'PIN', border: OutlineInputBorder()),
                ),
              ] else
                Row(
                  children: [
                    Text('Unidad ${s.veh}', style: theme.textTheme.titleMedium),
                    const Spacer(),
                    TextButton(onPressed: s.inService ? null : c.changeUnit, child: const Text('Cambiar unidad')),
                  ],
                ),
              const SizedBox(height: 32),
              SizedBox(
                height: 120,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: s.inService ? theme.colorScheme.error : theme.colorScheme.primary,
                    textStyle: theme.textTheme.headlineSmall,
                  ),
                  onPressed: s.busy
                      ? null
                      : s.inService
                          ? c.stopService
                          : () => c.startService(
                                veh: s.veh == null ? int.tryParse(_veh.text) : null,
                                pin: s.veh == null && _pin.text.isNotEmpty ? _pin.text : null,
                              ),
                  child: s.busy
                      ? const CircularProgressIndicator()
                      : Text(s.inService ? 'Fuera de servicio' : 'En servicio'),
                ),
              ),
              const SizedBox(height: 20),
              if (s.inService)
                Text(
                  s.connected
                      ? 'Enviando ubicación'
                      : s.pending > 0
                          ? 'Sin señal · ${s.pending} posiciones guardadas'
                          : 'Conectando…',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium,
                ),
              if (s.error != null) ...[
                const SizedBox(height: 12),
                Text(s.error!, textAlign: TextAlign.center, style: TextStyle(color: theme.colorScheme.error)),
              ],
              if (kDebugMode) ...[
                const SizedBox(height: 24),
                Text('Datos de la sesión: ${s.kb.toStringAsFixed(1)} KB',
                    textAlign: TextAlign.center, style: theme.textTheme.bodySmall),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
