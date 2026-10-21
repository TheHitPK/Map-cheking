import 'app/bootstrap.dart';
import 'app/config.dart';
import 'features/worker/presentation/worker_home_screen.dart';

/// flutter run --flavor trabajador -t lib/main_trabajador.dart
void main() => bootstrap(role: AppRole.worker, title: 'Asistencia', home: (_) => const WorkerHomeScreen());
