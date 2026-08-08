import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_repository.dart';
import '../models/app_user.dart';
import 'data_providers.dart';

const _sessionUserIdKey = 'session_user_id';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(databaseProvider));
});

/// Resolves the persisted session (if any) on boot, and exposes
/// login/register/logout actions. `AsyncData(null)` means "resolved, no one
/// is logged in" — distinct from the initial loading state, so [AuthGate]
/// can tell "still checking" apart from "show the login screen".
class AuthController extends AsyncNotifier<AppUser?> {
  @override
  Future<AppUser?> build() async {
    final prefs = ref.watch(sharedPreferencesProvider);
    final id = prefs.getInt(_sessionUserIdKey);
    if (id == null) return null;
    return ref.read(authRepositoryProvider).getUserById(id);
  }

  Future<void> login(String username, String password) async {
    state = const AsyncLoading<AppUser?>().copyWithPrevious(state);
    state = await AsyncValue.guard(() async {
      final user = await ref.read(authRepositoryProvider).login(username, password);
      await ref.read(sharedPreferencesProvider).setInt(_sessionUserIdKey, user.id);
      return user;
    });
  }

  Future<void> register(String username, String password) async {
    state = const AsyncLoading<AppUser?>().copyWithPrevious(state);
    state = await AsyncValue.guard(() async {
      final user = await ref.read(authRepositoryProvider).register(username, password);
      await ref.read(sharedPreferencesProvider).setInt(_sessionUserIdKey, user.id);
      return user;
    });
  }

  Future<void> logout() async {
    await ref.read(sharedPreferencesProvider).remove(_sessionUserIdKey);
    state = const AsyncData(null);
  }
}

final authControllerProvider = AsyncNotifierProvider<AuthController, AppUser?>(AuthController.new);
