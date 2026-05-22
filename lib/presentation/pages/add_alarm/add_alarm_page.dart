import 'package:alarm_app/domain/entities/alarm_entity.dart';
import 'package:alarm_app/presentation/blocs/alarm_list/alarm_list_bloc.dart';
import 'package:alarm_app/presentation/blocs/alarm_list/alarm_list_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:uuid/uuid.dart';

class AddAlarmPage extends StatefulWidget {
  const AddAlarmPage({super.key});

  @override
  State<AddAlarmPage> createState() => _AddAlarmPageState();
}

class _AddAlarmPageState extends State<AddAlarmPage> {
  List<int> selectedDays = [1, 2, 3, 4, 5];
  TimeOfDay selectedTime = TimeOfDay.now();
  final TextEditingController labelController = TextEditingController();
  final daysOfWeek = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  Future<void> pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: selectedTime,
    );

    if (picked != null) {
      setState(() {
        selectedTime = picked;
      });
    }
  }

  void saveAlarm() {
    final alarm = AlarmEntity(
      id: const Uuid().v4(),
      hour: selectedTime.hour,
      minute: selectedTime.minute,
      repeatDays: selectedDays,
      enabled: true,
      label: labelController.text,
    );

    context.read<AlarmListBloc>().add(AddAlarm(alarm));

    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Alarm')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 20,
                  ),
                  textStyle: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: pickTime,
                child: Text(selectedTime.format(context)),
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              'Repeat on',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: List.generate(7, (index) {
                final day = index + 1;
                return FilterChip(
                  label: Text(daysOfWeek[index]),
                  selected: selectedDays.contains(day),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        selectedDays.add(day);
                      } else {
                        selectedDays.remove(day);
                      }
                    });
                  },
                );
              }),
            ),
            const SizedBox(height: 30),
            TextField(
              controller: labelController,
              decoration: const InputDecoration(
                labelText: 'Alarm Label',
                border: OutlineInputBorder(),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
                onPressed: saveAlarm,
                child: const Text('SAVE ALARM', style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
