import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../models/glucose_reading.dart';

class StateRing extends StatelessWidget {
  const StateRing({super.key, required this.reading});

  final GlucoseReading? reading;

  @override
  Widget build(BuildContext context) {
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
          Text(
            '${reading!.mgDl.round()} mg/dL',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.ink),
          ),
          const SizedBox(height: 2),
          Text(reading!.glucoseClass.clinicalName, style: const TextStyle(fontSize: 14, color: AppColors.muted)),
          const SizedBox(height: 10),
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
        ] else
          const Text('Waiting for device', style: TextStyle(fontSize: 14, color: AppColors.muted)),
      ],
    );
  }
}
