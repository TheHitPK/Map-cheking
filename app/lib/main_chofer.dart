import 'package:flutter/widgets.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'chofer/chofer_screen.dart';
import 'shell.dart';

/// flutter run --flavor chofer -t lib/main_chofer.dart
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterForegroundTask.initCommunicationPort();
  runApp(const ProviderScope(child: RoleApp(title: 'TransMcbo Chofer', home: ChoferScreen())));
}
