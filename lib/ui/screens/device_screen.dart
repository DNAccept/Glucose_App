import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../ble/ble_manager.dart';
import '../../core/theme.dart';
import '../../state/ble_providers.dart';

class DeviceScreen extends ConsumerStatefulWidget {
  const DeviceScreen({super.key});

  @override
  ConsumerState<DeviceScreen> createState() => _DeviceScreenState();
}

class _DeviceScreenState extends ConsumerState<DeviceScreen> {
  String? _connectingDeviceId;
  bool _hasAttemptedScan = false;

  Future<void> _ensurePermissions() async {
    await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request();
  }

  Future<void> _handleConnect(BleManager manager, String deviceId) async {
    setState(() => _connectingDeviceId = deviceId);
    try {
      await manager.connect(deviceId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Connected to Glucose Wearable!'),
            backgroundColor: Color(0xFF2E7D32),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connection failed: $e'),
            backgroundColor: const Color(0xFFC62828),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _connectingDeviceId = null);
    }
  }

  Future<void> _triggerScan(BleManager manager) async {
    setState(() => _hasAttemptedScan = true);
    await _ensurePermissions();
    await manager.startScan();
  }

  @override
  Widget build(BuildContext context) {
    final connection = ref.watch(connectionStateProvider);
    final connectedDevice = ref.watch(connectedDeviceProvider);
    final battery = ref.watch(batteryLevelProvider);
    final devices = ref.watch(discoveredDevicesProvider);
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
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(connectedDevice?.name ?? 'Glucose Wearable', style: const TextStyle(fontWeight: FontWeight.w600)),
                            Text(connectedDevice?.id != null ? 'ID: ${connectedDevice!.id}' : 'Connected over Bluetooth LE', style: const TextStyle(fontSize: 12, color: AppColors.muted)),
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
                        onPressed: () async {
                          await manager.disconnect();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Disconnected from wearable'),
                                backgroundColor: Color(0xFF424242),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        },
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
          if (connection == BleConnectionState.disconnected && connectedDevice == null)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.25)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.bluetooth_disabled, color: Color(0xFFDC2626), size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'No wearable connected. Power on your device and scan.',
                      style: TextStyle(fontSize: 13, color: Color(0xFFDC2626), fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          if (connection == BleConnectionState.scanning) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const _RadarScanAnimation(),
                    const SizedBox(height: 12),
                    const Text(
                      'Scanning for wearable devices...',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Make sure your device is powered on and broadcasting nearby',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12.5, color: AppColors.muted),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: () => manager.stopScan(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.muted,
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Stop Scan'),
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
                      onPressed: connection == BleConnectionState.connecting
                          ? null
                          : () => _triggerScan(manager),
                      icon: const Icon(Icons.search),
                      label: const Text('Scan for device'),
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
          ],
          const Padding(
            padding: EdgeInsets.only(left: 6, top: 14, bottom: 8),
            child: Text('Found devices', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.muted)),
          ),
          if (devices.isEmpty) ...[
            if (connection != BleConnectionState.scanning && _hasAttemptedScan)
              _ScanFailedCard(onRetry: () => _triggerScan(manager))
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  connection == BleConnectionState.scanning
                      ? 'Searching over-the-air BLE signals...'
                      : 'No devices yet. Try scanning.',
                  style: const TextStyle(fontSize: 13, color: AppColors.muted),
                ),
              ),
          ] else
            ...devices.map((d) {
              final isConnectingThis = _connectingDeviceId == d.id || (connection == BleConnectionState.connecting && manager.currentDevice?.id == d.id);
              return Card(
                child: ListTile(
                  leading: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(color: const Color(0xFFEEF2FB), borderRadius: BorderRadius.circular(19)),
                    alignment: Alignment.center,
                    child: const Icon(Icons.watch_outlined, color: AppColors.accent, size: 20),
                  ),
                  title: Text(d.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(d.rssi != 0 ? '${d.rssi} dBm' : 'Nearby', style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                  trailing: FilledButton(
                    onPressed: isConnectingThis || connection == BleConnectionState.connecting
                        ? null
                        : () => _handleConnect(manager, d.id),
                    style: FilledButton.styleFrom(backgroundColor: AppColors.accent),
                    child: isConnectingThis
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Connect'),
                  ),
                ),
              );
            }),
        ],
      ],
    );
  }
}

class _RadarScanAnimation extends StatefulWidget {
  const _RadarScanAnimation();

  @override
  State<_RadarScanAnimation> createState() => _RadarScanAnimationState();
}

class _RadarScanAnimationState extends State<_RadarScanAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return SizedBox(
          height: 140,
          child: Stack(
            alignment: Alignment.center,
            children: [
              _buildRipple(_controller.value),
              _buildRipple((_controller.value + 0.5) % 1.0),
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.accent,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.35),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: RotationTransition(
                  turns: _controller,
                  child: const Icon(
                    Icons.bluetooth_searching,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRipple(double value) {
    final size = 60.0 + (value * 85.0);
    final opacity = (1.0 - value).clamp(0.0, 1.0);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.accent.withValues(alpha: opacity * 0.5),
          width: 2.0 * (1.0 - value + 0.2),
        ),
      ),
    );
  }
}

class _ScanFailedCard extends StatelessWidget {
  const _ScanFailedCard({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
      ),
      color: const Color(0xFFFEF2F2),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: const BoxDecoration(
                color: Color(0xFFFEE2E2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.bluetooth_disabled, color: Color(0xFFDC2626), size: 28),
            ),
            const SizedBox(height: 12),
            const Text(
              'No Wearable Found',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF991B1B),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'No active Glucose Wearable was detected broadcasting nearby over Bluetooth LE.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Color(0xFFB91C1C), height: 1.4),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFCA5A5)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Troubleshooting checklist:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF7F1D1D))),
                  SizedBox(height: 6),
                  Text('• Make sure your device is powered ON', style: TextStyle(fontSize: 12, color: Color(0xFF4B5563))),
                  Text('• Move device within 3 feet of your phone', style: TextStyle(fontSize: 12, color: Color(0xFF4B5563))),
                  Text('• Ensure Bluetooth is enabled on your phone', style: TextStyle(fontSize: 12, color: Color(0xFF4B5563))),
                ],
              ),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry Scan'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFDC2626),
                side: const BorderSide(color: Color(0xFFFCA5A5)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                minimumSize: const Size.fromHeight(42),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
