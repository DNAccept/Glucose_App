import 'package:shared_preferences/shared_preferences.dart';

class SettingsRepository {
  SettingsRepository(this._prefs);

  final SharedPreferences _prefs;

  static const _alertsKey = 'alerts_enabled';
  static const _cloudKey = 'cloud_sync_enabled';

  bool get alertsEnabled => _prefs.getBool(_alertsKey) ?? true;
  Future<void> setAlertsEnabled(bool value) => _prefs.setBool(_alertsKey, value);

  /// UI-only stub, as in the mockup — no cloud backend is implemented.
  bool get cloudSyncEnabled => _prefs.getBool(_cloudKey) ?? false;
  Future<void> setCloudSyncEnabled(bool value) => _prefs.setBool(_cloudKey, value);
}
