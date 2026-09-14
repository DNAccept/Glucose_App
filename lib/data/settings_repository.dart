import 'package:shared_preferences/shared_preferences.dart';

class SettingsRepository {
  SettingsRepository(this._prefs);

  final SharedPreferences _prefs;

  static const _alertsKey = 'alerts_enabled';
  static const _cloudKey = 'cloud_sync_enabled';
  static const _autoSyncKey = 'auto_sync_enabled';
  static const _autoSyncIntervalKey = 'auto_sync_interval_seconds';

  static const _lowThresholdKey = 'alert_low_threshold_mgdl';
  static const _highThresholdKey = 'alert_high_threshold_mgdl';
  static const _urgentLowThresholdKey = 'alert_urgent_low_threshold_mgdl';
  static const _snoozeDurationKey = 'alert_default_snooze_minutes';
  static const _snoozedUntilKey = 'alert_snoozed_until_ms';
  static const _authTokenKey = 'auth_session_token';

  bool get alertsEnabled => _prefs.getBool(_alertsKey) ?? true;
  Future<void> setAlertsEnabled(bool value) => _prefs.setBool(_alertsKey, value);

  bool get cloudSyncEnabled => _prefs.getBool(_cloudKey) ?? true;
  Future<void> setCloudSyncEnabled(bool value) => _prefs.setBool(_cloudKey, value);

  bool get autoSyncEnabled => _prefs.getBool(_autoSyncKey) ?? true;
  Future<void> setAutoSyncEnabled(bool value) => _prefs.setBool(_autoSyncKey, value);

  static const _serverUrlKey = 'custom_server_url';

  String? get serverUrl => _prefs.getString(_serverUrlKey);
  Future<void> setServerUrl(String value) => _prefs.setString(_serverUrlKey, value);

  String? get authToken => _prefs.getString(_authTokenKey);
  Future<void> setAuthToken(String? token) {
    if (token == null) return _prefs.remove(_authTokenKey);
    return _prefs.setString(_authTokenKey, token);
  }

  int get autoSyncIntervalSeconds => _prefs.getInt(_autoSyncIntervalKey) ?? 60;
  Future<void> setAutoSyncIntervalSeconds(int value) => _prefs.setInt(_autoSyncIntervalKey, value);

  // Alert Thresholds
  int get lowThresholdMgDl => _prefs.getInt(_lowThresholdKey) ?? 70;
  Future<void> setLowThresholdMgDl(int value) => _prefs.setInt(_lowThresholdKey, value);

  int get highThresholdMgDl => _prefs.getInt(_highThresholdKey) ?? 180;
  Future<void> setHighThresholdMgDl(int value) => _prefs.setInt(_highThresholdKey, value);

  int get urgentLowThresholdMgDl => _prefs.getInt(_urgentLowThresholdKey) ?? 55;
  Future<void> setUrgentLowThresholdMgDl(int value) => _prefs.setInt(_urgentLowThresholdKey, value);

  int get defaultSnoozeMinutes => _prefs.getInt(_snoozeDurationKey) ?? 30;
  Future<void> setDefaultSnoozeMinutes(int value) => _prefs.setInt(_snoozeDurationKey, value);

  DateTime? get snoozedUntil {
    final ms = _prefs.getInt(_snoozedUntilKey) ?? 0;
    return ms > 0 ? DateTime.fromMillisecondsSinceEpoch(ms) : null;
  }

  Future<void> setSnoozedUntil(DateTime? until) {
    if (until == null) {
      return _prefs.remove(_snoozedUntilKey);
    }
    return _prefs.setInt(_snoozedUntilKey, until.millisecondsSinceEpoch);
  }
}
