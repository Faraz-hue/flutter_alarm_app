import 'package:alarm_app/data/models/alarm_model.dart';
import 'package:alarm_app/data/models/log_model.dart';
import 'package:hive/hive.dart';

class AlarmLocalDatasource {
  final Box<AlarmModel> box = Hive.box<AlarmModel>('alarmsBox');
  final Box<LogModel> logBox = Hive.box<LogModel>('logsBox');

  List<AlarmModel> getAlarms() {
    return box.values.toList();
  }

  Future<void> addAlarm(AlarmModel alarm) async {
    await box.put(alarm.id, alarm);
  }

  Future<void> deleteAlarm(String id) async {
    await box.delete(id);
  }

  Future<void> toggleAlarm(String id, bool enabled) async {
    final alarm = box.get(id);

    if (alarm != null) {
      alarm.enabled = enabled;
      await alarm.save();
    }
  }

  List<LogModel> getLogs() {
    return logBox.values.toList();
  }

  Future<void> saveLog(LogModel log) async {
    await logBox.add(log);
  }
}
