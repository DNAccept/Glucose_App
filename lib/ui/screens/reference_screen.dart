import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/glucose_class.dart';
import '../../core/theme.dart';
import '../../models/glucose_reading.dart';
import '../../models/reference_reading.dart';
import '../../state/clinical_providers.dart';
import '../../state/data_providers.dart';
import '../../state/readings_providers.dart';
import '../widgets/confusion_matrix.dart';

class ReferenceScreen extends ConsumerStatefulWidget {
  const ReferenceScreen({super.key});

  @override
  ConsumerState<ReferenceScreen> createState() => _ReferenceScreenState();
}

class _ReferenceScreenState extends ConsumerState<ReferenceScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final latest = ref.watch(latestReadingProvider).valueOrNull;
    final referencesAsync = ref.watch(referencesProvider);
    final accuracyAsync = ref.watch(accuracyProvider);
    final value = int.tryParse(_controller.text);
    final previewClass = value != null && value > 0 ? GlucoseClass.fromMgDl(value) : null;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Reference log')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Check against a finger-prick', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Text(
                    'Enter your glucometer value. It becomes a class (low below '
                    '${GlucoseClass.lowCutMgDl}, high above ${GlucoseClass.highCutMgDl} mg/dL) '
                    'and is compared with the device prediction.',
                    style: const TextStyle(fontSize: 13, color: AppColors.muted, height: 1.4),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: 'Finger-prick mg/dL',
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFD5DAE6)),
                            ),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: value != null && value > 0 ? () => _addReference(value, latest) : null,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Add'),
                      ),
                    ],
                  ),
                  if (previewClass != null) ...[
                    const SizedBox(height: 12),
                    Text.rich(TextSpan(
                      style: const TextStyle(fontSize: 13.5, color: AppColors.ink),
                      children: [
                        const TextSpan(text: 'That reads as '),
                        TextSpan(
                          text: previewClass.label,
                          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.forClass(previewClass)),
                        ),
                      ],
                    )),
                    Text.rich(TextSpan(
                      style: const TextStyle(fontSize: 13.5, color: AppColors.ink),
                      children: [
                        const TextSpan(text: 'Device now: '),
                        TextSpan(
                          text: latest != null ? latest.glucoseClass.label : 'no reading',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: latest != null ? AppColors.forClass(latest.glucoseClass) : AppColors.muted,
                          ),
                        ),
                      ],
                    )),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          accuracyAsync.when(
            data: (summary) => summary.total == 0
                ? const SizedBox()
                : Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Agreement', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          ConfusionMatrix(summary: summary),
                        ],
                      ),
                    ),
                  ),
            loading: () => const SizedBox(),
            error: (e, st) => Text('Error: $e'),
          ),
          const SizedBox(height: 14),
          const Padding(
            padding: EdgeInsets.only(left: 2, bottom: 8),
            child: Text('History', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.muted)),
          ),
          referencesAsync.when(
            data: (entries) => entries.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Text('No reference readings yet.', style: TextStyle(color: AppColors.muted)),
                  )
                : Column(children: entries.map(_referenceRow).toList()),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => Text('Error: $e'),
          ),
        ],
      ),
    );
  }

  Widget _referenceRow(ReferenceReading e) {
    final match = e.classesAgree;
    final color = !e.hasDeviceReading ? AppColors.muted : (match ? AppColors.normal : AppColors.low);
    final icon = !e.hasDeviceReading ? Icons.help_outline_rounded : (match ? Icons.check_rounded : Icons.close_rounded);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(backgroundColor: color.withValues(alpha: 0.13), foregroundColor: color, child: Icon(icon, size: 18)),
      title: Text.rich(TextSpan(
        style: const TextStyle(fontSize: 15, color: AppColors.ink),
        children: [
          TextSpan(text: '${e.referenceValueMgDl} mg/dL · '),
          TextSpan(text: e.referenceClass.label, style: TextStyle(color: AppColors.forClass(e.referenceClass))),
        ],
      )),
      subtitle: Text(
        'device: ${e.hasDeviceReading ? '${e.deviceClass!.label}${e.deviceConfidence != null ? ' (${e.deviceConfidence}%)' : ''}' : 'no reading'} · ${DateFormat('HH:mm').format(e.timestamp)}',
        style: const TextStyle(fontSize: 12, color: AppColors.muted),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline, color: Color(0xFF9AA2AF)),
        onPressed: e.id == null
            ? null
            : () async {
                await ref.read(referenceRepositoryProvider).deleteReference(e.id!);
                await ref.read(glucoseCalibrationProvider.notifier).updateBaselineFromReferences();
              },
      ),
    );
  }

  Future<void> _addReference(int value, GlucoseReading? latest) async {
    final referenceClass = GlucoseClass.fromMgDl(value);
    await ref.read(referenceRepositoryProvider).addReference(ReferenceReading(
          referenceValueMgDl: value,
          referenceClass: referenceClass,
          deviceMgDl: latest?.mgDl,
          deviceClass: latest?.glucoseClass,
          deviceConfidence: latest?.confidence,
          timestamp: DateTime.now(),
        ));
    await ref.read(glucoseCalibrationProvider.notifier).updateBaselineFromReferences();
    _controller.clear();
    setState(() {});
  }
}
