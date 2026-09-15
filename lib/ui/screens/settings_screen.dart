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
          child: Column(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: const CircleAvatar(
                  backgroundColor: AppColors.accentSoft,
                  foregroundColor: AppColors.accent,
                  child: Icon(Icons.person_outline),
                ),
                title: Text(currentUser?.username ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                subtitle: const Text('Signed in on this device'),
              ),
              const Divider(height: 1),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                leading: const Icon(Icons.edit_outlined, size: 20),
                title: const Text('Edit Username'),
                trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
                onTap: () => _showEditUsernameDialog(context, ref, currentUser?.username),
              ),
              const Divider(height: 1),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                leading: const Icon(Icons.lock_outline, size: 20),
                title: const Text('Change Password'),
                trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
                onTap: () => _showChangePasswordDialog(context, ref),
              ),
              const Divider(height: 1),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                leading: const Icon(Icons.logout_rounded, size: 20, color: Colors.orange),
                title: const Text('Log out', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w600)),
                onTap: () => ref.read(authControllerProvider.notifier).logout(),
              ),
              const Divider(height: 1),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                leading: const Icon(Icons.delete_forever_outlined, size: 20, color: Colors.red),
                title: const Text('Delete Account', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
                onTap: () => _showDeleteAccountDialog(context, ref),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const _SectionLabel('Alerts & Clinical Thresholds'),
        const _AlertsCard(),
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

  void _showEditUsernameDialog(BuildContext context, WidgetRef ref, String? currentUsername) {
    final controller = TextEditingController(text: currentUsername);
    String? errorText;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          return AlertDialog(
            title: const Text('Edit Username'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    labelText: 'New Username',
                    errorText: errorText,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () async {
                  final newName = controller.text.trim();
                  if (newName.length < 3) {
                    setState(() => errorText = 'Username must be at least 3 characters.');
                    return;
                  }
                  try {
                    await ref.read(authControllerProvider.notifier).updateUsername(newName);
                    if (ctx.mounted) Navigator.of(ctx).pop();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Username updated successfully.')),
                      );
                    }
                  } catch (e) {
                    setState(() => errorText = e.toString().replaceFirst('Exception: ', ''));
                  }
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context, WidgetRef ref) {
    final currentPassCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();
    final confirmPassCtrl = TextEditingController();
    String? errorText;
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          return AlertDialog(
            title: const Text('Change Password'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: currentPassCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Current Password',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: newPassCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'New Password',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: confirmPassCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Confirm New Password',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  if (errorText != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      errorText!,
                      style: const TextStyle(color: Colors.red, fontSize: 12.5),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting ? null : () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: isSubmitting
                    ? null
                    : () async {
                        final currentPass = currentPassCtrl.text;
                        final newPass = newPassCtrl.text;
                        final confirmPass = confirmPassCtrl.text;

                        if (currentPass.isEmpty) {
                          setState(() => errorText = 'Please enter your current password.');
                          return;
                        }
                        if (newPass.length < 6) {
                          setState(() => errorText = 'New password must be at least 6 characters.');
                          return;
                        }
                        if (newPass != confirmPass) {
                          setState(() => errorText = 'New passwords do not match.');
                          return;
                        }

                        setState(() {
                          isSubmitting = true;
                          errorText = null;
                        });

                        try {
                          await ref.read(authControllerProvider.notifier).updatePassword(currentPass, newPass);
                          if (ctx.mounted) Navigator.of(ctx).pop();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Password updated successfully.')),
                            );
                          }
                        } catch (e) {
                          setState(() {
                            isSubmitting = false;
                            errorText = e.toString().replaceFirst('Exception: ', '');
                          });
                        }
                      },
                child: isSubmitting
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Update Password'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context, WidgetRef ref) {
    final passwordCtrl = TextEditingController();
    String? errorText;
    bool isDeleting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          return AlertDialog(
            title: Row(
              children: const [
                Icon(Icons.warning_amber_rounded, color: Colors.red),
                SizedBox(width: 8),
                Text('Delete Account?'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'This action cannot be undone. All your stored glucose readings, calibration logs, and cloud backups will be permanently deleted.',
                  style: TextStyle(fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: passwordCtrl,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password to Delete',
                    errorText: errorText,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isDeleting ? null : () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                onPressed: isDeleting
                    ? null
                    : () async {
                        final pass = passwordCtrl.text;
                        if (pass.isEmpty) {
                          setState(() => errorText = 'Please enter your password.');
                          return;
                        }

                        setState(() {
                          isDeleting = true;
                          errorText = null;
                        });

                        try {
                          await ref.read(authControllerProvider.notifier).deleteAccount(pass);
                          if (ctx.mounted) Navigator.of(ctx).pop();
                        } catch (e) {
                          setState(() {
                            isDeleting = false;
                            errorText = e.toString().replaceFirst('Exception: ', '');
                          });
                        }
                      },
                child: isDeleting
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Delete Account'),
              ),
            ],
          );
        },
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

class _AlertsCard extends ConsumerStatefulWidget {
  const _AlertsCard();

  @override
  ConsumerState<_AlertsCard> createState() => _AlertsCardState();
}

class _AlertsCardState extends ConsumerState<_AlertsCard> {
  bool _showMore = false;

  @override
  Widget build(BuildContext context) {
    final alertsEnabled = ref.watch(alertsEnabledProvider);
    final lowThreshold = ref.watch(lowThresholdProvider);
    final highThreshold = ref.watch(highThresholdProvider);
    final urgentLowThreshold = ref.watch(urgentLowThresholdProvider);
    final snoozeDuration = ref.watch(defaultSnoozeDurationProvider);

    return Card(
      child: Column(
        children: [
          SwitchListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            title: const Text('High / low alerts'),
            subtitle: const Text('Notify me when the device reports a hypo or hyper state'),
            value: alertsEnabled,
            activeTrackColor: AppColors.accent,
            onChanged: (v) {
              ref.read(alertsEnabledProvider.notifier).set(v);
              if (!v && _showMore) {
                setState(() => _showMore = false);
              }
            },
          ),
          if (alertsEnabled) ...[
            const Divider(height: 1),
            InkWell(
              onTap: () => setState(() => _showMore = !_showMore),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _showMore ? 'Show less' : 'Show more',
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.accent,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      _showMore ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                      color: AppColors.accent,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
            if (_showMore) ...[
              const Divider(height: 1),
              _ScrollableThresholdTile(
                title: 'Low Alert Threshold',
                subtitle: 'Triggers low alert notification',
                unit: 'mg/dL',
                value: lowThreshold,
                min: 60,
                max: 95,
                step: 5,
                onChanged: (val) => ref.read(lowThresholdProvider.notifier).set(val),
              ),
              const Divider(height: 1),
              _ScrollableThresholdTile(
                title: 'High Alert Threshold',
                subtitle: 'Triggers high alert notification',
                unit: 'mg/dL',
                value: highThreshold,
                min: 140,
                max: 260,
                step: 10,
                onChanged: (val) => ref.read(highThresholdProvider.notifier).set(val),
              ),
              const Divider(height: 1),
              _ScrollableThresholdTile(
                title: 'Urgent Low Alarm Threshold',
                subtitle: 'Max priority emergency alarm override',
                unit: 'mg/dL',
                value: urgentLowThreshold,
                min: 50,
                max: 75,
                step: 5,
                onChanged: (val) => ref.read(urgentLowThresholdProvider.notifier).set(val),
              ),
              const Divider(height: 1),
              _ScrollableThresholdTile(
                title: 'Default Snooze Duration',
                subtitle: 'Suppresses repeated alerts after snooze',
                unit: 'mins',
                value: snoozeDuration,
                min: 10,
                max: 60,
                step: 5,
                onChanged: (val) => ref.read(defaultSnoozeDurationProvider.notifier).set(val),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _ScrollableThresholdTile extends StatefulWidget {
  const _ScrollableThresholdTile({
    required this.title,
    required this.subtitle,
    required this.unit,
    required this.value,
    required this.min,
    required this.max,
    required this.step,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final String unit;
  final int value;
  final int min;
  final int max;
  final int step;
  final ValueChanged<int> onChanged;

  @override
  State<_ScrollableThresholdTile> createState() => _ScrollableThresholdTileState();
}

class _ScrollableThresholdTileState extends State<_ScrollableThresholdTile> {
  late final ScrollController _scrollController;

  List<int> get _range {
    final list = <int>[];
    for (int v = widget.min; v <= widget.max; v += widget.step) {
      list.add(v);
    }
    if (!list.contains(widget.value)) {
      list.add(widget.value);
      list.sort();
    }
    return list;
  }

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSelected());
  }

  @override
  void didUpdateWidget(covariant _ScrollableThresholdTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _scrollToSelected();
    }
  }

  void _scrollToSelected() {
    if (!_scrollController.hasClients) return;
    final index = _range.indexOf(widget.value);
    if (index != -1) {
      const itemWidth = 64.0;
      final targetOffset = (index * itemWidth) - 100;
      _scrollController.animateTo(
        targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rangeValues = _range;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(widget.subtitle, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accentSoft,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
                ),
                child: Text(
                  '${widget.value} ${widget.unit}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.accent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 38,
            child: ListView.builder(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              itemCount: rangeValues.length,
              itemBuilder: (context, index) {
                final val = rangeValues[index];
                final isSelected = val == widget.value;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(
                      '$val',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? Colors.white : Colors.black87,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: AppColors.accent,
                    backgroundColor: Colors.grey.shade100,
                    showCheckmark: false,
                    visualDensity: VisualDensity.compact,
                    side: BorderSide(
                      color: isSelected ? AppColors.accent : Colors.grey.shade300,
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        widget.onChanged(val);
                      }
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
