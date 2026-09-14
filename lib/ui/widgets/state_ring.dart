import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../clinical/trend_calculator.dart';
import '../../core/theme.dart';
import '../../models/glucose_reading.dart';
import '../../state/clinical_providers.dart';

class StateRing extends ConsumerWidget {
  const StateRing({super.key, required this.reading});

  final GlucoseReading? reading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trend = ref.watch(glucoseTrendProvider);
    final calib = ref.watch(glucoseCalibrationProvider);
    final color = reading != null ? AppColors.forClass(reading!.glucoseClass) : AppColors.muted;

    return Column(
      children: [
        Container(
          width: 150,
          height: 150,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(color: color, width: 10),
          ),
          child: Icon(
            reading != null ? reading!.glucoseClass.icon : Icons.help_outline_rounded,
            size: 56,
            color: color,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          reading != null ? reading!.glucoseClass.label : 'No reading',
          style: TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: color),
        ),
        if (reading != null) ...[
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                '${reading!.mgDl.round()} mg/dL',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.ink),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.accentSoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  trend.direction.symbol,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.accent),
                ),
              ),
            ],
          ),
          if (trend.rateOfChange != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                TrendCalculator.formatRateOfChange(trend.rateOfChange),
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.ink),
              ),
            ),
          const SizedBox(height: 4),
          Text(reading!.glucoseClass.clinicalName, style: const TextStyle(fontSize: 14, color: AppColors.muted)),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              Chip(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                avatar: const Icon(Icons.memory_outlined, size: 14, color: AppColors.accent),
                label: Text(
                  reading!.modelOrigin.label,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                ),
              ),
              Chip(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                avatar: Icon(
                  calib.ready ? Icons.check_circle_outline : Icons.warning_amber_rounded,
                  size: 14,
                  color: calib.ready ? AppColors.normal : AppColors.high,
                ),
                label: Text(
                  calib.ready
                      ? 'Calibrated (${calib.baseline.round()} mg/dL)'
                      : 'Needs Calibration',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: calib.ready ? AppColors.normal : AppColors.high,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.verified_outlined, size: 15, color: AppColors.muted),
              const SizedBox(width: 5),
              Text('${reading!.confidence}% confidence', style: const TextStyle(fontSize: 13, color: AppColors.muted)),
            ],
          ),
          if (reading!.isLowConfidence)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.warning_amber_rounded, size: 14, color: AppColors.high),
                  SizedBox(width: 4),
                  Text('Low confidence reading', style: TextStyle(fontSize: 12, color: AppColors.high)),
                ],
              ),
            ),
          if (reading!.flags.hasAnyIssue)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.high.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Sensor Warning: ${reading!.flags}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.high),
                ),
              ),
            ),
        ] else
          const Text('Waiting for device', style: TextStyle(fontSize: 14, color: AppColors.muted)),
      ],
    );
  }
}
