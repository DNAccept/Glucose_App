import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme.dart';
import '../state/auth_providers.dart';
import 'root_shell.dart';
import 'screens/login_screen.dart';

/// Gates the app behind login: shows a splash while the persisted session
/// is being resolved, then either [RootShell] or [LoginScreen].
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);

    if (!authState.hasValue && authState.isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.bg,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final user = authState.valueOrNull;
    return user != null ? const RootShell() : const LoginScreen();
  }
}
