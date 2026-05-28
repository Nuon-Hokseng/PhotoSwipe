import 'dart:math';

String formatBytes(int bytes, [int decimals = 2]) {
  if (bytes <= 0) return '0 B';
  const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
  final i = (log(bytes) / log(1024)).floor();
  final num = bytes / pow(1024, i);
  return '${num.toStringAsFixed(decimals)} ${suffixes[i]}';
}
