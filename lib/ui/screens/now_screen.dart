import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme.dart';
import '../../state/ble_providers.dart';
import '../../state/data_providers.dart';
import '../../state/readings_providers.dart';
import '../widgets/connection_banner.dart';
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

    return ListView(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 24),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Now', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w700)),
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
        ConnectionBanner(
          state: connection,
          batteryLevel: battery,
          onTap: () => ref.read(activeTabProvider.notifier).state = 2,
        ),
        const SizedBox(height: 8),
        readingAsync.when(
          data: (r) => StateRing(reading: r),
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, st) => Text('Error: $e'),
        ),
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
