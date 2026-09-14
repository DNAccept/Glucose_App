import 'package:flutter/material.dart';

import '../../core/theme.dart';

class StaleDataBanner extends StatelessWidget {
  const StaleDataBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.high.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.high.withOpacity(0.3)),
      ),
      child: Row(
        children: const [
          Icon(Icons.warning_amber_rounded, size: 22, color: AppColors.high),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Glucose Data Stale (>15 mins)',
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.high),
                ),
                SizedBox(height: 2),
                Text(
                  'No reading received recently. Check wearable connection.',
                  style: TextStyle(fontSize: 11.5, color: AppColors.ink),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
