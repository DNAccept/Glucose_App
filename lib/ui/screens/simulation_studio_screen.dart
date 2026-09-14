import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../ble/simulation_fixtures.dart';
import '../../core/theme.dart';
import '../../state/simulation_providers.dart';

class SimulationStudioScreen extends ConsumerStatefulWidget {
  const SimulationStudioScreen({super.key});

  @override
  ConsumerState<SimulationStudioScreen> createState() => _SimulationStudioScreenState();
}

class _SimulationStudioScreenState extends ConsumerState<SimulationStudioScreen> {
  String _selectedCategory = 'All';
  final ScrollController _logScrollController = ScrollController();
  bool _isRunningSelfTest = false;
  String? _selfTestSummary;

  @override
  void dispose() {
    _logScrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_logScrollController.hasClients) {
        _logScrollController.animateTo(
          _logScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _runAllScenariosSelfTest() async {
    setState(() {
      _isRunningSelfTest = true;
      _selfTestSummary = null;
    });

    final sim = ref.read(simulatedBleManagerProvider);
    var passed = 0;
    var failed = 0;
    final total = SimulationFixturesRegistry.allScenarios.length;

    for (final scenario in SimulationFixturesRegistry.allScenarios) {
      try {
        await sim.playScenario(scenario, mode: SimulationPlaybackMode.instant);
        passed++;
      } catch (_) {
        failed++;
      }
    }

    if (mounted) {
      setState(() {
        _isRunningSelfTest = false;
        _selfTestSummary = 'Self-Test Complete: $passed/$total scenarios passed ($failed failed).';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final studioState = ref.watch(simulationStudioProvider);
    final studioNotifier = ref.read(simulationStudioProvider.notifier);
    final isSimulation = ref.watch(isSimulationModeProvider);

    _scrollToBottom();

    final categories = ['All', ...SimulationFixturesRegistry.allScenarios.map((s) => s.category).toSet()];
    final filteredScenarios = _selectedCategory == 'All'
        ? SimulationFixturesRegistry.allScenarios
        : SimulationFixturesRegistry.allScenarios.where((s) => s.category == _selectedCategory).toList();

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('BLE Simulation Studio'),
        actions: [
          Row(
            children: [
              const Text('Sim Mode', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              Switch(
                value: isSimulation,
                activeTrackColor: AppColors.accent,
                onChanged: (val) => ref.read(isSimulationModeProvider.notifier).state = val,
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          // Category Filter Bar
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: categories.map((cat) {
                final isSelected = _selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: FilterChip(
                    label: Text(cat, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : AppColors.ink)),
                    selected: isSelected,
                    selectedColor: AppColors.accent,
                    onSelected: (_) => setState(() => _selectedCategory = cat),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),

          // Scenario Selector List
          const Text('Test Scenarios', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          ...filteredScenarios.map((scenario) {
            final isSelected = studioState.activeScenario?.id == scenario.id;
            return Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isSelected ? AppColors.accent : Colors.transparent,
                  width: isSelected ? 2 : 0,
                ),
              ),
              child: ListTile(
                title: Text(scenario.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(scenario.description, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                    const SizedBox(height: 4),
                    Text('Expected: ${scenario.expectedOutcome}',
                        style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppColors.accent)),
                  ],
                ),
                trailing: Text('${scenario.events.length} steps', style: const TextStyle(fontSize: 11, color: AppColors.muted)),
                onTap: () => studioNotifier.selectScenario(scenario),
              ),
            );
          }),

          const SizedBox(height: 16),

          // Active Scenario Control Bar
          if (studioState.activeScenario != null) ...[
            Card(
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Active: ${studioState.activeScenario!.title}',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.accent),
                    ),
                    const SizedBox(height: 12),

                    // Execution Mode & Speed Sliders
                    Row(
                      children: [
                        const Text('Mode:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        const SizedBox(width: 8),
                        SegmentedButton<SimulationPlaybackMode>(
                          segments: const [
                            ButtonSegment(value: SimulationPlaybackMode.timed, label: Text('Timed')),
                            ButtonSegment(value: SimulationPlaybackMode.step, label: Text('Step')),
                            ButtonSegment(value: SimulationPlaybackMode.instant, label: Text('Instant')),
                          ],
                          selected: {studioState.playbackMode},
                          onSelectionChanged: (set) => studioNotifier.setPlaybackMode(set.first),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    if (studioState.playbackMode == SimulationPlaybackMode.timed) ...[
                      Row(
                        children: [
                          const Text('Speed:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          const SizedBox(width: 8),
                          ...[1.0, 2.0, 5.0, 10.0].map((s) {
                            final isSel = studioState.speedMultiplier == s;
                            return Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: ChoiceChip(
                                label: Text('${s.toInt()}x', style: TextStyle(fontSize: 11, color: isSel ? Colors.white : AppColors.ink)),
                                selected: isSel,
                                selectedColor: AppColors.accent,
                                onSelected: (_) => studioNotifier.setSpeedMultiplier(s),
                              ),
                            );
                          }),
                        ],
                      ),
                      const SizedBox(height: 10),
                    ],

                    // Action Buttons
                    Row(
                      children: [
                        if (!studioState.isPlaying)
                          ElevatedButton.icon(
                            onPressed: () => studioNotifier.play(),
                            icon: const Icon(Icons.play_arrow_rounded),
                            label: const Text('Play Scenario'),
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: Colors.white),
                          )
                        else
                          ElevatedButton.icon(
                            onPressed: () => studioNotifier.pause(),
                            icon: const Icon(Icons.pause_rounded),
                            label: const Text('Pause'),
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.high, foregroundColor: Colors.white),
                          ),
                        const SizedBox(width: 8),
                        if (studioState.playbackMode == SimulationPlaybackMode.step)
                          OutlinedButton.icon(
                            onPressed: () => studioNotifier.step(),
                            icon: const Icon(Icons.skip_next_rounded),
                            label: const Text('Next Step'),
                          ),
                        const Spacer(),
                        TextButton(
                          onPressed: () => studioNotifier.stop(),
                          child: const Text('Reset'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Automated Self-Test Runner Button & Summary
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Automated Self-Test Harness', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  const Text('Executes all 9 scenarios in instant mode to verify app stability and zero crashes.',
                      style: TextStyle(fontSize: 12, color: AppColors.muted)),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isRunningSelfTest ? null : _runAllScenariosSelfTest,
                      icon: _isRunningSelfTest
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.fact_check_outlined),
                      label: Text(_isRunningSelfTest ? 'Running All Scenarios...' : 'Run All 9 Scenarios Self-Test'),
                    ),
                  ),
                  if (_selfTestSummary != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.accentSoft,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(_selfTestSummary!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.accent)),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Terminal Log Viewer
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Simulation Event Log Terminal', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
              TextButton(
                onPressed: () => studioNotifier.clearLogs(),
                child: const Text('Clear Log', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Container(
            height: 180,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(10),
            ),
            child: studioState.logs.isEmpty
                ? const Center(child: Text('No events logged yet. Select and play a scenario.', style: TextStyle(color: Colors.grey, fontSize: 12)))
                : ListView.builder(
                    controller: _logScrollController,
                    itemCount: studioState.logs.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          studioState.logs[index],
                          style: const TextStyle(color: Color(0xFF4EC9B0), fontFamily: 'monospace', fontSize: 11),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
