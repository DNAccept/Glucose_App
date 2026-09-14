import 'dart:math';

final _random = Random.secure();

/// Generates a standard RFC-4122 v4 UUID string.
String generateUuid() {
  final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
  // Set version to 4 (0100)
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  // Set variant to 10xxxxxx
  bytes[8] = (bytes[8] & 0x3f) | 0x80;

  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20, 32)}';
}
