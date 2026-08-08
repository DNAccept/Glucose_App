import 'package:flutter/material.dart';

import 'core/theme.dart';
import 'ui/auth_gate.dart';

class GlucoseMonitorApp extends StatelessWidget {
  const GlucoseMonitorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Glucose Monitor',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const AuthGate(),
    );
  }
}
