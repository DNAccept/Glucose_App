import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../data/readings_repository.dart';

/// Rows = finger-prick reference class, columns = device class — ported
/// from the mockup's `accuracy()`/matrix markup.
class ConfusionMatrix extends StatelessWidget {
  const ConfusionMatrix({super.key, required this.summary});

  final AccuracySummary summary;

  static const _labels = ['Low', 'Norm', 'High'];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${(summary.agreementRate * 100).round()}',
              style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w800, color: AppColors.accent, height: 1),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 4, left: 4),
              child: Text(
                '% (${summary.agree}/${summary.total})',
                style: const TextStyle(fontSize: 15, color: AppColors.muted, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        if (summary.meanAbsoluteErrorMgDl != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Mean absolute error: ${summary.meanAbsoluteErrorMgDl!.toStringAsFixed(1)} mg/dL',
              style: const TextStyle(fontSize: 12.5, color: AppColors.muted),
            ),
          ),
        const Padding(
          padding: EdgeInsets.only(top: 12, bottom: 8),
          child: Text('rows: finger-prick · columns: device', style: TextStyle(fontSize: 11.5, color: AppColors.muted)),
        ),
        Table(
          children: [
            TableRow(children: [
              const SizedBox(),
              for (final l in _labels) _headCell(l),
            ]),
            for (var r = 0; r < 3; r++)
              TableRow(children: [
                _headCell(_labels[r]),
                for (var c = 0; c < 3; c++) _valueCell(summary.confusion[r][c], isDiagonal: r == c),
              ]),
          ],
        ),
      ],
    );
  }

  Widget _headCell(String text) => Padding(
        padding: const EdgeInsets.all(1.5),
        child: Container(
          height: 38,
          alignment: Alignment.center,
          child: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.muted)),
        ),
      );

  Widget _valueCell(int value, {required bool isDiagonal}) {
    final bg = isDiagonal
        ? AppColors.normal.withValues(alpha: 0.14)
        : (value > 0 ? AppColors.low.withValues(alpha: 0.10) : const Color(0xFFF4F6F9));
    final fg = isDiagonal ? AppColors.normal : (value > 0 ? const Color(0xFFA32D2D) : AppColors.ink);
    return Padding(
      padding: const EdgeInsets.all(1.5),
      child: Container(
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
        child: Text('$value', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: fg)),
      ),
    );
  }
}
