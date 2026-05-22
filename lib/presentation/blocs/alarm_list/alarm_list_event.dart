import '../../../domain/entities/alarm_entity.dart';

abstract class AlarmListEvent {}

class LoadAlarms extends AlarmListEvent {}

class AddAlarm extends AlarmListEvent {
  final AlarmEntity alarm;

  AddAlarm(this.alarm);
}

class DeleteAlarm extends AlarmListEvent {
  final String id;

  DeleteAlarm(this.id);
}

class ToggleAlarm extends AlarmListEvent {
  final String id;
  final bool enabled;

  ToggleAlarm(this.id, this.enabled);
}
