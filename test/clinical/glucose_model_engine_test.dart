import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

import 'package:glucose_monitor/clinical/glucose_model_engine.dart';
import 'package:glucose_monitor/clinical/trend_calculator.dart';
import 'package:glucose_monitor/core/glucose_class.dart';
import 'package:glucose_monitor/models/glucose_reading.dart';

void main() {
  group('GlucoseModelEngine - Parity Tests against C Model', () {
    late GlucoseModelEngine engine;

    // Fixtures from glucose_model_test.h
    final testVectors = <List<double>>[
      [0.36451328, 0.192161091, -0.395668815, -1.13201515, -0.682098206, -0.0468257952, -0.425646582, -0.42564658, -0.415260368, 0.0140609773, 0.731625764, 0.705953737, 0.694395965, 0.467957251, 0.958570376, 1.33758325, 1.70058394, -0.24579875, 0.905040127, 0.691211455, -0.242396849, -0.1682215],
      [-0.501592349, -1.20375083, -0.194291759, 2.40788756, 3.84076294, 0.537537275, 0.944729516, 0.914955428, -0.0119515262, -0.926970614, -1.18875051, -1.31654793, -1.31215823, -1.44110546, -1.80613108, -0.711990468, -1.35608748, 0.242588918, -1.03625185, 0.917668208, -0.819816334, -0.907831129],
      [-1.78992905, -1.03854278, 3.00918733, -1.29349744, -0.167860913, 1.1396493, 0.0695559239, 0.0695559326, 1.04896924, 2.02387847, 0.697220826, 0.894616923, 0.939106149, 0.764752006, 1.043218, 1.02039945, 1.10031018, -0.286409944, 0.988905156, -1.73038646, -0.141186951, -0.32472744],
      [0.792290447, 0.813074287, -0.262619519, -0.200417139, -0.432994158, -0.485338334, 0.33930825, 0.339308255, 0.856160792, -0.671268252, 0.388652137, 0.128330544, 0.299963684, 0.39722539, 0.107436185, -0.421320111, -0.432898976, -0.332304245, 0.214218534, -0.211887861, 0.066721241, -0.783604603],
      [-0.00386127677, 0.57162717, -0.40588474, 0.986447291, -1.12951121, -0.220595589, 0.375491943, 0.375491947, -1.22900914, -0.603246081, -0.897764545, -0.83541961, -1.21611349, -1.37275304, -1.17793246, -0.844141437, -1.17963519, 0.676987135, -1.14704744, 0.743040509, -0.369050435, 0.0403179563],
      [-0.999904627, -0.826589694, -0.279849111, -0.347355062, -0.206990704, 3.21192107, -0.711137648, -1.41838599, -1.16336056, -0.791596708, -1.50246432, -1.43273204, -0.321939869, 0.506682326, -0.757917017, -0.441902037, 0.199643216, -0.305809209, -1.0525165, 0.805796882, -0.687017416, 0.467859626],
      [-0.676073443, -0.0426387434, -0.194291759, 1.90830833, 2.92759501, -1.37436779, -0.257608536, 0.0243619152, -1.29355831, -1.04725437, -0.778434166, 0.820071123, 0.241696781, 0.865994091, 0.085332765, 0.322367378, 0.0592914752, 0.411260586, -1.05040416, 1.12302374, -0.56430386, -1.0524818],
      [-1.3691407, -0.745136715, -0.136082763, 0.00985076752, -0.0905800386, 5.06086721, -7.19082808, -8.08686231, -1.30195327, -0.0905158359, -1.95429262, 1.27987499, 1.26567498, 0.459574289, 0.855774732, 1.01397086, 0.867452199, 2.34537002, -1.63662495, 0.85456903, -0.959623506, -0.082934193],
      [-1.56650136, 0.0711039062, 3.46563561, -1.1004278, 0.0365071918, 0.807267243, -1.03994742, -1.03994741, -0.123296827, 0.7829761, 0.767115329, 0.249822819, 0.593843628, 0.92588543, 0.743007374, 0.0322758463, 0.639054278, -0.502197911, 1.08450657, 0.365109019, -0.157295208, 0.126656774],
      [-0.218394382, 0.183188321, -0.300841791, 1.08492901, -1.01448623, 0.359447752, -0.805577736, -0.80557772, -0.746976386, -0.545622272, -0.792506424, 0.956990278, 0.45738386, 0.264131061, 0.593394677, 0.726311612, 0.683372491, -0.246038001, -0.289048132, -0.452557972, -0.124511075, 0.217832322],
      [0.070616296, -1.60049249, -0.282945809, 0.546080965, 1.05127794, -0.582609925, 0.140427526, 0.140427537, 0.416884396, -0.972689598, -0.167439429, 1.0370653, 0.896313551, 0.636534052, 0.647340752, 2.02074275, 0.759721067, 0.136010291, -0.166862275, -0.788502943, -0.208834172, -2.62742545e-05],
      [-1.62857133, 0.588506878, 2.73802914, -0.108902147, -0.70398796, 0.488753745, 0.420199026, 0.420199024, 0.571524923, 0.898779661, 0.672326604, 1.11177004, 1.25995409, 1.03291854, 1.00965376, 0.694861552, 1.5890569, -0.522610335, 0.369815955, 0.0425159008, -0.289658429, -0.13398415],
    ];

    final expectedDeltas = <double>[
      -10.3919524, -38.4400192, -11.3098496, 1.19967322, 2.71090257, -12.1868877,
      -48.0413502, 103.305928, -6.90641251, -8.61948692, 4.09120525, 18.6144726,
    ];

    setUpAll(() {
      final cFile = File('Model/glucose_model.c');
      expect(cFile.existsSync(), isTrue, reason: 'Model/glucose_model.c must exist');
      final cSource = cFile.readAsStringSync();
      engine = GlucoseModelEngine.fromCSource(cSource);
    });

    test('Parses exactly 400 trees and 24400 nodes', () {
      expect(engine.treeStart.length, equals(400));
      expect(engine.feat.length, equals(24400));
      expect(engine.left.length, equals(24400));
      expect(engine.right.length, equals(24400));
      expect(engine.thr.length, equals(24400));
    });

    test('Matches C model delta predictions across all 12 test vectors', () {
      for (var i = 0; i < testVectors.length; i++) {
        final delta = engine.predictDelta(testVectors[i]);
        final expected = expectedDeltas[i];
        expect(delta, closeTo(expected, 1e-3),
            reason: 'Vector $i prediction mismatch: got $delta, expected $expected');
      }
    });

    test('Predicts glucose with baseline clamping', () {
      const baseline = 100.0;
      final g = engine.predictGlucose(testVectors[0], baseline);
      expect(g, closeTo(100.0 - 10.3919524, 1e-3));
    });
  });

  group('GlucoseCalibration Tests', () {
    test('Welford running mean and SD calculation', () {
      final calib = GlucoseCalibration();
      for (var i = 0; i < 20; i++) {
        calib.addRawFeatures(List<double>.filled(22, 10.0 + i));
      }
      calib.addReferenceGlucose(110.0);
      final success = calib.finish();

      expect(success, isTrue);
      expect(calib.baseline, equals(110.0));
      expect(calib.mean[0], closeTo(19.5, 1e-3));
      expect(calib.ready, isTrue);
    });
  });

  group('TrendCalculator Tests', () {
    test('Calculates rising fast trend (> 2.0 mg/dL/min)', () {
      final t0 = DateTime.now();
      final readings = [
        GlucoseReading(timestamp: t0, mgDl: 100.0, glucoseClass: GlucoseClass.normal, confidence: 95),
        GlucoseReading(timestamp: t0.add(const Duration(minutes: 5)), mgDl: 115.0, glucoseClass: GlucoseClass.normal, confidence: 95),
        GlucoseReading(timestamp: t0.add(const Duration(minutes: 10)), mgDl: 130.0, glucoseClass: GlucoseClass.high, confidence: 95),
      ];

      final roc = TrendCalculator.calculateRateOfChange(readings);
      expect(roc, closeTo(3.0, 1e-2));

      final direction = TrendCalculator.getTrendDirection(roc);
      expect(direction, equals(GlucoseTrendDirection.risingFast));
      expect(direction.symbol, equals('⇈'));
    });
  });
}
