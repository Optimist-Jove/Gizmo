import 'package:flutter/material.dart';
import 'shared/theme.dart';
import 'features/auth/presentation/phone_auth_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const GizmoApp());
}

class GizmoApp extends StatelessWidget {
  const GizmoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gizmo - E2EE Messaging',
      debugShowCheckedModeBanner: false,
      theme: GizmoTheme.darkTheme,
      home: const PhoneAuthScreen(),
    );
  }
}
