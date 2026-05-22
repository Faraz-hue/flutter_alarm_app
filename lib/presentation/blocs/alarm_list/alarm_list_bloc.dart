import 'package:alarm_app/core/services/notification_service.dart';
import 'package:alarm_app/domain/repositories/alarm_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'alarm_list_event.dart';
import 'alarm_list_state.dart';

class AlarmListBloc extends Bloc<AlarmListEvent, AlarmListState> {
  final AlarmRepository repository;

  AlarmListBloc(this.repository) : super(AlarmListInitial()) {
    on<LoadAlarms>(_onLoadAlarms);

    on<AddAlarm>(_onAddAlarm);

    on<DeleteAlarm>(_onDeleteAlarm);

    on<ToggleAlarm>(_onToggleAlarm);
  }

  Future<void> _onLoadAlarms(
    LoadAlarms event,
    Emitter<AlarmListState> emit,
  ) async {
    final alarms = await repository.getAlarms();

    emit(AlarmListLoaded(alarms));
  }

  Future<void> _onAddAlarm(AddAlarm event, Emitter<AlarmListState> emit) async {
    await repository.addAlarm(event.alarm);

    // schedule system alarm
    await NotificationService.scheduleAlarm(
      id: event.alarm.id.hashCode,
      hour: event.alarm.hour,
      minute: event.alarm.minute,
      repeatDays: event.alarm.repeatDays,
    );

    add(LoadAlarms());
  }

  Future<void> _onDeleteAlarm(
    DeleteAlarm event,
    Emitter<AlarmListState> emit,
  ) async {
    await repository.deleteAlarm(event.id);

    add(LoadAlarms());
  }

  Future<void> _onToggleAlarm(
    ToggleAlarm event,
    Emitter<AlarmListState> emit,
  ) async {
    await repository.toggleAlarm(event.id, event.enabled);

    if (event.enabled) {
      final alarms = await repository.getAlarms();
      final alarm = alarms.firstWhere((a) => a.id == event.id);

      await NotificationService.scheduleAlarm(
        id: alarm.id.hashCode,
        hour: alarm.hour,
        minute: alarm.minute,
        repeatDays: alarm.repeatDays,
      );
    } else {
      await NotificationService.cancel(event.id.hashCode);
    }

    add(LoadAlarms());
  }
}
