String formatTimeInMinutes(double minutes) {
  if (minutes.isNaN || minutes.isInfinite) {
    return '0.0 min';
  }
  return '${minutes.toStringAsFixed(1)} min';
}

String formatTimestamp(DateTime timestamp) {
  return timestamp.toIso8601String().substring(11, 19);
}