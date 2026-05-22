import 'package:alarm_app/domain/entities/log_entity.dart';

import '../entities/alarm_entity.dart';

abstract class AlarmRepository {
  Future<List<AlarmEntity>> getAlarms();

  Future<void> addAlarm(AlarmEntity alarm);

  Future<void> deleteAlarm(String id);

  Future<void> toggleAlarm(String id, bool enabled);

  Future<List<LogEntity>> getLogs();

  Future<void> saveLog(LogEntity log);
}
