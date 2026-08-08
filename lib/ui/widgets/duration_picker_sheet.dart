import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../state/readings_providers.dart';

/// "30m", "3h", "2h 30m", "5d", "5d 12h" ...
String formatDuration(Duration d) {
  final totalMinutes = d.inMinutes;
  if (totalMinutes < 60) {
    return '${totalMinutes}m';
  }
  if (totalMinutes < 24 * 60) {
    final h = totalMinutes ~/ 60;
    final m = totalMinutes % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }
  final days = totalMinutes ~/ (24 * 60);
  final hours = (totalMinutes % (24 * 60)) ~/ 60;
  return hours == 0 ? '${days}d' : '${days}d ${hours}h';
}

Future<void> showDurationPickerSheet(
  BuildContext context, {
  required Duration current,
  required ValueChanged<Duration> onChanged,
}) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (_) => _DurationPickerSheet(initial: current, onChanged: onChanged),
  );
}

class _DurationPickerSheet extends StatefulWidget {
  const _DurationPickerSheet({required this.initial, required this.onChanged});

  final Duration initial;
  final ValueChanged<Duration> onChanged;

  @override
  State<_DurationPickerSheet> createState() => _DurationPickerSheetState();
}

class _DurationPickerSheetState extends State<_DurationPickerSheet> {
  late Duration _value;

  static final double _minLog = math.log(historyWindowMin.inMinutes.toDouble());
  static final double _maxLog = math.log(historyWindowMax.inMinutes.toDouble());

  @override
  void initState() {
    super.initState();
    _value = widget.initial;
  }

  double get _sliderT {
    final minutes = _value.inMinutes.clamp(historyWindowMin.inMinutes, historyWindowMax.inMinutes);
    final t = (math.log(minutes.toDouble()) - _minLog) / (_maxLog - _minLog);
    return t.clamp(0.0, 1.0);
  }

  void _setFromSlider(double t) {
    final minutes = math.exp(_minLog + t * (_maxLog - _minLog));
    setState(() => _value = Duration(minutes: _niceMinutes(minutes.round())));
  }

  // Snaps the raw exponential-slider value to a step size that scales with
  // magnitude, so dragging feels deliberate instead of jittery — 1-minute
  // precision at the 30-day end of the range would be unusable.
  static int _niceMinutes(int minutes) {
    final int step;
    if (minutes < 60) {
      step = 5;
    } else if (minutes < 6 * 60) {
      step = 15;
    } else if (minutes < 24 * 60) {
      step = 60;
    } else if (minutes < 3 * 24 * 60) {
      step = 3 * 60;
    } else {
      step = 24 * 60;
    }
    final rounded = (minutes / step).round() * step;
    return rounded.clamp(historyWindowMin.inMinutes, historyWindowMax.inMinutes);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(color: const Color(0xFFDDE1E8), borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Time range', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            const Text('From 30 minutes up to 30 days', style: TextStyle(fontSize: 12.5, color: AppColors.muted)),
            const SizedBox(height: 14),
            Text(
              formatDuration(_value),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: AppColors.accent),
            ),
            Slider(value: _sliderT, onChanged: _setFromSlider, activeColor: AppColors.accent),
            const SizedBox(height: 4),
            const Text('Quick select', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.muted)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: historyWindowPresets.map((d) {
                final selected = d == _value;
                return ChoiceChip(
                  label: Text(formatDuration(d)),
                  selected: selected,
                  selectedColor: AppColors.accentSoft,
                  labelStyle: TextStyle(color: selected ? AppColors.accent : const Color(0xFF374151), fontWeight: FontWeight.w600),
                  onSelected: (_) => setState(() => _value = d),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () {
                widget.onChanged(_value);
                Navigator.of(context).pop();
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }
}
