import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

import '../models/app_user.dart';
import 'app_database.dart';

class AuthException implements Exception {
  AuthException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Local-only accounts: there is no backend, so "authentication" is a
/// salted-hash check against the [Users] table in the on-device database.
/// This gates access to the app; it does not partition glucose history or
/// reference readings per account.
class AuthRepository {
  AuthRepository(this._db);

  final AppDatabase _db;
  static final _random = Random.secure();

  Future<AppUser> register(String username, String password) async {
    final normalized = username.trim();
    if (normalized.length < 3) {
      throw AuthException('Username must be at least 3 characters.');
    }
    if (password.length < 6) {
      throw AuthException('Password must be at least 6 characters.');
    }

    final existing = await (_db.select(_db.users)..where((t) => t.username.equals(normalized))).getSingleOrNull();
    if (existing != null) {
      throw AuthException('That username is already taken.');
    }

    final salt = _generateSalt();
    final hash = _hash(password, salt);
    final id = await _db.into(_db.users).insert(UsersCompanion.insert(
          username: normalized,
          passwordHash: hash,
          passwordSalt: salt,
          createdAt: DateTime.now(),
        ));
    return AppUser(id: id, username: normalized);
  }

  Future<AppUser> login(String username, String password) async {
    final normalized = username.trim();
    final row = await (_db.select(_db.users)..where((t) => t.username.equals(normalized))).getSingleOrNull();
    if (row == null) {
      throw AuthException('No account with that username.');
    }
    final hash = _hash(password, row.passwordSalt);
    if (hash != row.passwordHash) {
      throw AuthException('Incorrect password.');
    }
    return AppUser(id: row.id, username: row.username);
  }

  Future<AppUser?> getUserById(int id) async {
    final row = await (_db.select(_db.users)..where((t) => t.id.equals(id))).getSingleOrNull();
    if (row == null) return null;
    return AppUser(id: row.id, username: row.username);
  }

  static String _generateSalt() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
    return base64UrlEncode(bytes);
  }

  static String _hash(String password, String salt) {
    return sha256.convert(utf8.encode('$salt:$password')).toString();
  }
}
