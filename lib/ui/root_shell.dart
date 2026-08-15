import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ble/ble_manager.dart';
import '../core/theme.dart';
import '../state/ble_providers.dart';
import '../state/data_providers.dart';
import '../state/readings_providers.dart';
import 'screens/device_screen.dart';
import 'screens/history_screen.dart';
import 'screens/now_screen.dart';
import 'screens/settings_screen.dart';

class RootShell extends ConsumerStatefulWidget {
  const RootShell({super.key});

  @override
  ConsumerState<RootShell> createState() => _RootShellState();
}

class _RootShellState extends ConsumerState<RootShell> {
  static const _screens = [
    NowScreen(),
    HistoryScreen(),
    DeviceScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationServiceProvider).requestPermission();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Keep the BLE ingest pipeline alive for the lifetime of the app.
    ref.watch(readingsIngestProvider);

    final activeTab = ref.watch(activeTabProvider);

    // Visual in-app alert + push notification when device disconnects
    ref.listen<BleConnectionState>(connectionStateProvider, (prev, current) {
      if (prev == BleConnectionState.connected && current == BleConnectionState.disconnected) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.bluetooth_disabled, color: Colors.white, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Glucose Wearable disconnected',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFFC62828),
            duration: const Duration(seconds: 5),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            action: SnackBarAction(
              label: 'View Device',
              textColor: Colors.white,
              onPressed: () {
                ref.read(activeTabProvider.notifier).state = 2;
              },
            ),
          ),
        );

        ref.read(notificationServiceProvider).notifyDisconnection();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: IndexedStack(index: activeTab, children: _screens),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: activeTab,
        onDestinationSelected: (i) => ref.read(activeTabProvider.notifier).state = i,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.water_drop_outlined), selectedIcon: Icon(Icons.water_drop), label: 'Now'),
          NavigationDestination(icon: Icon(Icons.show_chart), label: 'History'),
          NavigationDestination(icon: Icon(Icons.bluetooth), label: 'Device'),
          NavigationDestination(icon: Icon(Icons.tune), label: 'Settings'),
        ],
      ),
    );
  }
}
