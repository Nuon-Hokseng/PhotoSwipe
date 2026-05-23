import 'dart:math' as math;

String formatStorageBytes(int bytes) {
  if (bytes <= 0) {
    return '0 MB';
  }

  const megabyte = 1024 * 1024;
  const gigabyte = 1024 * 1024 * 1024;

  if (bytes >= gigabyte) {
    return '${(bytes / gigabyte).toStringAsFixed(1)} GB';
  }

  final megabytes = bytes / megabyte;
  return megabytes < 10
      ? '${megabytes.toStringAsFixed(1)} MB'
      : '${math.max(1, megabytes.round())} MB';
}
