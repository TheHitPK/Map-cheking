import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'pasajero/pasajero_screen.dart';
import 'shell.dart';

/// flutter run --flavor pasajero -t lib/main_pasajero.dart
void main() => runApp(const ProviderScope(child: RoleApp(title: 'TransMcbo', home: PasajeroScreen())));
