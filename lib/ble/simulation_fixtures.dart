import '../core/glucose_class.dart';
import '../models/glucose_reading.dart';

/// Execution mode for scenario playback.
enum SimulationPlaybackMode { instant, timed, step }

/// A single discrete event within a simulation scenario fixture.
class SimulationEvent {
  const SimulationEvent({
    this.delayMs = 1000,
    this.reading,
    this.isDisconnect = false,
    this.isReconnect = false,
    this.isCorrupt = false,
    this.corruptBytes,
    this.batteryLevel,
    required this.logMessage,
  });

  final int delayMs;
  final GlucoseReading? reading;
  final bool isDisconnect;
  final bool isReconnect;
  final bool isCorrupt;
  final List<int>? corruptBytes;
  final int? batteryLevel;
  final String logMessage;
}

/// Data fixture representing a complete test scenario.
class SimulationScenario {
  const SimulationScenario({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.expectedOutcome,
    required this.events,
  });

  final String id;
  final String title;
  final String category;
  final String description;
  final String expectedOutcome;
  final List<SimulationEvent> events;
}

/// Registry of 9 data fixtures across 6 categories matching app_simulation_implementation_plan.md.
class SimulationFixturesRegistry {
  SimulationFixturesRegistry._();

  static final DateTime _baseTime = DateTime.now();

  static final List<SimulationScenario> allScenarios = [
    // 1. Regular Use
    SimulationScenario(
      id: 'regular_use_normal_range',
      title: 'Regular Use (Normal Range)',
      category: 'Regular Use',
      description: 'Stable BLE connection with 10 normal-range readings (90-120 mg/dL), normal battery, and zero alerts.',
      expectedOutcome: 'Continuous normal state display without alerts or errors.',
      events: List.generate(10, (i) {
        final val = 95.0 + (i % 5) * 4.0;
        return SimulationEvent(
          delayMs: 1000,
          batteryLevel: 98 - i,
          logMessage: 'Reading ${i + 1}/10: $val mg/dL (Normal)',
          reading: GlucoseReading(
            timestamp: _baseTime.add(Duration(minutes: i * 5)),
            mgDl: val,
            glucoseClass: GlucoseClass.normal,
            confidence: 95,
            flags: SensorHealthFlags.none,
            modelOrigin: ModelOrigin.onDevice,
            sequenceNumber: i + 1,
          ),
        );
      }),
    ),

    // 2. Extreme / Clinical: Hypoglycemia Event
    SimulationScenario(
      id: 'hypoglycemia_event',
      title: 'Hypoglycemia Event',
      category: 'Extreme / Clinical',
      description: 'Rapid descent into hypoglycemia (85 -> 68 -> 52 mg/dL) triggering low alert transition.',
      expectedOutcome: 'Low alert banner and notification triggered when passing below 80 mg/dL.',
      events: [
        SimulationEvent(
          delayMs: 1000,
          logMessage: 'Baseline reading: 85 mg/dL (Normal)',
          reading: GlucoseReading(
            timestamp: _baseTime,
            mgDl: 85.0,
            glucoseClass: GlucoseClass.normal,
            confidence: 92,
            sequenceNumber: 1,
          ),
        ),
        SimulationEvent(
          delayMs: 1000,
          logMessage: 'Descent: 68 mg/dL (Low)',
          reading: GlucoseReading(
            timestamp: _baseTime.add(const Duration(minutes: 5)),
            mgDl: 68.0,
            glucoseClass: GlucoseClass.low,
            confidence: 90,
            sequenceNumber: 2,
          ),
        ),
        SimulationEvent(
          delayMs: 1000,
          logMessage: 'Severe Low: 52 mg/dL (Low)',
          reading: GlucoseReading(
            timestamp: _baseTime.add(const Duration(minutes: 10)),
            mgDl: 52.0,
            glucoseClass: GlucoseClass.low,
            confidence: 95,
            sequenceNumber: 3,
          ),
        ),
      ],
    ),

    // 2. Extreme / Clinical: Hyperglycemia Event
    SimulationScenario(
      id: 'hyperglycemia_event',
      title: 'Hyperglycemia Event',
      category: 'Extreme / Clinical',
      description: 'Steep rise into hyperglycemia (130 -> 195 -> 240 mg/dL) triggering high alert transition.',
      expectedOutcome: 'High alert banner and notification triggered when passing above 170 mg/dL.',
      events: [
        SimulationEvent(
          delayMs: 1000,
          logMessage: 'Baseline reading: 130 mg/dL (Normal)',
          reading: GlucoseReading(
            timestamp: _baseTime,
            mgDl: 130.0,
            glucoseClass: GlucoseClass.normal,
            confidence: 94,
            sequenceNumber: 1,
          ),
        ),
        SimulationEvent(
          delayMs: 1000,
          logMessage: 'Steep Rise: 195 mg/dL (High)',
          reading: GlucoseReading(
            timestamp: _baseTime.add(const Duration(minutes: 5)),
            mgDl: 195.0,
            glucoseClass: GlucoseClass.high,
            confidence: 91,
            sequenceNumber: 2,
          ),
        ),
        SimulationEvent(
          delayMs: 1000,
          logMessage: 'Severe High: 240 mg/dL (High)',
          reading: GlucoseReading(
            timestamp: _baseTime.add(const Duration(minutes: 10)),
            mgDl: 240.0,
            glucoseClass: GlucoseClass.high,
            confidence: 96,
            sequenceNumber: 3,
          ),
        ),
      ],
    ),

    // 2. Extreme / Clinical: Rapid Swings
    SimulationScenario(
      id: 'rapid_swings',
      title: 'Rapid Swings',
      category: 'Extreme / Clinical',
      description: 'Oscillating across low, normal, and high thresholds to test edge-triggered alerts and debouncing.',
      expectedOutcome: 'Proper state transitions and alert handling without duplicate triggers.',
      events: [
        SimulationEvent(
          delayMs: 1000,
          logMessage: 'Swing 1: 65 mg/dL (Low)',
          reading: GlucoseReading(
            timestamp: _baseTime,
            mgDl: 65.0,
            glucoseClass: GlucoseClass.low,
            confidence: 90,
            sequenceNumber: 1,
          ),
        ),
        SimulationEvent(
          delayMs: 1000,
          logMessage: 'Swing 2: 110 mg/dL (Normal)',
          reading: GlucoseReading(
            timestamp: _baseTime.add(const Duration(minutes: 5)),
            mgDl: 110.0,
            glucoseClass: GlucoseClass.normal,
            confidence: 93,
            sequenceNumber: 2,
          ),
        ),
        SimulationEvent(
          delayMs: 1000,
          logMessage: 'Swing 3: 210 mg/dL (High)',
          reading: GlucoseReading(
            timestamp: _baseTime.add(const Duration(minutes: 10)),
            mgDl: 210.0,
            glucoseClass: GlucoseClass.high,
            confidence: 92,
            sequenceNumber: 3,
          ),
        ),
      ],
    ),

    // 3. Confidence & Quality: Low Confidence & Disagreement
    SimulationScenario(
      id: 'low_confidence_disagreement',
      title: 'Low Confidence & Model Origin',
      category: 'Confidence & Quality',
      description: 'Low-confidence readings (<50%) and model origin toggles (on-device vs phone background).',
      expectedOutcome: 'Low confidence warning badge displayed on Now screen.',
      events: [
        SimulationEvent(
          delayMs: 1000,
          logMessage: 'On-device low confidence (40%)',
          reading: GlucoseReading(
            timestamp: _baseTime,
            mgDl: 105.0,
            glucoseClass: GlucoseClass.normal,
            confidence: 40,
            modelOrigin: ModelOrigin.onDevice,
            sequenceNumber: 1,
          ),
        ),
        SimulationEvent(
          delayMs: 1000,
          logMessage: 'Phone background fallback (88% confidence)',
          reading: GlucoseReading(
            timestamp: _baseTime.add(const Duration(minutes: 5)),
            mgDl: 112.0,
            glucoseClass: GlucoseClass.normal,
            confidence: 88,
            modelOrigin: ModelOrigin.phoneBackground,
            sequenceNumber: 2,
          ),
        ),
      ],
    ),

    // 3. Confidence & Quality: Corrupted & Missing Packets
    SimulationScenario(
      id: 'corrupted_missing_packets',
      title: 'Corrupted & Missing Packets',
      category: 'Confidence & Quality',
      description: 'Malformed byte sequences and truncated payloads to verify zero app crashes.',
      expectedOutcome: 'App handles malformed bytes gracefully without crashing or corrupting state.',
      events: [
        SimulationEvent(
          delayMs: 1000,
          isCorrupt: true,
          corruptBytes: [0xFF, 0x00],
          logMessage: 'Received truncated 2-byte payload [0xFF, 0x00]',
        ),
        SimulationEvent(
          delayMs: 1000,
          logMessage: 'Valid packet recovery: 100 mg/dL',
          reading: GlucoseReading(
            timestamp: _baseTime.add(const Duration(minutes: 5)),
            mgDl: 100.0,
            glucoseClass: GlucoseClass.normal,
            confidence: 95,
            sequenceNumber: 2,
          ),
        ),
      ],
    ),

    // 4. Connectivity: Mid-Stream Disconnect & Reconnect
    SimulationScenario(
      id: 'disconnect_reconnect',
      title: 'Mid-Stream Disconnect & Reconnect',
      category: 'Connectivity',
      description: 'Mid-stream BLE disconnect event, reconnection delay, and stream recovery.',
      expectedOutcome: 'Connection banner updates to disconnected then reconnected, resuming stream.',
      events: [
        SimulationEvent(
          delayMs: 1000,
          logMessage: 'Initial reading before drop: 102 mg/dL',
          reading: GlucoseReading(
            timestamp: _baseTime,
            mgDl: 102.0,
            glucoseClass: GlucoseClass.normal,
            confidence: 94,
            sequenceNumber: 1,
          ),
        ),
        SimulationEvent(
          delayMs: 1000,
          isDisconnect: true,
          logMessage: 'GATT Disconnect event triggered',
        ),
        SimulationEvent(
          delayMs: 1500,
          isReconnect: true,
          logMessage: 'BLE Reconnected & Services Discovered',
        ),
        SimulationEvent(
          delayMs: 1000,
          logMessage: 'Post-reconnect reading: 108 mg/dL',
          reading: GlucoseReading(
            timestamp: _baseTime.add(const Duration(minutes: 5)),
            mgDl: 108.0,
            glucoseClass: GlucoseClass.normal,
            confidence: 96,
            sequenceNumber: 2,
          ),
        ),
      ],
    ),

    // 5. Signal Integrity: Health Flags
    SimulationScenario(
      id: 'signal_integrity_flags',
      title: 'Sensor Health Flags',
      category: 'Signal Integrity',
      description: 'Packets carrying motion artifact, poor skin contact, low battery, and sensor fault bitmasks.',
      expectedOutcome: 'Sensor warning badges displayed on NowScreen.',
      events: [
        SimulationEvent(
          delayMs: 1000,
          logMessage: 'Packet with Motion Artifact (0x01)',
          reading: GlucoseReading(
            timestamp: _baseTime,
            mgDl: 110.0,
            glucoseClass: GlucoseClass.normal,
            confidence: 70,
            flags: const SensorHealthFlags(motionArtifact: true),
            sequenceNumber: 1,
          ),
        ),
        SimulationEvent(
          delayMs: 1000,
          logMessage: 'Packet with Poor Contact (0x02) & Low Battery (0x04)',
          reading: GlucoseReading(
            timestamp: _baseTime.add(const Duration(minutes: 5)),
            mgDl: 115.0,
            glucoseClass: GlucoseClass.normal,
            confidence: 60,
            flags: const SensorHealthFlags(poorSkinContact: true, lowBattery: true),
            sequenceNumber: 2,
          ),
        ),
      ],
    ),

    // 6. Timing: Burst & Jitter
    SimulationScenario(
      id: 'timing_burst_and_jitter',
      title: 'Timing Burst & Out-of-Order Jitter',
      category: 'Timing',
      description: 'High-frequency burst packets (0ms gap) and out-of-order sequence counters.',
      expectedOutcome: 'App processes high-rate packet stream without UI lag or database lockups.',
      events: List.generate(5, (i) {
        return SimulationEvent(
          delayMs: 50, // Burst
          logMessage: 'Burst packet ${i + 1}/5 (0ms delay gap)',
          reading: GlucoseReading(
            timestamp: _baseTime.add(Duration(seconds: i * 2)),
            mgDl: 98.0 + i,
            glucoseClass: GlucoseClass.normal,
            confidence: 95,
            sequenceNumber: i + 1,
          ),
        );
      }),
    ),
  ];
}
