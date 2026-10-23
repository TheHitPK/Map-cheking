import 'package:flutter/material.dart';

import '../../../core/strings.dart';
import '../../payroll/presentation/my_pay_page.dart';
import 'worker_home_screen.dart';

/// Crew home: punch in/out and my pay. Both stay alive so the GPS fix and the punch state survive tab switches.
class WorkerShell extends StatefulWidget {
  const WorkerShell({super.key});

  @override
  State<WorkerShell> createState() => _WorkerShellState();
}

class _WorkerShellState extends State<WorkerShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: IndexedStack(index: _index, children: const [WorkerHomeScreen(), MyPayPage()]),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.pin_drop_outlined), selectedIcon: Icon(Icons.pin_drop), label: S.navPunch),
            NavigationDestination(icon: Icon(Icons.payments_outlined), selectedIcon: Icon(Icons.payments), label: S.navMyPay),
          ],
        ),
      );
}
