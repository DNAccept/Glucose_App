import 'package:flutter_test/flutter_test.dart';
import 'package:glucose_monitor/core/config.dart';

void main() {
  test('AppConfig provides default server URL and candidate fallback list', () {
    expect(AppConfig.defaultServerUrl, isNotEmpty);
    expect(AppConfig.getCandidateUrls(null).length, greaterThanOrEqualTo(6));
  });

  test('AppConfig resolves custom URL in candidate list', () {
    final customUrl = 'https://api.mycgmdomain.com';
    final candidates = AppConfig.getCandidateUrls(customUrl);

    expect(candidates.first, customUrl);
    expect(candidates, contains('http://127.0.0.1:8080'));
    expect(candidates, contains('http://10.0.2.2:8080'));
  });
}
