import 'package:hive/hive.dart';

part 'log_model.g.dart';

@HiveType(typeId: 1)
class LogModel extends HiveObject {
  @HiveField(0)
  final String alarmId;

  @HiveField(1)
  final DateTime timestamp;

  @HiveField(2)
  final bool success;

  @HiveField(3)
  final int timeTakenSeconds;

  LogModel({
    required this.alarmId,
    required this.timestamp,
    required this.success,
    required this.timeTakenSeconds,
  });
}
