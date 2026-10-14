import 'package:flutter/material.dart';

class RoleApp extends StatelessWidget {
  const RoleApp({super.key, required this.title, required this.home});

  final String title;
  final Widget home;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: title,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: const Color(0xFF0B6E4F), useMaterial3: true),
      home: home,
    );
  }
}

/// Temporary screen until each role's UI is built (F2 chofer, F3 pasajero).
class ComingSoon extends StatelessWidget {
  const ComingSoon({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Scaffold(body: Center(child: Text(text)));
}
