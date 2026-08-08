import 'package:flutter/material.dart';

import '../../ble/ble_manager.dart';
import '../../core/theme.dart';

class ConnectionBanner extends StatelessWidget {
  const ConnectionBanner({super.key, required this.state, this.batteryLevel});

  final BleConnectionState state;
  final int? batteryLevel;

  @override
  Widget build(BuildContext context) {
    final connected = state == BleConnectionState.connected;
    final bg = connected ? AppColors.normal.withValues(alpha: 0.12) : const Color(0xFF6B7280).withValues(alpha: 0.12);
    final fg = connected ? AppColors.normal : const Color(0xFF6B7280);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          Icon(Icons.bluetooth, size: 18, color: fg),
          const SizedBox(width: 8),
          Text(_label(state), style: TextStyle(color: fg, fontWeight: FontWeight.w600, fontSize: 13.5)),
          const Spacer(),
          if (connected && batteryLevel != null)
            Row(
              children: [
                const Icon(Icons.battery_std, size: 16, color: AppColors.muted),
                const SizedBox(width: 4),
                Text('$batteryLevel%', style: const TextStyle(color: AppColors.muted, fontSize: 13)),
              ],
            ),
        ],
      ),
    );
  }

  String _label(BleConnectionState s) => switch (s) {
        BleConnectionState.connected => 'Connected',
        BleConnectionState.connecting => 'Connecting…',
        BleConnectionState.scanning => 'Scanning…',
        BleConnectionState.disconnected => 'Not connected',
      };
}
