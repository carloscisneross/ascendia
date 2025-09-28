String twoDigits(int n) => n.toString().padLeft(2, '0');

Map<String, String> formatDuration(Duration duration) {
  final hours = twoDigits(duration.inHours.remainder(24));
  final minutes = twoDigits(duration.inMinutes.remainder(60));
  final seconds = twoDigits(duration.inSeconds.remainder(60));
  return {
    'h': hours,
    'm': minutes,
    's': seconds,
  };
}
