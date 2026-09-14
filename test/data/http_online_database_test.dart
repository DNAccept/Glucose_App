import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:glucose_monitor/data/online_database_service.dart';

void main() {
  late HttpServer mockServer;
  late OnlineDatabaseService onlineDb;
  late String mockUrl;

  setUp(() async {
    // Start local HttpServer on ephemeral port for unit testing HTTP REST operations
    mockServer = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    mockUrl = 'http://localhost:${mockServer.port}';

    onlineDb = OnlineDatabaseService(isOnline: true, serverUrl: mockUrl);

    mockServer.listen((request) async {
      final path = request.uri.path;
      final bodyStr = await utf8.decoder.bind(request).join();
      final body = bodyStr.isNotEmpty ? jsonDecode(bodyStr) : {};
      final authHeader = request.headers.value('authorization');

      request.response.headers.contentType = ContentType.json;

      if (path == '/api/health') {
        request.response.write(jsonEncode({'status': 'ok'}));
      } else if (path == '/api/register') {
        request.response.write(jsonEncode({
          'id': 2002,
          'username': body['username'],
          'passwordHash': body['passwordHash'],
          'passwordSalt': body['passwordSalt'],
          'createdAt': body['createdAt'] ?? DateTime.now().toIso8601String(),
          'token': 'valid-bearer-token-2002',
        }));
      } else if (path == '/api/login') {
        request.response.write(jsonEncode({
          'id': 2002,
          'username': body['username'],
          'passwordHash': body['passwordHash'],
          'passwordSalt': 'salt',
          'createdAt': DateTime.now().toIso8601String(),
          'token': 'valid-bearer-token-2002',
        }));
      } else if (path == '/api/readings/push') {
        if (authHeader != 'Bearer valid-bearer-token-2002') {
          request.response.statusCode = 401;
          request.response.write(jsonEncode({'error': 'Missing or invalid authentication token.'}));
        } else if (body['userId'] != 2002) {
          request.response.statusCode = 403;
          request.response.write(jsonEncode({'error': 'Access denied: token user ID mismatch.'}));
        } else {
          request.response.write(jsonEncode(body['readings']));
        }
      } else if (path == '/api/readings/pull') {
        final queryUserId = int.tryParse(request.uri.queryParameters['user_id'] ?? '');
        if (authHeader != 'Bearer valid-bearer-token-2002') {
          request.response.statusCode = 401;
          request.response.write(jsonEncode({'error': 'Missing or invalid authentication token.'}));
        } else if (queryUserId != 2002) {
          request.response.statusCode = 403;
          request.response.write(jsonEncode({'error': 'Access denied: token user ID mismatch.'}));
        } else {
          request.response.write(jsonEncode([
            {
              'uuid': 'http-uuid-1',
              'userId': 2002,
              'timestamp': DateTime.now().toIso8601String(),
              'mgDl': 118.5,
              'glucoseClass': 1,
              'confidence': 92,
              'lastModified': DateTime.now().toIso8601String(),
              'isDeleted': false,
            }
          ]));
        }
      } else {
        request.response.statusCode = 404;
        request.response.write(jsonEncode({'error': 'Not found'}));
      }
      await request.response.close();
    });
  });

  tearDown(() async {
    onlineDb.dispose();
    await mockServer.close();
  });

  test('checkHealth returns true when server responds', () async {
    final ok = await onlineDb.checkHealth();
    expect(ok, isTrue);
  });

  test('register sends POST request and receives bearer token', () async {
    final user = await onlineDb.register('httpuser', 'hash', 'salt');
    expect(user.username, 'httpuser');
    expect(user.id, 2002);
    expect(user.token, 'valid-bearer-token-2002');
    expect(onlineDb.authToken, 'valid-bearer-token-2002');
  });

  test('login sends POST request and receives bearer token', () async {
    final user = await onlineDb.login('httpuser', 'hash');
    expect(user.username, 'httpuser');
    expect(user.id, 2002);
    expect(user.token, 'valid-bearer-token-2002');
    expect(onlineDb.authToken, 'valid-bearer-token-2002');
  });

  test('pushReadings and pullReadings include bearer token and succeed for matching user', () async {
    // Set token
    onlineDb.authToken = 'valid-bearer-token-2002';

    final reading = RemoteReading(
      uuid: 'http-uuid-1',
      userId: 2002,
      timestamp: DateTime.now(),
      mgDl: 118.5,
      glucoseClass: 1,
      confidence: 92,
      lastModified: DateTime.now(),
    );

    final pushed = await onlineDb.pushReadings(2002, [reading]);
    expect(pushed.length, 1);
    expect(pushed.first.uuid, 'http-uuid-1');

    final pulled = await onlineDb.pullReadings(2002);
    expect(pulled.length, 1);
    expect(pulled.first.mgDl, 118.5);
  });

  test('pushReadings fails with 401 when token is invalid or missing', () async {
    onlineDb.authToken = 'invalid-token';
    final reading = RemoteReading(
      uuid: 'http-uuid-1',
      userId: 2002,
      timestamp: DateTime.now(),
      mgDl: 118.5,
      glucoseClass: 1,
      confidence: 92,
      lastModified: DateTime.now(),
    );

    expect(
      () => onlineDb.pushReadings(2002, [reading]),
      throwsA(isA<OnlineDatabaseException>().having(
        (e) => e.message,
        'message',
        contains('Missing or invalid authentication token'),
      )),
    );
  });

  test('pullReadings fails with 403 when requesting data of another user', () async {
    onlineDb.authToken = 'valid-bearer-token-2002'; // token belongs to 2002

    expect(
      () => onlineDb.pullReadings(9999), // trying to pull user 9999's data
      throwsA(isA<OnlineDatabaseException>().having(
        (e) => e.message,
        'message',
        contains('Access denied: token user ID mismatch'),
      )),
    );
  });
}
