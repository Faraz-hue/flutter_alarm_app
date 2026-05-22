class LogEntity {
  final String alarmId;
  final DateTime timestamp;
  final bool success;
  final int timeTakenSeconds;

  LogEntity({
    required this.alarmId,
    required this.timestamp,
    required this.success,
    required this.timeTakenSeconds,
  });
}
