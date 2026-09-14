import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/glucose_class.dart';
import '../../core/theme.dart';
import '../../state/alert_providers.dart';
import '../../state/ble_providers.dart';
import '../../state/data_providers.dart';
import '../../state/readings_providers.dart';
import '../../state/settings_providers.dart';
import '../widgets/connection_banner.dart';
import '../widgets/connectivity_badge.dart';
import '../widgets/stale_data_banner.dart';
import '../widgets/state_ring.dart';
import '../widgets/time_in_state_bar.dart';
import 'reference_screen.dart';

class NowScreen extends ConsumerWidget {
  const NowScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final readingAsync = ref.watch(latestReadingProvider);
    final connection = ref.watch(connectionStateProvider);
    final battery = ref.watch(batteryLevelProvider);
    final fractions = ref.watch(fractionsProvider(const Duration(hours: 24)));
    final isStale = ref.watch(staleDataProvider).valueOrNull ?? false;
    final snoozedUntil = ref.watch(alertSnoozeProvider);
    final defaultSnoozeMins = ref.watch(defaultSnoozeDurationProvider);

    final isSnoozed = snoozedUntil != null && DateTime.now().isBefore(snoozedUntil);
    final latestReading = readingAsync.valueOrNull;

    return ListView(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 24),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              children: [
                const Text('Now', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w700)),
                const SizedBox(width: 10),
                const ConnectivityBadge(compact: true),
              ],
            ),
            readingAsync.maybeWhen(
              data: (r) => r == null
                  ? const SizedBox()
                  : Text('Updated ${DateFormat('HH:mm').format(r.timestamp)}',
                      style: const TextStyle(color: AppColors.muted, fontSize: 13)),
              orElse: () => const SizedBox(),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Stale Data Warning Banner
        if (isStale) const StaleDataBanner(),

        ConnectionBanner(
          state: connection,
          batteryLevel: battery,
          onTap: () => ref.read(activeTabProvider.notifier).state = 2,
        ),
        const SizedBox(height: 8),

        // Snooze Status Banner
        if (isSnoozed) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.accentSoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.snooze, size: 18, color: AppColors.accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Alerts snoozed until ${DateFormat.jm().format(snoozedUntil)}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.accent),
                  ),
                ),
                TextButton(
                  onPressed: () => ref.read(alertSnoozeProvider.notifier).clearSnooze(),
                  child: const Text('Clear', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],

        readingAsync.when(
          data: (r) => StateRing(reading: r),
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, st) => Text('Error: $e'),
        ),

        // Snooze Button if active low or high
        if (latestReading != null && latestReading.glucoseClass != GlucoseClass.normal && !isSnoozed) ...[
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => ref.read(alertSnoozeProvider.notifier).snooze(Duration(minutes: defaultSnoozeMins)),
            icon: const Icon(Icons.snooze_outlined),
            label: Text('Snooze Alert ($defaultSnoozeMins mins)'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.ink,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],

        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Time in state · last 24h', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                fractions.when(
                  data: (f) => TimeInStateBar(fractions: f),
                  loading: () => const SizedBox(height: 16),
                  error: (e, st) => Text('Error: $e'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        FilledButton.tonalIcon(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ReferenceScreen()),
          ),
          icon: const Icon(Icons.colorize_outlined),
          label: const Text('Add reference reading'),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.accentSoft,
            foregroundColor: AppColors.accent,
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ],
    );
  }
}
