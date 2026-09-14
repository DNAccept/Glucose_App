import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../data/sync_service.dart';
import '../../state/connectivity_providers.dart';
import '../../state/data_providers.dart';
import '../../state/sync_providers.dart';

/// Interactive UI badge reflecting live Connectivity and Cloud Sync status.
class ConnectivityBadge extends ConsumerWidget {
  const ConnectivityBadge({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(isOnlineProvider);
    final syncStatus = ref.watch(syncStatusStateProvider);
    final onlineDb = ref.watch(onlineDatabaseServiceProvider);
    final serverUrl = onlineDb.serverUrl ?? 'Offline';

    final Color badgeBg;
    final Color textColor;
    final IconData statusIcon;
    final String label;

    if (!isOnline || syncStatus == SyncStateStatus.offline) {
      badgeBg = const Color(0xFFFFF3E0); // Soft Amber
      textColor = const Color(0xFFE65100);
      statusIcon = Icons.wifi_off_rounded;
      label = compact ? 'Offline' : 'Offline Mode (Local Storage)';
    } else if (syncStatus == SyncStateStatus.syncing) {
      badgeBg = const Color(0xFFE3F2FD); // Soft Blue
      textColor = const Color(0xFF1565C0);
      statusIcon = Icons.sync_rounded;
      label = compact ? 'Syncing' : 'Syncing Cloud...';
    } else if (syncStatus == SyncStateStatus.error) {
      badgeBg = const Color(0xFFFFEBEE); // Soft Red
      textColor = const Color(0xFFC62828);
      statusIcon = Icons.cloud_off_rounded;
      label = compact ? 'Sync Error' : 'Cloud Sync Error';
    } else {
      badgeBg = const Color(0xFFE8F5E9); // Soft Green
      textColor = const Color(0xFF2E7D32);
      statusIcon = Icons.cloud_done_rounded;
      label = compact ? 'Synced' : 'Cloud Synced';
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          _showConnectivityDetails(context, ref, isOnline, syncStatus, serverUrl);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 8.0 : 12.0,
            vertical: compact ? 4.0 : 6.0,
          ),
          decoration: BoxDecoration(
            color: badgeBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: textColor.withOpacity(0.3), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(statusIcon, size: compact ? 14 : 16, color: textColor),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: compact ? 11 : 12,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showConnectivityDetails(
    BuildContext context,
    WidgetRef ref,
    bool isOnline,
    SyncStateStatus syncStatus,
    String serverUrl,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isOnline ? Icons.cloud_done_rounded : Icons.wifi_off_rounded,
                  color: isOnline ? AppColors.normal : AppColors.high,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  isOnline ? 'Online Cloud Mode' : 'Offline Local Storage Mode',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.ink),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              isOnline
                  ? 'Your glucose readings are automatically encrypted and synced in real-time with the cloud database server.'
                  : 'Device is currently operating in 100% standalone local mode. Readings are saved securely in local SQLite database and will automatically sync when connection returns.',
              style: const TextStyle(fontSize: 14, color: AppColors.ink, height: 1.4),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.dns_outlined, size: 18, color: AppColors.muted),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Server Endpoint:\n$serverUrl',
                      style: const TextStyle(fontSize: 12, fontFamily: 'monospace', color: AppColors.ink),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () async {
                  Navigator.pop(ctx);
                  final onlineDb = ref.read(onlineDatabaseServiceProvider);
                  final success = await onlineDb.verifyConnection();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          success
                              ? 'Connected to server: ${onlineDb.serverUrl}'
                              : 'Server unreachable. Remaining in local offline mode.',
                        ),
                        backgroundColor: success ? AppColors.normal : AppColors.high,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Check Connection Now'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
