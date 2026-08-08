import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../data/readings_repository.dart';

/// Proportional low/normal/high segment bar with a legend — ported from the
/// mockup's `tisBar()` flex-div bar as a CustomPainter instead of nested
/// widgets, so the segment weights are pixel-exact.
class TimeInStateBar extends StatelessWidget {
  const TimeInStateBar({super.key, required this.fractions});

  final TimeInStateFractions fractions;

  @override
  Widget build(BuildContext context) {
    if (fractions.count == 0) {
      return const Text(
        'No readings in this window',
        style: TextStyle(color: AppColors.muted, fontSize: 13),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: 16,
            child: Row(
              children: [
                if (fractions.low > 0) Expanded(flex: _weight(fractions.low), child: Container(color: AppColors.low)),
                if (fractions.normal > 0) Expanded(flex: _weight(fractions.normal), child: Container(color: AppColors.normal)),
                if (fractions.high > 0) Expanded(flex: _weight(fractions.high), child: Container(color: AppColors.high)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 14,
          runSpacing: 8,
          children: [
            _LegendDot(color: AppColors.normal, label: 'Normal ${_pct(fractions.normal)}%'),
            _LegendDot(color: AppColors.low, label: 'Low ${_pct(fractions.low)}%'),
            _LegendDot(color: AppColors.high, label: 'High ${_pct(fractions.high)}%'),
          ],
        ),
      ],
    );
  }

  int _weight(double f) => (f * 1000).round().clamp(1, 1000);
  int _pct(double f) => (f * 100).round();
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12.5, color: Color(0xFF374151))),
      ],
    );
  }
}
