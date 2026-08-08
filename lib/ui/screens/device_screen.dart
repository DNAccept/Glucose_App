import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../ble/ble_manager.dart';
import '../../core/theme.dart';
import '../../state/ble_providers.dart';

class DeviceScreen extends ConsumerWidget {
  const DeviceScreen({super.key});

  Future<void> _ensurePermissions() async {
    await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connection = ref.watch(connectionStateProvider).valueOrNull ?? BleConnectionState.disconnected;
    final battery = ref.watch(batteryLevelProvider).valueOrNull;
    final devices = ref.watch(discoveredDevicesProvider).valueOrNull ?? const [];
    final manager = ref.read(bleManagerProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 24),
      children: [
        const Text('Device', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        if (connection == BleConnectionState.connected) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(color: const Color(0xFFEEF2FB), borderRadius: BorderRadius.circular(20)),
                        alignment: Alignment.center,
                        child: const Icon(Icons.bluetooth, color: AppColors.accent),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Glucose Wearable', style: TextStyle(fontWeight: FontWeight.w600)),
                            Text('Paired over BLE', style: TextStyle(fontSize: 12, color: AppColors.muted)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.battery_std, size: 16, color: AppColors.muted),
                      const SizedBox(width: 5),
                      Text('Battery ${battery ?? '--'}%', style: const TextStyle(color: AppColors.muted)),
                      const Spacer(),
                      OutlinedButton(
                        onPressed: () => manager.disconnect(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.accent,
                          side: const BorderSide(color: Color(0xFFCFE0F7)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Disconnect'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ] else ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Pair your wearable', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  const Text(
                    'Power on the device and wear it on the forearm, then scan.',
                    style: TextStyle(fontSize: 13, color: AppColors.muted),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: connection == BleConnectionState.scanning
                        ? null
                        : () async {
                            await _ensurePermissions();
                            await manager.startScan();
                          },
                    icon: const Icon(Icons.search),
                    label: Text(connection == BleConnectionState.scanning ? 'Scanning…' : 'Scan for device'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      minimumSize: const Size.fromHeight(46),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(left: 6, top: 14, bottom: 8),
            child: Text('Found devices', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.muted)),
          ),
          if (devices.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                connection == BleConnectionState.scanning ? 'Searching…' : 'No devices yet. Try scanning.',
                style: const TextStyle(fontSize: 13, color: AppColors.muted),
              ),
            )
          else
            ...devices.map((d) => Card(
                  child: ListTile(
                    leading: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(color: const Color(0xFFEEF2FB), borderRadius: BorderRadius.circular(19)),
                      alignment: Alignment.center,
                      child: const Icon(Icons.watch_outlined, color: AppColors.accent, size: 20),
                    ),
                    title: Text(d.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('${d.rssi} dBm', style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                    trailing: FilledButton(
                      onPressed: () => manager.connect(d.id),
                      style: FilledButton.styleFrom(backgroundColor: AppColors.accent),
                      child: const Text('Connect'),
                    ),
                  ),
                )),
        ],
      ],
    );
  }
}
