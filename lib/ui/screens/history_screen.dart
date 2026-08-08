import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme.dart';
import '../../state/readings_providers.dart';
import '../widgets/duration_picker_sheet.dart';
import '../widgets/time_in_state_bar.dart';
import '../widgets/timeline_strip.dart';
import '../widgets/trend_line_chart.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final window = ref.watch(historyWindowProvider);
    final readingsAsync = ref.watch(windowedReadingsProvider);
    final fractionsAsync = ref.watch(fractionsProvider(window));

    return ListView(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 24),
      children: [
        const Text('History', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        _TimeRangeSelector(
          value: window,
          onTap: () => showDurationPickerSheet(
            context,
            current: window,
            onChanged: (d) => ref.read(historyWindowProvider.notifier).state = d,
          ),
        ),
        const SizedBox(height: 14),
        readingsAsync.when(
          data: (readings) {
            final ascending = readings.reversed.toList();
            // The simulator's virtual clock can run ahead of wall-clock time
            // (it advances 5 simulated minutes per 5-second tick so a full
            // day cycle is visible quickly). Anchor "now" to the latest
            // reading when it's ahead of wall time, or every point would
            // clamp to the chart's right edge.
            final now = ascending.isEmpty
                ? DateTime.now()
                : (ascending.last.timestamp.isAfter(DateTime.now()) ? ascending.last.timestamp : DateTime.now());
            return Column(
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Glucose trend', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 10),
                        TrendLineChart(readings: ascending, window: window, now: now),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('State over time', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 10),
                        TimelineStrip(readings: ascending, window: window, now: now),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Time in state', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 10),
                        fractionsAsync.when(
                          data: (f) => TimeInStateBar(fractions: f),
                          loading: () => const SizedBox(height: 16),
                          error: (e, st) => Text('Error: $e'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Padding(
                  padding: EdgeInsets.only(left: 2, bottom: 8),
                  child: Text('Readings', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.muted)),
                ),
                if (readings.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(child: Text('No readings in this window', style: TextStyle(color: AppColors.muted))),
                  )
                else
                  ...readings.take(20).map((r) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: AppColors.forClass(r.glucoseClass).withValues(alpha: 0.15),
                          foregroundColor: AppColors.forClass(r.glucoseClass),
                          child: Icon(r.glucoseClass.icon, size: 18),
                        ),
                        title: Row(
                          children: [
                            Text(r.glucoseClass.label,
                                style: TextStyle(color: AppColors.forClass(r.glucoseClass), fontWeight: FontWeight.w700, fontSize: 16)),
                            const SizedBox(width: 6),
                            Text('· ${r.mgDl.round()} mg/dL · ${r.confidence}%',
                                style: const TextStyle(color: AppColors.muted, fontSize: 12, fontWeight: FontWeight.w400)),
                          ],
                        ),
                        subtitle: Text(DateFormat('MMM d, HH:mm').format(r.timestamp),
                            style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                      )),
              ],
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, st) => Text('Error: $e'),
        ),
      ],
    );
  }
}

class _TimeRangeSelector extends StatelessWidget {
  const _TimeRangeSelector({required this.value, required this.onTap});

  final Duration value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFE7EAF1),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              const Icon(Icons.schedule, size: 18, color: AppColors.accent),
              const SizedBox(width: 8),
              Text(
                'Last ${formatDuration(value)}',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.accent),
              ),
              const Spacer(),
              const Text('Change', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF4B5563))),
              const Icon(Icons.chevron_right, size: 18, color: Color(0xFF4B5563)),
            ],
          ),
        ),
      ),
    );
  }
}
