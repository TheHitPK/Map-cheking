import 'app/bootstrap.dart';
import 'app/config.dart';
import 'features/supervisor/presentation/supervisor_shell.dart';

/// Android: flutter run --flavor supervisor -t lib/main_supervisor.dart
/// Web:     flutter run -d chrome -t lib/main_supervisor.dart
void main() => bootstrap(role: AppRole.supervisor, title: 'Asistencia · Supervisor', home: (_) => const SupervisorShell());
