import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glucose_monitor/data/online_database_service.dart';
import 'package:glucose_monitor/state/data_providers.dart';
import 'package:glucose_monitor/state/sync_providers.dart';
import 'package:glucose_monitor/ui/widgets/connectivity_badge.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late OnlineDatabaseService mockOnlineDb;
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    mockOnlineDb = OnlineDatabaseService(isOnline: true, serverUrl: '');
  });

  tearDown(() {
    mockOnlineDb.dispose();
  });

  testWidgets('ConnectivityBadge renders Cloud Synced when online', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          onlineDatabaseServiceProvider.overrideWithValue(mockOnlineDb),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: ConnectivityBadge(),
          ),
        ),
      ),
    );

    expect(find.text('Cloud Synced'), findsOneWidget);
  });

  testWidgets('ConnectivityBadge renders Offline Mode when offline', (tester) async {
    mockOnlineDb.setOnlineForTesting(false);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          onlineDatabaseServiceProvider.overrideWithValue(mockOnlineDb),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: ConnectivityBadge(),
          ),
        ),
      ),
    );

    expect(find.text('Offline Mode (Local Storage)'), findsOneWidget);
  });
}
