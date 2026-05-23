class AlarmEntity {
  final String id;
  final int hour;
  final int minute;
  final List<int> repeatDays;
  final bool enabled;
  final String label;
  final String difficulty; // 'EASY' | 'MEDIUM' | 'HARD'
  final int mathQuestions; // 1 – 5

  AlarmEntity({
    required this.id,
    required this.hour,
    required this.minute,
    required this.repeatDays,
    required this.enabled,
    required this.label,
    this.difficulty = 'MEDIUM',
    this.mathQuestions = 2,
  });
}
