import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../core/config.dart';

class OnlineDatabaseException implements Exception {
  OnlineDatabaseException(this.message);
  final String message;

  @override
  String toString() => message;
}

class RemoteUser {
  RemoteUser({
    required this.id,
    required this.username,
    required this.passwordHash,
    required this.passwordSalt,
    required this.createdAt,
    this.token,
  });

  final int id;
  final String username;
  final String passwordHash;
  final String passwordSalt;
  final DateTime createdAt;
  final String? token;

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'passwordHash': passwordHash,
        'passwordSalt': passwordSalt,
        'createdAt': createdAt.toIso8601String(),
        if (token != null) 'token': token,
      };

  factory RemoteUser.fromJson(Map<String, dynamic> json) => RemoteUser(
        id: json['id'] as int,
        username: json['username'] as String,
        passwordHash: json['passwordHash'] as String,
        passwordSalt: json['passwordSalt'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        token: json['token'] as String?,
      );
}

class RemoteReading {
  RemoteReading({
    required this.uuid,
    required this.userId,
    required this.timestamp,
    required this.mgDl,
    required this.glucoseClass,
    required this.confidence,
    required this.lastModified,
    this.isDeleted = false,
  });

  final String uuid;
  final int userId;
  final DateTime timestamp;
  final double mgDl;
  final int glucoseClass;
  final int confidence;
  final DateTime lastModified;
  final bool isDeleted;

  Map<String, dynamic> toJson() => {
        'uuid': uuid,
        'userId': userId,
        'timestamp': timestamp.toIso8601String(),
        'mgDl': mgDl,
        'glucoseClass': glucoseClass,
        'confidence': confidence,
        'lastModified': lastModified.toIso8601String(),
        'isDeleted': isDeleted,
      };

  factory RemoteReading.fromJson(Map<String, dynamic> json) => RemoteReading(
        uuid: json['uuid'] as String,
        userId: json['userId'] as int,
        timestamp: DateTime.parse(json['timestamp'] as String),
        mgDl: (json['mgDl'] as num).toDouble(),
        glucoseClass: json['glucoseClass'] as int,
        confidence: json['confidence'] as int,
        lastModified: DateTime.parse(json['lastModified'] as String),
        isDeleted: json['isDeleted'] as bool? ?? false,
      );
}

class RemoteReferenceReading {
  RemoteReferenceReading({
    required this.uuid,
    required this.userId,
    required this.referenceValueMgDl,
    required this.referenceClass,
    this.deviceMgDl,
    this.deviceClass,
    this.deviceConfidence,
    required this.timestamp,
    required this.lastModified,
    this.isDeleted = false,
  });

  final String uuid;
  final int userId;
  final int referenceValueMgDl;
  final int referenceClass;
  final double? deviceMgDl;
  final int? deviceClass;
  final int? deviceConfidence;
  final DateTime timestamp;
  final DateTime lastModified;
  final bool isDeleted;

  Map<String, dynamic> toJson() => {
        'uuid': uuid,
        'userId': userId,
        'referenceValueMgDl': referenceValueMgDl,
        'referenceClass': referenceClass,
        'deviceMgDl': deviceMgDl,
        'deviceClass': deviceClass,
        'deviceConfidence': deviceConfidence,
        'timestamp': timestamp.toIso8601String(),
        'lastModified': lastModified.toIso8601String(),
        'isDeleted': isDeleted,
      };

  factory RemoteReferenceReading.fromJson(Map<String, dynamic> json) => RemoteReferenceReading(
        uuid: json['uuid'] as String,
        userId: json['userId'] as int,
        referenceValueMgDl: json['referenceValueMgDl'] as int,
        referenceClass: json['referenceClass'] as int,
        deviceMgDl: json['deviceMgDl'] != null ? (json['deviceMgDl'] as num).toDouble() : null,
        deviceClass: json['deviceClass'] as int?,
        deviceConfidence: json['deviceConfidence'] as int?,
        timestamp: DateTime.parse(json['timestamp'] as String),
        lastModified: DateTime.parse(json['lastModified'] as String),
        isDeleted: json['isDeleted'] as bool? ?? false,
      );
}

class RemoteUserSettings {
  RemoteUserSettings({
    required this.userId,
    required this.alertsEnabled,
    required this.cloudSyncEnabled,
    required this.lastModified,
  });

  final int userId;
  final bool alertsEnabled;
  final bool cloudSyncEnabled;
  final DateTime lastModified;

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'alertsEnabled': alertsEnabled,
        'cloudSyncEnabled': cloudSyncEnabled,
        'lastModified': lastModified.toIso8601String(),
      };

  factory RemoteUserSettings.fromJson(Map<String, dynamic> json) => RemoteUserSettings(
        userId: json['userId'] as int,
        alertsEnabled: json['alertsEnabled'] as bool,
        cloudSyncEnabled: json['cloudSyncEnabled'] as bool,
        lastModified: DateTime.parse(json['lastModified'] as String),
      );
}

/// Online Cloud Database Client with Bearer Token Authentication.
class OnlineDatabaseService {
  OnlineDatabaseService({
    bool isOnline = true,
    this.serverUrl = 'http://127.0.0.1:8080',
    this.authToken,
    http.Client? httpClient,
  })  : _isOnline = isOnline,
        _client = httpClient ?? http.Client() {
    _startHealthCheckTimer();
    verifyConnection();
  }

  bool _isOnline;
  bool get isOnline => _isOnline;

  String? serverUrl;
  String? authToken;

  void updateServerUrl(String newUrl) {
    serverUrl = newUrl.trim();
    print('[HTTP CONFIG] Server URL updated to: "$serverUrl"');
    verifyConnection();
  }

  Map<String, String> _authHeaders() {
    final headers = {'Content-Type': 'application/json'};
    if (authToken != null && authToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $authToken';
    }
    return headers;
  }

  final http.Client _client;
  Timer? _healthCheckTimer;
  final _connectivityController = StreamController<bool>.broadcast();
  Stream<bool> get connectivityStream => _connectivityController.stream;

  void _startHealthCheckTimer() {
    _healthCheckTimer?.cancel();
    _healthCheckTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      verifyConnection();
    });
  }

  void _setOnlineStatus(bool online) {
    if (_isOnline != online) {
      _isOnline = online;
      if (!_connectivityController.isClosed) {
        _connectivityController.add(online);
      }
    }
  }

  /// Actively checks whether the online feature server URL is reachable.
  /// First pings current serverUrl if available; if unreachable, probes all fallback candidate IPs in parallel.
  Future<bool> verifyConnection() async {
    if (serverUrl != null && serverUrl!.trim().isNotEmpty) {
      final baseUrl = serverUrl!.trim().endsWith('/')
          ? serverUrl!.trim().substring(0, serverUrl!.trim().length - 1)
          : serverUrl!.trim();
      try {
        final res = await _client.get(Uri.parse('$baseUrl/api/health')).timeout(const Duration(seconds: 1));
        if (res.statusCode == 200) {
          print('[HTTP SUCCESS] Connected to online database server at $baseUrl');
          serverUrl = baseUrl;
          _setOnlineStatus(true);
          return true;
        }
      } catch (_) {}
    }

    final candidateUrls = AppConfig.getCandidateUrls(serverUrl);
    final futures = candidateUrls.map((candidate) async {
      final baseUrl = candidate.endsWith('/') ? candidate.substring(0, candidate.length - 1) : candidate;
      final url = '$baseUrl/api/health';
      try {
        final res = await _client.get(Uri.parse(url)).timeout(const Duration(seconds: 2));
        if (res.statusCode == 200) {
          return baseUrl;
        }
      } catch (_) {}
      return null;
    });

    final results = await Future.wait(futures);
    final workingUrl = results.firstWhere((url) => url != null, orElse: () => null);

    if (workingUrl != null) {
      print('[HTTP SUCCESS] Connected to online database server at $workingUrl');
      serverUrl = workingUrl;
      _setOnlineStatus(true);
      return true;
    } else {
      print('[HTTP ERROR] All server URL candidates failed.');
      _setOnlineStatus(false);
      return false;
    }
  }

  // Fallback in-memory cloud datastores (when serverUrl is null/empty)
  final Map<int, RemoteUser> _usersById = {};
  final Map<String, RemoteUser> _usersByUsername = {};
  final Map<String, RemoteReading> _readingsByUuid = {};
  final Map<String, RemoteReferenceReading> _referencesByUuid = {};
  final Map<int, RemoteUserSettings> _settingsByUserId = {};
  int _nextUserId = 1001;

  void _checkOnline() {
    if (!_isOnline) {
      throw OnlineDatabaseException('Network connection unavailable (Offline mode).');
    }
  }

  void setOnlineForTesting(bool online) {
    _setOnlineStatus(online);
  }

  /// Pings the remote REST server to test connectivity.
  Future<bool> checkHealth() => verifyConnection();

  Future<RemoteUser> register(String username, String passwordHash, String passwordSalt) async {
    _checkOnline();

    if (serverUrl != null && serverUrl!.isNotEmpty) {
      try {
        final res = await _client.post(
          Uri.parse('$serverUrl/api/register'),
          headers: _authHeaders(),
          body: jsonEncode({
            'username': username,
            'passwordHash': passwordHash,
            'passwordSalt': passwordSalt,
            'createdAt': DateTime.now().toIso8601String(),
          }),
        ).timeout(const Duration(seconds: 5));

        if (res.statusCode == 200) {
          final user = RemoteUser.fromJson(jsonDecode(res.body));
          if (user.token != null) authToken = user.token;
          return user;
        } else {
          final body = jsonDecode(res.body);
          throw OnlineDatabaseException(body['error'] ?? 'Failed to register account on cloud server.');
        }
      } catch (e) {
        if (e is OnlineDatabaseException) rethrow;
        throw OnlineDatabaseException('Server error: ${e.toString()}');
      }
    }

    // In-memory fallback
    final normalized = username.trim().toLowerCase();
    if (_usersByUsername.containsKey(normalized)) {
      throw OnlineDatabaseException('Username already registered in cloud database.');
    }
    final user = RemoteUser(
      id: _nextUserId++,
      username: username.trim(),
      passwordHash: passwordHash,
      passwordSalt: passwordSalt,
      createdAt: DateTime.now(),
      token: 'mock-token-${_nextUserId}',
    );
    _usersById[user.id] = user;
    _usersByUsername[normalized] = user;
    authToken = user.token;
    return user;
  }

  Future<RemoteUser> login(String username, String passwordHash) async {
    _checkOnline();

    if (serverUrl != null && serverUrl!.isNotEmpty) {
      try {
        final res = await _client.post(
          Uri.parse('$serverUrl/api/login'),
          headers: _authHeaders(),
          body: jsonEncode({
            'username': username,
            'passwordHash': passwordHash,
          }),
        ).timeout(const Duration(seconds: 5));

        if (res.statusCode == 200) {
          final user = RemoteUser.fromJson(jsonDecode(res.body));
          if (user.token != null) authToken = user.token;
          return user;
        } else {
          final body = jsonDecode(res.body);
          throw OnlineDatabaseException(body['error'] ?? 'Failed to log in to cloud server.');
        }
      } catch (e) {
        if (e is OnlineDatabaseException) rethrow;
        throw OnlineDatabaseException('Server connection error: ${e.toString()}');
      }
    }

    // In-memory fallback
    final normalized = username.trim().toLowerCase();
    final user = _usersByUsername[normalized];
    if (user == null) {
      throw OnlineDatabaseException('User account not found on cloud server.');
    }
    if (user.passwordHash != passwordHash) {
      throw OnlineDatabaseException('Invalid password for cloud user account.');
    }
    authToken = user.token ?? 'mock-token-${user.id}';
    return user;
  }

  Future<RemoteUser?> getUserById(int remoteId) async {
    _checkOnline();
    if (serverUrl != null && serverUrl!.isNotEmpty) {
      try {
        final res = await _client.get(
          Uri.parse('$serverUrl/api/user?id=$remoteId'),
          headers: _authHeaders(),
        );
        if (res.statusCode == 200) {
          return RemoteUser.fromJson(jsonDecode(res.body));
        }
        return null;
      } catch (_) {
        return null;
      }
    }
    return _usersById[remoteId];
  }

  Future<List<RemoteReading>> pushReadings(int userId, List<RemoteReading> items) async {
    _checkOnline();
    if (serverUrl != null && serverUrl!.isNotEmpty) {
      final res = await _client.post(
        Uri.parse('$serverUrl/api/readings/push'),
        headers: _authHeaders(),
        body: jsonEncode({
          'userId': userId,
          'readings': items.map((i) => i.toJson()).toList(),
        }),
      );
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List;
        return list.map((i) => RemoteReading.fromJson(i)).toList();
      } else if (res.statusCode == 401 || res.statusCode == 403) {
        final body = jsonDecode(res.body);
        throw OnlineDatabaseException(body['error'] ?? 'Unauthorized or session expired.');
      } else {
        throw OnlineDatabaseException('Failed to push readings to server.');
      }
    }

    final synced = <RemoteReading>[];
    for (final item in items) {
      final existing = _readingsByUuid[item.uuid];
      if (existing == null || item.lastModified.isAfter(existing.lastModified)) {
        _readingsByUuid[item.uuid] = item;
      }
      synced.add(_readingsByUuid[item.uuid]!);
    }
    return synced;
  }

  Future<List<RemoteReading>> pullReadings(int userId, {DateTime? since}) async {
    _checkOnline();
    if (serverUrl != null && serverUrl!.isNotEmpty) {
      var url = '$serverUrl/api/readings/pull?user_id=$userId';
      if (since != null) url += '&since=${since.toIso8601String()}';
      final res = await _client.get(
        Uri.parse(url),
        headers: _authHeaders(),
      );
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List;
        return list.map((i) => RemoteReading.fromJson(i)).toList();
      } else if (res.statusCode == 401 || res.statusCode == 403) {
        final body = jsonDecode(res.body);
        throw OnlineDatabaseException(body['error'] ?? 'Unauthorized or session expired.');
      } else {
        throw OnlineDatabaseException('Failed to pull readings from server.');
      }
    }

    return _readingsByUuid.values.where((r) {
      if (r.userId != userId) return false;
      if (since != null && r.lastModified.isBefore(since)) return false;
      return true;
    }).toList();
  }

  Future<List<RemoteReferenceReading>> pushReferences(int userId, List<RemoteReferenceReading> items) async {
    _checkOnline();
    if (serverUrl != null && serverUrl!.isNotEmpty) {
      final res = await _client.post(
        Uri.parse('$serverUrl/api/references/push'),
        headers: _authHeaders(),
        body: jsonEncode({
          'userId': userId,
          'references': items.map((i) => i.toJson()).toList(),
        }),
      );
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List;
        return list.map((i) => RemoteReferenceReading.fromJson(i)).toList();
      } else if (res.statusCode == 401 || res.statusCode == 403) {
        final body = jsonDecode(res.body);
        throw OnlineDatabaseException(body['error'] ?? 'Unauthorized or session expired.');
      } else {
        throw OnlineDatabaseException('Failed to push references to server.');
      }
    }

    final synced = <RemoteReferenceReading>[];
    for (final item in items) {
      final existing = _referencesByUuid[item.uuid];
      if (existing == null || item.lastModified.isAfter(existing.lastModified)) {
        _referencesByUuid[item.uuid] = item;
      }
      synced.add(_referencesByUuid[item.uuid]!);
    }
    return synced;
  }

  Future<List<RemoteReferenceReading>> pullReferences(int userId, {DateTime? since}) async {
    _checkOnline();
    if (serverUrl != null && serverUrl!.isNotEmpty) {
      var url = '$serverUrl/api/references/pull?user_id=$userId';
      if (since != null) url += '&since=${since.toIso8601String()}';
      final res = await _client.get(
        Uri.parse(url),
        headers: _authHeaders(),
      );
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List;
        return list.map((i) => RemoteReferenceReading.fromJson(i)).toList();
      } else if (res.statusCode == 401 || res.statusCode == 403) {
        final body = jsonDecode(res.body);
        throw OnlineDatabaseException(body['error'] ?? 'Unauthorized or session expired.');
      } else {
        throw OnlineDatabaseException('Failed to pull references from server.');
      }
    }

    return _referencesByUuid.values.where((r) {
      if (r.userId != userId) return false;
      if (since != null && r.lastModified.isBefore(since)) return false;
      return true;
    }).toList();
  }

  Future<RemoteUserSettings> pushSettings(int userId, RemoteUserSettings settings) async {
    _checkOnline();
    if (serverUrl != null && serverUrl!.isNotEmpty) {
      final res = await _client.post(
        Uri.parse('$serverUrl/api/settings/push'),
        headers: _authHeaders(),
        body: jsonEncode({
          'userId': userId,
          'settings': settings.toJson(),
        }),
      );
      if (res.statusCode == 200) {
        return RemoteUserSettings.fromJson(jsonDecode(res.body));
      } else if (res.statusCode == 401 || res.statusCode == 403) {
        final body = jsonDecode(res.body);
        throw OnlineDatabaseException(body['error'] ?? 'Unauthorized or session expired.');
      } else {
        throw OnlineDatabaseException('Failed to push settings to server.');
      }
    }

    final existing = _settingsByUserId[userId];
    if (existing == null || settings.lastModified.isAfter(existing.lastModified)) {
      _settingsByUserId[userId] = settings;
    }
    return _settingsByUserId[userId]!;
  }

  Future<RemoteUserSettings?> pullSettings(int userId) async {
    _checkOnline();
    if (serverUrl != null && serverUrl!.isNotEmpty) {
      final res = await _client.get(
        Uri.parse('$serverUrl/api/settings/pull?user_id=$userId'),
        headers: _authHeaders(),
      );
      if (res.statusCode == 200 && res.body != 'null') {
        return RemoteUserSettings.fromJson(jsonDecode(res.body));
      } else if (res.statusCode == 401 || res.statusCode == 403) {
        final body = jsonDecode(res.body);
        throw OnlineDatabaseException(body['error'] ?? 'Unauthorized or session expired.');
      }
      return null;
    }
    return _settingsByUserId[userId];
  }

  void dispose() {
    _healthCheckTimer?.cancel();
    _client.close();
    _connectivityController.close();
  }
}
