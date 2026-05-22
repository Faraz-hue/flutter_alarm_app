import 'package:alarm_app/domain/entities/alarm_entity.dart';
import 'package:alarm_app/presentation/blocs/alarm_list/alarm_list_bloc.dart';
import 'package:alarm_app/presentation/blocs/alarm_list/alarm_list_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AlarmTile extends StatelessWidget {
  final AlarmEntity alarm;

  const AlarmTile({super.key, required this.alarm});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(
          '${alarm.hour.toString().padLeft(2, '0')}:${alarm.minute.toString().padLeft(2, '0')}',
        ),
        subtitle: Text(alarm.label),
        trailing: Switch(
          value: alarm.enabled,
          onChanged: (value) {
            context.read<AlarmListBloc>().add(ToggleAlarm(alarm.id, value));
          },
        ),
      ),
    );
  }
}
