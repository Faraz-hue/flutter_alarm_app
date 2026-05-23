import 'package:alarm_app/domain/entities/alarm_entity.dart';
import 'package:alarm_app/presentation/blocs/alarm_list/alarm_list_bloc.dart';
import 'package:alarm_app/presentation/blocs/alarm_list/alarm_list_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AlarmTile extends StatelessWidget {
  final AlarmEntity alarm;

  const AlarmTile({super.key, required this.alarm});

  String _repeatDaysLabel(List<int> days) {
    if (days.isEmpty) return 'Once';
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    if (days.length == 7) return 'Every day';
    if (days.length == 5 && !days.contains(6) && !days.contains(7)) {
      return 'Weekdays';
    }
    return days.map((d) => names[d - 1]).join(', ');
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Alarm'),
        content: Text(
          'Delete alarm at ${alarm.hour.toString().padLeft(2, '0')}:${alarm.minute.toString().padLeft(2, '0')}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<AlarmListBloc>().add(DeleteAlarm(alarm.id));
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(alarm.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: Colors.red.shade800,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
      ),
      confirmDismiss: (_) async {
        bool confirmed = false;
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete Alarm'),
            content: Text(
              'Delete alarm at ${alarm.hour.toString().padLeft(2, '0')}:${alarm.minute.toString().padLeft(2, '0')}?',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  confirmed = false;
                  Navigator.of(ctx).pop();
                },
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  confirmed = true;
                  Navigator.of(ctx).pop();
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
        return confirmed;
      },
      onDismissed: (_) {
        context.read<AlarmListBloc>().add(DeleteAlarm(alarm.id));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Alarm ${alarm.hour.toString().padLeft(2, '0')}:${alarm.minute.toString().padLeft(2, '0')} deleted',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onLongPress: () => _confirmDelete(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${alarm.hour.toString().padLeft(2, '0')}:${alarm.minute.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: alarm.enabled ? Colors.white : Colors.white38,
                        ),
                      ),
                      const SizedBox(height: 2),
                      if (alarm.label.isNotEmpty)
                        Text(
                          alarm.label,
                          style: TextStyle(
                            fontSize: 13,
                            color: alarm.enabled
                                ? Colors.white70
                                : Colors.white30,
                          ),
                        ),
                      Text(
                        _repeatDaysLabel(alarm.repeatDays),
                        style: TextStyle(
                          fontSize: 12,
                          color: alarm.enabled
                              ? Colors.white54
                              : Colors.white24,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    Switch(
                      value: alarm.enabled,
                      activeThumbColor: Colors.deepPurple,
                      onChanged: (value) {
                        context.read<AlarmListBloc>().add(
                          ToggleAlarm(alarm.id, value),
                        );
                      },
                    ),
                    GestureDetector(
                      onTap: () => _confirmDelete(context),
                      child: const Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
