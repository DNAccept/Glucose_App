import 'package:flutter_test/flutter_test.dart';
import 'package:glucose_monitor/data/online_database_service.dart';

void main() {
  late OnlineDatabaseService onlineDb;

  setUp(() {
    onlineDb = OnlineDatabaseService(isOnline: true, serverUrl: '');
  });

  tearDown(() {
    onlineDb.dispose();
  });

  test('register and login remote user', () async {
    final user = await onlineDb.register('testuser', 'hash123', 'salt123');
    expect(user.username, 'testuser');
    expect(user.id, greaterThan(0));

    final loggedIn = await onlineDb.login('testuser', 'hash123');
    expect(loggedIn.id, user.id);
  });

  test('throws OnlineDatabaseException when offline', () async {
    onlineDb.setOnlineForTesting(false);
    expect(
      () => onlineDb.register('user2', 'hash', 'salt'),
      throwsA(isA<OnlineDatabaseException>()),
    );
  });

  test('push and pull remote readings', () async {
    final user = await onlineDb.register('user3', 'hash', 'salt');
    final reading = RemoteReading(
      uuid: 'uuid-1',
      userId: user.id,
      timestamp: DateTime.now(),
      mgDl: 120.0,
      glucoseClass: 1,
      confidence: 95,
      lastModified: DateTime.now(),
    );

    await onlineDb.pushReadings(user.id, [reading]);
    final pulled = await onlineDb.pullReadings(user.id);

    expect(pulled.length, 1);
    expect(pulled.first.uuid, 'uuid-1');
    expect(pulled.first.mgDl, 120.0);
  });
}
