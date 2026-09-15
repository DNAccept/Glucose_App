import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/config.dart';
import '../../core/theme.dart';
import '../../data/sync_service.dart';
import '../../state/auth_providers.dart';
import '../../state/data_providers.dart';
import '../../state/settings_providers.dart';
import '../../state/simulation_providers.dart';
import '../../state/sync_providers.dart';
import 'simulation_studio_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertsEnabled = ref.watch(alertsEnabledProvider);
    final cloudEnabled = ref.watch(cloudSyncEnabledProvider);
    final currentUser = ref.watch(authControllerProvider).valueOrNull;
    final syncState = ref.watch(syncControllerProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 24),
      children: [
        const Text('Settings', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        const _SectionLabel('Account'),
        Card(
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            leading: const CircleAvatar(
              backgroundColor: AppColors.accentSoft,
              foregroundColor: AppColors.accent,
              child: Icon(Icons.person_outline),
            ),
            title: Text(currentUser?.username ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text('Signed in on this device'),
            trailing: TextButton(
              onPressed: () => ref.read(authControllerProvider.notifier).logout(),
              child: const Text('Log out'),
            ),
          ),
        ),
        const SizedBox(height: 14),
        const _SectionLabel('Alerts & Clinical Thresholds'),
        Card(
          child: Column(
            children: [
              SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                title: const Text('High / low alerts'),
                subtitle: const Text('Notify me when the device reports a hypo or hyper state'),
                value: alertsEnabled,
                activeTrackColor: AppColors.accent,
                onChanged: (v) => ref.read(alertsEnabledProvider.notifier).set(v),
              ),
              if (alertsEnabled) ...[
                const Divider(height: 1),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  title: const Text('Low Alert Threshold'),
                  subtitle: const Text('Triggers low alert notification'),
                  trailing: DropdownButton<int>(
                    value: ref.watch(lowThresholdProvider),
                    underline: const SizedBox(),
                    items: [60, 70, 80, 90].map((v) => DropdownMenuItem(value: v, child: Text('$v mg/dL'))).toList(),
                    onChanged: (val) => val != null ? ref.read(lowThresholdProvider.notifier).set(val) : null,
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  title: const Text('High Alert Threshold'),
                  subtitle: const Text('Triggers high alert notification'),
                  trailing: DropdownButton<int>(
                    value: ref.watch(highThresholdProvider),
                    underline: const SizedBox(),
                    items: [160, 180, 200, 240].map((v) => DropdownMenuItem(value: v, child: Text('$v mg/dL'))).toList(),
                    onChanged: (val) => val != null ? ref.read(highThresholdProvider.notifier).set(val) : null,
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  title: const Text('Urgent Low Alarm Threshold'),
                  subtitle: const Text('Max priority emergency alarm override'),
                  trailing: DropdownButton<int>(
                    value: ref.watch(urgentLowThresholdProvider),
                    underline: const SizedBox(),
                    items: [50, 55, 60, 65].map((v) => DropdownMenuItem(value: v, child: Text('$v mg/dL'))).toList(),
                    onChanged: (val) => val != null ? ref.read(urgentLowThresholdProvider.notifier).set(val) : null,
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  title: const Text('Default Snooze Duration'),
                  subtitle: const Text('Suppresses repeated alerts after snooze'),
                  trailing: DropdownButton<int>(
                    value: ref.watch(defaultSnoozeDurationProvider),
                    underline: const SizedBox(),
                    items: [15, 30, 45, 60].map((v) => DropdownMenuItem(value: v, child: Text('$v mins'))).toList(),
                    onChanged: (val) => val != null ? ref.read(defaultSnoozeDurationProvider.notifier).set(val) : null,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),
        const _SectionLabel('Cloud Backup & Synchronization'),
        Card(
          child: Column(
            children: [
              SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                title: const Text('Sync to cloud'),
                subtitle: const Text('Back up history to online database for cross-device access'),
                value: cloudEnabled,
                activeTrackColor: AppColors.accent,
                onChanged: (v) {
                  ref.read(cloudSyncEnabledProvider.notifier).set(v);
                  if (v && !ref.read(networkModeProvider)) {
                    ref.read(networkModeProvider.notifier).recheck();
                  }
                },
              ),
              const Divider(height: 1),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                leading: Icon(
                  ref.watch(networkModeProvider) ? Icons.cloud_done : Icons.cloud_off,
                  color: ref.watch(networkModeProvider) ? Colors.green.shade700 : Colors.orange.shade800,
                ),
                title: const Text('Cloud Connection Status'),
                subtitle: Text(
                  ref.watch(networkModeProvider)
                      ? 'Cloud database is connected'
                      : 'Cloud server unreachable — storing data locally on device',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: ref.watch(networkModeProvider) ? Colors.green.shade800 : Colors.orange.shade900,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Divider(height: 1),
              SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                title: const Text('Auto-Sync in Background'),
                subtitle: Text(ref.watch(autoSyncEnabledProvider)
                    ? 'Automatic mode (syncs on new readings & reconnection)'
                    : 'Manual Mode (syncs only when tapping Sync Now)'),
                value: ref.watch(autoSyncEnabledProvider),
                activeTrackColor: AppColors.accent,
                onChanged: (v) => ref.read(autoSyncEnabledProvider.notifier).set(v),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildSyncStatusBadge(syncState),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: syncState.status == SyncStateStatus.syncing
                          ? null
                          : () async {
                              final res = await ref.read(syncControllerProvider.notifier).triggerSync();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(res.status == SyncStateStatus.success
                                        ? 'Cloud sync completed successfully!'
                                        : res.errorMessage ?? 'Sync finished (${res.status.name})'),
                                    duration: const Duration(seconds: 3),
                                  ),
                                );
                              }
                            },
                      icon: syncState.status == SyncStateStatus.syncing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.cloud_upload_outlined),
                      label: Text(syncState.status == SyncStateStatus.syncing ? 'Syncing...' : 'Sync now'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        minimumSize: const Size.fromHeight(46),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const _SectionLabel('Developer Options'),
        Card(
          child: Column(
            children: [
              SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                title: const Text('Simulation Mode'),
                subtitle: const Text('Inject simulated BLE reading stream instead of physical Bluetooth hardware'),
                value: ref.watch(isSimulationModeProvider),
                activeTrackColor: AppColors.accent,
                onChanged: (val) => ref.read(isSimulationModeProvider.notifier).state = val,
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                leading: const Icon(Icons.science_outlined, color: AppColors.accent),
                title: const Text('BLE Simulation Studio', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Interactive scenario runner, step debugger, and self-test suite'),
                trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SimulationStudioScreen()),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'Research prototype. Not a medical device.\nDo not use for treatment decisions.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11.5, color: Color(0xFF9AA2AF), height: 1.5),
        ),
      ],
    );
  }

  Widget _buildSyncStatusBadge(SyncResult syncState) {
    String statusText;
    Color color;
    IconData icon;

    switch (syncState.status) {
      case SyncStateStatus.syncing:
        statusText = 'Syncing local SQLite with online database...';
        color = Colors.orange;
        icon = Icons.sync;
      case SyncStateStatus.success:
        final lastTime = syncState.lastSyncedAt != null
            ? DateFormat.jm().format(syncState.lastSyncedAt!)
            : 'recently';
        statusText = 'Synced with cloud ($lastTime)';
        color = Colors.green;
        icon = Icons.cloud_done_outlined;
      case SyncStateStatus.offline:
        statusText = 'Offline mode (${syncState.pendingCount} items pending sync)';
        color = Colors.grey.shade700;
        icon = Icons.cloud_off_outlined;
      case SyncStateStatus.error:
        statusText = syncState.errorMessage ?? 'Sync failed';
        color = Colors.red;
        icon = Icons.error_outline;
      case SyncStateStatus.idle:
        statusText = 'Ready to sync (${syncState.pendingCount} items pending)';
        color = AppColors.muted;
        icon = Icons.cloud_queue_outlined;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              statusText,
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500, color: color),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 6, bottom: 8),
      child: Text(text, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.muted)),
    );
  }
}
