import 'package:hive/hive.dart';

part 'alarm_model.g.dart';

@HiveType(typeId: 0)
class AlarmModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  int hour;

  @HiveField(2)
  int minute;

  @HiveField(3)
  List<int> repeatDays;

  @HiveField(4)
  bool enabled;

  @HiveField(5)
  String label;

  AlarmModel({
    required this.id,
    required this.hour,
    required this.minute,
    required this.repeatDays,
    required this.enabled,
    required this.label,
  });
}
