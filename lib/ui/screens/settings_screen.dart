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

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late TextEditingController _serverUrlController;
  bool _testingConnection = false;
  String? _connectionResult;
  bool _connectionSuccess = false;

  @override
  void initState() {
    super.initState();
    final onlineDb = ref.read(onlineDatabaseServiceProvider);
    _serverUrlController = TextEditingController(text: onlineDb.serverUrl ?? 'http://10.12.64.7:8080');
  }

  @override
  void dispose() {
    _serverUrlController.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    setState(() {
      _testingConnection = true;
      _connectionResult = null;
    });

    final onlineDb = ref.read(onlineDatabaseServiceProvider);
    onlineDb.serverUrl = _serverUrlController.text.trim();
    final ok = await onlineDb.checkHealth();

    if (mounted) {
      setState(() {
        _testingConnection = false;
        _connectionSuccess = ok;
        _connectionResult = ok
            ? 'Connected to online database server (${onlineDb.serverUrl})'
            : 'Unable to reach server at ${onlineDb.serverUrl}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final alertsEnabled = ref.watch(alertsEnabledProvider);
    final cloudEnabled = ref.watch(cloudSyncEnabledProvider);
    final currentUser = ref.watch(authControllerProvider).valueOrNull;
    final onlineDb = ref.watch(onlineDatabaseServiceProvider);
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
        const _SectionLabel('Cloud Database & Localhost Server'),
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
                title: const Text('Server Connection Status'),
                subtitle: Text(
                  ref.watch(networkModeProvider)
                      ? 'Online server is reachable and connected'
                      : 'Online server unreachable — using offline local SQLite storage',
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
                    ? 'Automatic mode (syncs on write, reconnect & 30s timer)'
                    : 'Manual Mode (syncs only when tapping Sync Now)'),
                value: ref.watch(autoSyncEnabledProvider),
                activeTrackColor: AppColors.accent,
                onChanged: (v) => ref.read(autoSyncEnabledProvider.notifier).set(v),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                      TextFormField(
                        controller: _serverUrlController,
                        decoration: InputDecoration(
                          labelText: 'Online Database Server URL',
                          hintText: 'http://10.12.64.7:8080',
                          isDense: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          suffixIcon: IconButton(
                            icon: _testingConnection
                                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                : const Icon(Icons.network_check),
                            onPressed: () async {
                              final url = _serverUrlController.text.trim();
                              await ref.read(settingsRepositoryProvider).setServerUrl(url);
                              await _testConnection();
                            },
                            tooltip: 'Test Connection',
                          ),
                        ),
                        onChanged: (v) {
                          onlineDb.serverUrl = v.trim();
                          ref.read(settingsRepositoryProvider).setServerUrl(v.trim());
                        },
                      ),
                      const SizedBox(height: 8),
                      const Text('Quick Connection Mode:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.muted)),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          if (AppConfig.definedServerUrl.isNotEmpty)
                            ActionChip(
                              avatar: const Icon(Icons.cloud_done, size: 14),
                              label: Text('Production Cloud (${AppConfig.definedServerUrl})', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                              onPressed: () async {
                                _serverUrlController.text = AppConfig.definedServerUrl;
                                onlineDb.serverUrl = AppConfig.definedServerUrl;
                                await ref.read(settingsRepositoryProvider).setServerUrl(AppConfig.definedServerUrl);
                                await _testConnection();
                              },
                            ),
                          ActionChip(
                            avatar: const Icon(Icons.travel_explore, size: 14),
                            label: const Text('Auto-Discover', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                            onPressed: () async {
                              await _testConnection();
                              if (onlineDb.serverUrl != null) {
                                _serverUrlController.text = onlineDb.serverUrl!;
                                await ref.read(settingsRepositoryProvider).setServerUrl(onlineDb.serverUrl!);
                              }
                            },
                          ),
                          ActionChip(
                            avatar: const Icon(Icons.usb, size: 14),
                            label: const Text('USB Cable', style: TextStyle(fontSize: 11.5)),
                            onPressed: () async {
                              _serverUrlController.text = 'http://127.0.0.1:8080';
                              onlineDb.serverUrl = 'http://127.0.0.1:8080';
                              await ref.read(settingsRepositoryProvider).setServerUrl('http://127.0.0.1:8080');
                              await _testConnection();
                            },
                          ),
                          ActionChip(
                            avatar: const Icon(Icons.wifi, size: 14),
                            label: const Text('Wi-Fi (192.168.137.118)', style: TextStyle(fontSize: 11.5)),
                            onPressed: () async {
                              _serverUrlController.text = 'http://192.168.137.118:8080';
                              onlineDb.serverUrl = 'http://192.168.137.118:8080';
                              await ref.read(settingsRepositoryProvider).setServerUrl('http://192.168.137.118:8080');
                              await _testConnection();
                            },
                          ),
                          ActionChip(
                            avatar: const Icon(Icons.phonelink, size: 14),
                            label: const Text('Emulator', style: TextStyle(fontSize: 11.5)),
                            onPressed: () async {
                              _serverUrlController.text = 'http://10.0.2.2:8080';
                              onlineDb.serverUrl = 'http://10.0.2.2:8080';
                              await ref.read(settingsRepositoryProvider).setServerUrl('http://10.0.2.2:8080');
                              await _testConnection();
                            },
                          ),
                        ],
                      ),
                      if (_connectionResult != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              _connectionSuccess ? Icons.check_circle_outline : Icons.error_outline,
                              size: 16,
                              color: _connectionSuccess ? Colors.green : Colors.red,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                _connectionResult!,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: _connectionSuccess ? Colors.green.shade800 : Colors.red.shade800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 12),
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
