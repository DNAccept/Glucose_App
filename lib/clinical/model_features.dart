import 'dart:math' as math;

/// Schema and metadata for the 22 input features expected by the LightGBM model.
class ModelFeatures {
  ModelFeatures._();

  static const int featureCount = 22;

  static const List<String> featureNames = [
    'ppg_pulse',
    'ppg_skew_sqi',
    'ppg_rise_t',
    'ppg_pw50',
    'ppg_refl_idx',
    'ppg_notch_rel',
    'ppg_apg_ba',
    'ppg_apg_aging',
    'ppg_beat_amp_cv',
    'ppg_harm_ratio',
    'ppg_spec_entropy',
    'ppg_hrv_sdnn',
    'ppg_hrv_rmssd',
    'ppg_hrv_pnn50',
    'ppg_hrv_cv',
    'ppg_hrv_lf',
    'ppg_hrv_hf',
    'ppg_hrv_lfhf',
    'ppg_hrv_nbeats',
    'ctx_temp_mean',
    'ctx_temp_std',
    'ctx_temp_slope',
  ];

  /// Creates a default baseline raw feature vector filled with zeros.
  static List<double> createDefaultVector() {
    return List<double>.filled(featureCount, 0.0);
  }

  /// Sanitizes a feature vector by replacing NaN or infinite values with 0.0.
  static List<double> sanitize(List<double> raw) {
    final result = List<double>.filled(featureCount, 0.0);
    for (var i = 0; i < featureCount; i++) {
      if (i < raw.length) {
        final val = raw[i];
        result[i] = (val.isNaN || val.isInfinite) ? 0.0 : val;
      }
    }
    return result;
  }
}
