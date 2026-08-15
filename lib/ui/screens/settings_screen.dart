import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../state/auth_providers.dart';
import '../../state/settings_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertsEnabled = ref.watch(alertsEnabledProvider);
    final cloudEnabled = ref.watch(cloudSyncEnabledProvider);
    final currentUser = ref.watch(authControllerProvider).valueOrNull;

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
        const _SectionLabel('Alerts'),
        Card(
          child: SwitchListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            title: const Text('High / low alerts'),
            subtitle: const Text('Notify me when the device reports a hypo or hyper state'),
            value: alertsEnabled,
            activeTrackColor: AppColors.accent,
            onChanged: (v) => ref.read(alertsEnabledProvider.notifier).set(v),
          ),
        ),
        const SizedBox(height: 14),
        const _SectionLabel('Cloud'),
        Card(
          child: Column(
            children: [
              SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                title: const Text('Sync to cloud'),
                subtitle: const Text('Back up history and enable sharing with a clinician'),
                value: cloudEnabled,
                activeTrackColor: AppColors.accent,
                onChanged: (v) => ref.read(cloudSyncEnabledProvider.notifier).set(v),
              ),
              if (cloudEnabled)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: FilledButton.icon(
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Cloud sync is not implemented in this build.')),
                    ),
                    icon: const Icon(Icons.cloud_upload_outlined),
                    label: const Text('Sync now'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      minimumSize: const Size.fromHeight(46),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
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
