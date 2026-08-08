import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glucose_monitor/data/app_database.dart';
import 'package:glucose_monitor/data/auth_repository.dart';

void main() {
  late AppDatabase db;
  late AuthRepository auth;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    auth = AuthRepository(db);
  });

  tearDown(() => db.close());

  test('register creates an account and login accepts the same password', () async {
    final registered = await auth.register('alice', 'hunter22');
    expect(registered.username, 'alice');

    final loggedIn = await auth.login('alice', 'hunter22');
    expect(loggedIn.id, registered.id);
  });

  test('register rejects a duplicate username', () async {
    await auth.register('bob', 'password1');
    expect(() => auth.register('bob', 'somethingElse'), throwsA(isA<AuthException>()));
  });

  test('register rejects a short username or password', () async {
    expect(() => auth.register('ab', 'password1'), throwsA(isA<AuthException>()));
    expect(() => auth.register('validname', 'short'), throwsA(isA<AuthException>()));
  });

  test('login rejects an unknown username', () async {
    expect(() => auth.login('nobody', 'whatever1'), throwsA(isA<AuthException>()));
  });

  test('login rejects the wrong password', () async {
    await auth.register('carol', 'correctPass1');
    expect(() => auth.login('carol', 'wrongPass1'), throwsA(isA<AuthException>()));
  });

  test('two users with the same password get different stored hashes (per-user salt)', () async {
    await auth.register('dave', 'samePassword1');
    await auth.register('erin', 'samePassword1');

    final daveRow = await (db.select(db.users)..where((t) => t.username.equals('dave'))).getSingle();
    final erinRow = await (db.select(db.users)..where((t) => t.username.equals('erin'))).getSingle();

    expect(daveRow.passwordSalt, isNot(erinRow.passwordSalt));
    expect(daveRow.passwordHash, isNot(erinRow.passwordHash));
  });

  test('getUserById returns null for an unknown id', () async {
    expect(await auth.getUserById(999), isNull);
  });
}
