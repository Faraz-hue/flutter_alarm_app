import 'package:alarm_app/data/datasources/local/alarm_local_datasource.dart';
import 'package:alarm_app/data/models/alarm_model.dart';
import 'package:alarm_app/data/models/log_model.dart';
import 'package:alarm_app/domain/entities/alarm_entity.dart';
import 'package:alarm_app/domain/entities/log_entity.dart';
import 'package:alarm_app/domain/repositories/alarm_repository.dart';

class AlarmRepositoryImpl implements AlarmRepository {
  final AlarmLocalDatasource datasource = AlarmLocalDatasource();

  @override
  Future<void> addAlarm(AlarmEntity alarm) async {
    final model = AlarmModel(
      id: alarm.id,
      hour: alarm.hour,
      minute: alarm.minute,
      repeatDays: alarm.repeatDays,
      enabled: alarm.enabled,
      label: alarm.label,
    );

    await datasource.addAlarm(model);
  }

  @override
  Future<void> deleteAlarm(String id) async {
    await datasource.deleteAlarm(id);
  }

  @override
  Future<List<AlarmEntity>> getAlarms() async {
    final alarms = datasource.getAlarms();

    return alarms
        .map(
          (e) => AlarmEntity(
            id: e.id,
            hour: e.hour,
            minute: e.minute,
            repeatDays: e.repeatDays,
            enabled: e.enabled,
            label: e.label,
          ),
        )
        .toList();
  }

  @override
  Future<void> toggleAlarm(String id, bool enabled) async {
    await datasource.toggleAlarm(id, enabled);
  }

  @override
  Future<List<LogEntity>> getLogs() async {
    final logs = datasource.getLogs();
    return logs
        .map(
          (e) => LogEntity(
            alarmId: e.alarmId,
            timestamp: e.timestamp,
            success: e.success,
            timeTakenSeconds: e.timeTakenSeconds,
          ),
        )
        .toList();
  }

  @override
  Future<void> saveLog(LogEntity log) async {
    final model = LogModel(
      alarmId: log.alarmId,
      timestamp: log.timestamp,
      success: log.success,
      timeTakenSeconds: log.timeTakenSeconds,
    );
    await datasource.saveLog(model);
  }
}
