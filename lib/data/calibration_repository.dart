import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../clinical/glucose_model_engine.dart';
import 'readings_repository.dart';

class CalibrationRepository {
  CalibrationRepository(this._prefs, this._referenceRepository);

  final SharedPreferences _prefs;
  final ReferenceRepository _referenceRepository;

  static const _calibKey = 'glucose_calibration_state';

  /// Loads the persisted calibration state or returns a fresh uncalibrated state.
  GlucoseCalibration getCalibration() {
    final rawJson = _prefs.getString(_calibKey);
    if (rawJson == null || rawJson.isEmpty) {
      return GlucoseCalibration();
    }
    try {
      final map = jsonDecode(rawJson) as Map<String, dynamic>;
      return GlucoseCalibration.fromJson(map);
    } catch (_) {
      return GlucoseCalibration();
    }
  }

  /// Persists calibration state to [SharedPreferences].
  Future<void> saveCalibration(GlucoseCalibration calib) async {
    final rawJson = jsonEncode(calib.toJson());
    await _prefs.setString(_calibKey, rawJson);
  }

  /// Recalculates subject baseline using all recorded finger-stick reference readings.
  Future<GlucoseCalibration> updateBaselineFromReferences() async {
    final calib = getCalibration();
    final references = await _referenceRepository.watchAll().first;

    if (references.isNotEmpty) {
      var sum = 0.0;
      for (final ref in references) {
        sum += ref.referenceValueMgDl;
      }
      calib.baseline = sum / references.length;
      calib.nGlu = references.length;
      if (calib.n >= 10 && calib.nGlu >= 1) {
        calib.ready = true;
      }
    }
    await saveCalibration(calib);
    return calib;
  }
}
