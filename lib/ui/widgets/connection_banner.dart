import 'package:flutter/material.dart';

import '../../ble/ble_manager.dart';
import '../../core/theme.dart';

class ConnectionBanner extends StatelessWidget {
  const ConnectionBanner({
    super.key,
    required this.state,
    this.batteryLevel,
    this.onTap,
  });

  final BleConnectionState state;
  final int? batteryLevel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, border, icon, label, trailing) = _config(state, batteryLevel);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
            border: border != null ? Border.all(color: border, width: 1.2) : null,
          ),
          child: Row(
            children: [
              icon,
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(color: fg, fontWeight: FontWeight.w600, fontSize: 13.5),
              ),
              const Spacer(),
              ?trailing,
            ],
          ),
        ),
      ),
    );
  }

  (Color, Color, Color?, Widget, String, Widget?) _config(BleConnectionState s, int? battery) {
    switch (s) {
      case BleConnectionState.connected:
        return (
          AppColors.normal.withValues(alpha: 0.12),
          AppColors.normal,
          null,
          const Icon(Icons.bluetooth_connected, size: 18, color: AppColors.normal),
          'Wearable Connected',
          battery != null
              ? Row(
                  children: [
                    const Icon(Icons.battery_std, size: 16, color: AppColors.muted),
                    const SizedBox(width: 4),
                    Text('$battery%', style: const TextStyle(color: AppColors.muted, fontSize: 13)),
                  ],
                )
              : null,
        );

      case BleConnectionState.connecting:
        return (
          AppColors.accent.withValues(alpha: 0.12),
          AppColors.accent,
          null,
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent),
          ),
          'Connecting to wearable…',
          null,
        );

      case BleConnectionState.scanning:
        return (
          AppColors.accent.withValues(alpha: 0.12),
          AppColors.accent,
          null,
          const Icon(Icons.radar, size: 18, color: AppColors.accent),
          'Scanning for device…',
          null,
        );

      case BleConnectionState.disconnected:
        return (
          const Color(0xFFEF4444).withValues(alpha: 0.08),
          const Color(0xFFDC2626),
          const Color(0xFFEF4444).withValues(alpha: 0.30),
          const Icon(Icons.bluetooth_disabled, size: 18, color: Color(0xFFDC2626)),
          'Wearable Disconnected',
          const Row(
            children: [
              Text(
                'Connect',
                style: TextStyle(
                  color: Color(0xFFDC2626),
                  fontWeight: FontWeight.w600,
                  fontSize: 12.5,
                ),
              ),
              SizedBox(width: 2),
              Icon(Icons.arrow_forward_ios, size: 11, color: Color(0xFFDC2626)),
            ],
          ),
        );
    }
  }
}
