// ignore: file_names
import 'package:alarm_app/domain/entities/alarm_entity.dart';

abstract class AlarmListState {}

class AlarmListInitial extends AlarmListState {}

class AlarmListLoaded extends AlarmListState {
  final List<AlarmEntity> alarms;

  AlarmListLoaded(this.alarms);
}
