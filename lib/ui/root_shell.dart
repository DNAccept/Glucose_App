import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ble/ble_manager.dart';
import '../core/theme.dart';
import '../data/sync_service.dart';
import '../state/ble_providers.dart';
import '../state/data_providers.dart';
import '../state/readings_providers.dart';
import '../state/sync_providers.dart';
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
    final isOnline = ref.watch(networkModeProvider);
    final syncResult = ref.watch(syncControllerProvider);

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
        child: Column(
          children: [
            _NetworkHeader(isOnline: isOnline, syncResult: syncResult),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: IndexedStack(index: activeTab, children: _screens),
              ),
            ),
          ],
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

class _NetworkHeader extends ConsumerWidget {
  const _NetworkHeader({
    required this.isOnline,
    required this.syncResult,
  });

  final bool isOnline;
  final SyncResult syncResult;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusColor = isOnline ? Colors.green.shade700 : Colors.orange.shade800;
    final statusBg = isOnline ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0);

    String text = isOnline ? 'ONLINE SERVER CONNECTED' : 'SERVER UNREACHABLE (OFFLINE SQLITE)';
    if (syncResult.status == SyncStateStatus.syncing) {
      text = 'SYNCING WITH CLOUD...';
    } else if (!isOnline && syncResult.pendingCount > 0) {
      text = 'SERVER UNREACHABLE (${syncResult.pendingCount} PENDING SYNC)';
    }

    return Container(
      width: double.infinity,
      color: statusBg,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  isOnline ? Icons.cloud_done : Icons.cloud_off,
                  size: 15,
                  color: statusColor,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    text,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          InkWell(
            onTap: () async {
              final ok = await ref.read(networkModeProvider.notifier).recheck();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(ok ? 'Online server is reachable!' : 'Online server is unreachable.'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.refresh, size: 12, color: statusColor),
                  const SizedBox(width: 4),
                  Text(
                    'Ping Server',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
