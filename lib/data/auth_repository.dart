import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';

import '../models/app_user.dart';
import 'app_database.dart';
import 'online_database_service.dart';

class AuthException implements Exception {
  AuthException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Manages authentication against the Online Database (when available)
/// and local SQLite database (for offline usage and local session caching).
class AuthRepository {
  AuthRepository(this._db, [this._onlineDb]);

  final AppDatabase _db;
  final OnlineDatabaseService? _onlineDb;
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

    int? remoteId;
    int syncStatus = SyncStatus.pendingSync;
    DateTime? lastSyncedAt;

    final onlineDb = _onlineDb;
    if (onlineDb != null && onlineDb.isOnline) {
      try {
        final remoteUser = await onlineDb.register(normalized, hash, salt);
        remoteId = remoteUser.id;
        syncStatus = SyncStatus.synced;
        lastSyncedAt = DateTime.now();
      } catch (e) {
        if (e is OnlineDatabaseException) {
          throw AuthException(e.message);
        }
        rethrow;
      }
    }

    final id = await _db.into(_db.users).insert(UsersCompanion.insert(
          username: normalized,
          passwordHash: hash,
          passwordSalt: salt,
          createdAt: DateTime.now(),
          remoteId: Value(remoteId),
          syncStatus: Value(syncStatus),
          lastSyncedAt: Value(lastSyncedAt),
        ));
    return AppUser(id: id, username: normalized);
  }

  Future<AppUser> login(String username, String password) async {
    final normalized = username.trim();
    final localRow = await (_db.select(_db.users)..where((t) => t.username.equals(normalized))).getSingleOrNull();

    final onlineDb = _onlineDb;
    if (onlineDb != null && onlineDb.isOnline) {
      // Try online login first
      final salt = localRow?.passwordSalt ?? _generateSalt();
      final hash = _hash(password, salt);

      try {
        final remoteUser = await onlineDb.login(normalized, hash);
        if (localRow == null) {
          // Cache user in local SQLite for offline access
          final localId = await _db.into(_db.users).insert(UsersCompanion.insert(
                username: normalized,
                passwordHash: hash,
                passwordSalt: salt,
                createdAt: DateTime.now(),
                remoteId: Value(remoteUser.id),
                syncStatus: const Value(SyncStatus.synced),
                lastSyncedAt: Value(DateTime.now()),
              ));
          return AppUser(id: localId, username: normalized);
        } else {
          // Update remote ID and last synced timestamp
          await (_db.update(_db.users)..where((t) => t.id.equals(localRow.id))).write(
            UsersCompanion(
              remoteId: Value(remoteUser.id),
              syncStatus: const Value(SyncStatus.synced),
              lastSyncedAt: Value(DateTime.now()),
            ),
          );
          return AppUser(id: localRow.id, username: localRow.username);
        }
      } on OnlineDatabaseException catch (e) {
        // If local user exists, fallback to offline verification
        if (localRow == null) {
          throw AuthException(e.message);
        }
      }
    }

    // Offline verification against local SQLite database
    if (localRow == null) {
      throw AuthException('No account with that username.');
    }
    final hash = _hash(password, localRow.passwordSalt);
    if (hash != localRow.passwordHash) {
      throw AuthException('Incorrect password.');
    }
    return AppUser(id: localRow.id, username: localRow.username);
  }

  Future<AppUser?> getUserById(int id) async {
    final row = await (_db.select(_db.users)..where((t) => t.id.equals(id))).getSingleOrNull();
    if (row == null) return null;
    return AppUser(id: row.id, username: row.username);
  }

  Future<AppUser> updateUsername(int userId, String newUsername) async {
    final normalized = newUsername.trim();
    if (normalized.length < 3) {
      throw AuthException('Username must be at least 3 characters.');
    }

    final localRow = await (_db.select(_db.users)..where((t) => t.id.equals(userId))).getSingleOrNull();
    if (localRow == null) {
      throw AuthException('User account not found.');
    }

    final existing = await (_db.select(_db.users)..where((t) => t.username.equals(normalized) & t.id.equals(userId).not())).getSingleOrNull();
    if (existing != null) {
      throw AuthException('That username is already taken.');
    }

    final onlineDb = _onlineDb;
    if (onlineDb != null && onlineDb.isOnline && localRow.remoteId != null) {
      try {
        await onlineDb.updateUser(
          userId: localRow.remoteId!,
          newUsername: normalized,
        );
      } on OnlineDatabaseException catch (e) {
        throw AuthException(e.message);
      }
    }

    await (_db.update(_db.users)..where((t) => t.id.equals(userId))).write(
      UsersCompanion(
        username: Value(normalized),
        lastSyncedAt: Value(DateTime.now()),
      ),
    );

    return AppUser(id: userId, username: normalized);
  }

  Future<void> updatePassword(int userId, String currentPassword, String newPassword) async {
    if (newPassword.length < 6) {
      throw AuthException('New password must be at least 6 characters.');
    }

    final localRow = await (_db.select(_db.users)..where((t) => t.id.equals(userId))).getSingleOrNull();
    if (localRow == null) {
      throw AuthException('User account not found.');
    }

    final currentHash = _hash(currentPassword, localRow.passwordSalt);
    if (currentHash != localRow.passwordHash) {
      throw AuthException('Current password is incorrect.');
    }

    final newSalt = _generateSalt();
    final newHash = _hash(newPassword, newSalt);

    final onlineDb = _onlineDb;
    if (onlineDb != null && onlineDb.isOnline && localRow.remoteId != null) {
      try {
        await onlineDb.updateUser(
          userId: localRow.remoteId!,
          newPasswordHash: newHash,
          newPasswordSalt: newSalt,
        );
      } on OnlineDatabaseException catch (e) {
        throw AuthException(e.message);
      }
    }

    await (_db.update(_db.users)..where((t) => t.id.equals(userId))).write(
      UsersCompanion(
        passwordHash: Value(newHash),
        passwordSalt: Value(newSalt),
        lastSyncedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> deleteAccount(int userId, String currentPassword) async {
    final localRow = await (_db.select(_db.users)..where((t) => t.id.equals(userId))).getSingleOrNull();
    if (localRow == null) {
      throw AuthException('User account not found.');
    }

    final currentHash = _hash(currentPassword, localRow.passwordSalt);
    if (currentHash != localRow.passwordHash) {
      throw AuthException('Incorrect password.');
    }

    final onlineDb = _onlineDb;
    if (onlineDb != null && onlineDb.isOnline && localRow.remoteId != null) {
      try {
        await onlineDb.deleteUser(localRow.remoteId!);
      } on OnlineDatabaseException catch (_) {
        // Continue with local deletion
      }
    }

    await (_db.delete(_db.readings)..where((t) => t.userId.equals(userId))).go();
    await (_db.delete(_db.referenceReadings)..where((t) => t.userId.equals(userId))).go();
    await (_db.delete(_db.userSettings)..where((t) => t.userId.equals(userId))).go();
    await (_db.delete(_db.users)..where((t) => t.id.equals(userId))).go();
  }

  static String _generateSalt() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
    return base64UrlEncode(bytes);
  }

  static String _hash(String password, String salt) {
    return sha256.convert(utf8.encode('$salt:$password')).toString();
  }
}

