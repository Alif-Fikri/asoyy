const int authFreeAttempts = 4;

const List<Duration> _lockoutLadder = [
  Duration(seconds: 30),
  Duration(minutes: 1),
  Duration(minutes: 5),
  Duration(minutes: 15),
  Duration(minutes: 30),
];

Duration lockoutForFailures(int failures) {
  final over = failures - authFreeAttempts;
  if (over <= 0) return Duration.zero;
  final index = over - 1;
  return index >= _lockoutLadder.length
      ? _lockoutLadder.last
      : _lockoutLadder[index];
}

int attemptsLeftBeforeLockout(int failures) {
  final left = authFreeAttempts - failures;
  return left < 0 ? 0 : left;
}

String formatLockout(Duration remaining) {
  final total = remaining.inSeconds < 0 ? 0 : remaining.inSeconds;
  final minutes = total ~/ 60;
  final seconds = total % 60;
  if (minutes == 0) return '${seconds}s';
  if (seconds == 0) return '${minutes}m';
  return '${minutes}m ${seconds}s';
}
