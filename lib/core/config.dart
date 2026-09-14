import 'package:flutter/foundation.dart';

/// Centralized Production & Environment Configuration for the Glucose App.
class AppConfig {
  AppConfig._();

  /// Compile-time server URL passed via `--dart-define=SERVER_URL=https://your-hosted-domain.com`.
  static const String definedServerUrl = String.fromEnvironment(
    'SERVER_URL',
    defaultValue: '',
  );

  /// Production mode detection.
  static bool get isProduction => kReleaseMode || definedServerUrl.isNotEmpty;

  /// Default production server endpoint or fallback local host.
  static String get defaultServerUrl {
    if (definedServerUrl.isNotEmpty) {
      return definedServerUrl.trim();
    }
    return 'http://127.0.0.1:8080';
  }

  /// List of candidate fallback server endpoints for automatic network resolution.
  static List<String> getCandidateUrls(String? customUrl) {
    final candidates = <String>[];

    if (customUrl != null && customUrl.trim().isNotEmpty) {
      candidates.add(customUrl.trim());
    }

    if (definedServerUrl.isNotEmpty && !candidates.contains(definedServerUrl)) {
      candidates.add(definedServerUrl.trim());
    }

    for (final fallback in [
      'http://127.0.0.1:8080',
      'http://192.168.137.118:8080',
      'http://192.168.56.1:8080',
      'http://10.12.64.7:8080',
      'http://10.0.2.2:8080',
      'http://localhost:8080',
    ]) {
      if (!candidates.contains(fallback)) {
        candidates.add(fallback);
      }
    }

    return candidates;
  }
}
