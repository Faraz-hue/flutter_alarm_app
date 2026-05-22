class AlarmEntity {
  final String id;
  final int hour;
  final int minute;
  final List<int> repeatDays;
  final bool enabled;
  final String label;

  AlarmEntity({
    required this.id,
    required this.hour,
    required this.minute,
    required this.repeatDays,
    required this.enabled,
    required this.label,
  });
}
