import 'app/bootstrap.dart';
import 'app/config.dart';
import 'core/strings.dart';
import 'features/worker/presentation/location_disclosure.dart';
import 'features/worker/presentation/worker_home_screen.dart';

/// flutter run --flavor trabajador -t lib/main_trabajador.dart
void main() => bootstrap(
      role: AppRole.worker,
      title: S.appName,
      home: (_) => const LocationDisclosureGate(child: WorkerHomeScreen()),
    );
