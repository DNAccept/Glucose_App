import 'dart:math' as math;

import 'dart:typed_data';

import '../core/glucose_class.dart';
import 'model_features.dart';

/// Clinical constants from glucose_model.h notebook spec.
class ClinicalConstants {
  ClinicalConstants._();

  static const double gluMin = 41.0;
  static const double gluMax = 399.0;
  static const double ruleLow = 80.0;
  static const double ruleHigh = 170.0;
  static const double bias = 0.0;
  static const int numTrees = 400;
  static const int numNodes = 24400;
  static const int numFeatures = 22;
}

/// Subject-specific Welford calibration state.
/// Mirrors `gm_calib_t` in glucose_model.h.
class GlucoseCalibration {
  GlucoseCalibration({
    List<double>? mean,
    List<double>? m2,
    List<double>? sd,
    this.baseline = 0.0,
    this.gluSum = 0.0,
    this.n = 0,
    this.nGlu = 0,
    this.ready = false,
  })  : mean = mean ?? List<double>.filled(ClinicalConstants.numFeatures, 0.0),
        m2 = m2 ?? List<double>.filled(ClinicalConstants.numFeatures, 0.0),
        sd = sd ?? List<double>.filled(ClinicalConstants.numFeatures, 1.0);

  final List<double> mean;
  final List<double> m2;
  final List<double> sd;
  double baseline;
  double gluSum;
  int n;
  int nGlu;
  bool ready;

  void reset() {
    for (var i = 0; i < ClinicalConstants.numFeatures; i++) {
      mean[i] = 0.0;
      m2[i] = 0.0;
      sd[i] = 1.0;
    }
    baseline = 0.0;
    gluSum = 0.0;
    n = 0;
    nGlu = 0;
    ready = false;
  }

  /// Adds a raw 22-feature window to the Welford running statistics.
  void addRawFeatures(List<double> raw) {
    n++;
    for (var i = 0; i < ClinicalConstants.numFeatures; i++) {
      final val = i < raw.length ? raw[i] : 0.0;
      final delta = val - mean[i];
      mean[i] += delta / n;
      m2[i] += delta * (val - mean[i]);
    }
  }

  /// Adds a finger-stick reference glucose value (mg/dL).
  void addReferenceGlucose(double glucoseMgDl) {
    gluSum += glucoseMgDl;
    nGlu++;
  }

  /// Finalizes running statistics and computes feature standard deviations & baseline.
  /// Returns true if calibration succeeds (n >= 10 and nGlu >= 1).
  bool finish() {
    if (n < 10 || nGlu < 1) {
      ready = false;
      return false;
    }
    for (var i = 0; i < ClinicalConstants.numFeatures; i++) {
      final variance = m2[i] / (n - 1);
      final s = variance > 0.0 ? math.sqrt(variance) : 0.0;
      sd[i] = s > 1e-6 ? s : 1.0;
    }
    baseline = gluSum / nGlu;
    ready = true;
    return true;
  }

  /// Transforms raw feature vector into Z-scored feature vector [z].
  List<double> applyCalib(List<double> raw) {
    final z = List<double>.filled(ClinicalConstants.numFeatures, 0.0);
    for (var i = 0; i < ClinicalConstants.numFeatures; i++) {
      final val = i < raw.length ? raw[i] : 0.0;
      var v = (val - mean[i]) / sd[i];
      if (v.isNaN || v.isInfinite) v = 0.0;
      z[i] = v;
    }
    return z;
  }

  Map<String, dynamic> toJson() => {
        'mean': mean,
        'm2': m2,
        'sd': sd,
        'baseline': baseline,
        'gluSum': gluSum,
        'n': n,
        'nGlu': nGlu,
        'ready': ready,
      };

  factory GlucoseCalibration.fromJson(Map<String, dynamic> json) => GlucoseCalibration(
        mean: List<double>.from(json['mean'] as List? ?? []),
        m2: List<double>.from(json['m2'] as List? ?? []),
        sd: List<double>.from(json['sd'] as List? ?? []),
        baseline: (json['baseline'] as num?)?.toDouble() ?? 0.0,
        gluSum: (json['gluSum'] as num?)?.toDouble() ?? 0.0,
        n: (json['n'] as num?)?.toInt() ?? 0,
        nGlu: (json['nGlu'] as num?)?.toInt() ?? 0,
        ready: json['ready'] as bool? ?? false,
      );
}

/// Pure Dart execution engine for the LightGBM 400-tree glucose prediction model.
class GlucoseModelEngine {
  GlucoseModelEngine({
    required this.treeStart,
    required this.feat,
    required this.dleft,
    required this.left,
    required this.right,
    required this.thr,
  });

  final Uint32List treeStart;
  final Int8List feat;
  final Uint8List dleft;
  final Int16List left;
  final Int16List right;
  final Float32List thr;

  /// Predicts the glucose deviation delta (mg/dL) from Z-scored features.
  double predictDelta(List<double> z) {
    var sum = ClinicalConstants.bias;
    final numTrees = treeStart.length;

    for (var t = 0; t < numTrees; t++) {
      final start = treeStart[t];
      var i = start;
      while (true) {
        final f = feat[i];
        final threshold = thr[i];

        if (f < 0) {
          sum += threshold;
          break;
        }

        final val = (f < z.length) ? z[f] : 0.0;
        final goLeft = val.isNaN ? (dleft[i] == 1) : (val <= threshold);
        final offset = goLeft ? left[i] : right[i];
        i = start + offset;
      }
    }
    return sum;
  }

  /// Predicts absolute glucose (mg/dL) given Z-scored features and subject baseline.
  double predictGlucose(List<double> z, double baseline) {
    var g = baseline + predictDelta(z);
    if (g < ClinicalConstants.gluMin) g = ClinicalConstants.gluMin;
    if (g > ClinicalConstants.gluMax) g = ClinicalConstants.gluMax;
    return g;
  }

  /// Classifies glucose level into low (0), normal (1), high (2).
  static GlucoseClass classify(double glucoseMgDl) {
    if (glucoseMgDl < ClinicalConstants.ruleLow) return GlucoseClass.low;
    if (glucoseMgDl > ClinicalConstants.ruleHigh) return GlucoseClass.high;
    return GlucoseClass.normal;
  }

  /// Parses C source code of glucose_model.c into a high-performance typed [GlucoseModelEngine].
  factory GlucoseModelEngine.fromCSource(String cSourceCode) {
    final treeStarts = <int>[];
    final feats = <int>[];
    final dlefts = <int>[];
    final lefts = <int>[];
    final rights = <int>[];
    final thrs = <double>[];

    // 1. Parse gm_tree_start array
    final treeStartMatch = RegExp(r'const uint32_t gm_tree_start\[GM_N_TREES\]\s*=\s*\{([^\}]+)\}').firstMatch(cSourceCode);
    if (treeStartMatch != null) {
      final numbersText = treeStartMatch.group(1)!;
      final matches = RegExp(r'(\d+)u').allMatches(numbersText);
      for (final m in matches) {
        treeStarts.add(int.parse(m.group(1)!));
      }
    }

    // 2. Parse gm_nodes array entries: { feat, dleft, left, right, thr }
    final nodesBlockMatch = RegExp(r'const gm_node_t gm_nodes\[GM_N_NODES\]\s*=\s*\{([\s\S]*?)\};').firstMatch(cSourceCode);
    if (nodesBlockMatch != null) {
      final nodesText = nodesBlockMatch.group(1)!;
      // Match pattern like: { 20, 1, 1, 26, -0.375853208f} or { -1, 0, -1, -1, 1.82179071f}
      final nodeRegex = RegExp(r'\{\s*(-?\d+)\s*,\s*(\d+)\s*,\s*(-?\d+)\s*,\s*(-?\d+)\s*,\s*(-?[\d\.eE\+\-]+)f?\s*\}');
      for (final m in nodeRegex.allMatches(nodesText)) {
        feats.add(int.parse(m.group(1)!));
        dlefts.add(int.parse(m.group(2)!));
        lefts.add(int.parse(m.group(3)!));
        rights.add(int.parse(m.group(4)!));
        thrs.add(double.parse(m.group(5)!));
      }
    }

    return GlucoseModelEngine(
      treeStart: Uint32List.fromList(treeStarts),
      feat: Int8List.fromList(feats),
      dleft: Uint8List.fromList(dlefts),
      left: Int16List.fromList(lefts),
      right: Int16List.fromList(rights),
      thr: Float32List.fromList(thrs),
    );
  }
}
