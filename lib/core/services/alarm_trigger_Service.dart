// ignore_for_file: file_names

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:alarm_app/core/routes/approuter.dart';
import 'package:alarm_app/data/repositories/alarm_repository_impl.dart';

/// Polls every 30 seconds and checks if any enabled alarm matches the current
/// time. When a match is found it navigates to /ringing and plays audio via
/// the global AudioService singleton.
class AlarmTriggerService {
  static AlarmTriggerService? _instance;
  static AlarmTriggerService get instance =>
      _instance ??= AlarmTriggerService._();

  AlarmTriggerService._();

  Timer? _timer;
  AlarmRepositoryImpl? _repository;

  // Track which alarm IDs have already been triggered this minute so we don't
  // fire twice for the same minute.
  final Set<String> _firedThisMinute = {};
  int _lastCheckedMinute = -1;

  void start(AlarmRepositoryImpl repository) {
    _repository = repository;
    _timer?.cancel();
    // Check every 20 seconds for reliability
    _timer = Timer.periodic(const Duration(seconds: 20), (_) => _check());
    debugPrint('⏱️ AlarmTriggerService started');
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _check() async {
    if (_repository == null) return;

    final now = DateTime.now();
    final currentMinute = now.hour * 60 + now.minute;

    // Clear the fired set when the minute rolls over
    if (currentMinute != _lastCheckedMinute) {
      _firedThisMinute.clear();
      _lastCheckedMinute = currentMinute;
    }

    final alarms = await _repository!.getAlarms();

    for (final alarm in alarms) {
      if (!alarm.enabled) continue;
      if (_firedThisMinute.contains(alarm.id)) continue;

      // Check time match
      if (alarm.hour == now.hour && alarm.minute == now.minute) {
        // Check day of week (DateTime weekday: 1=Mon … 7=Sun)
        if (alarm.repeatDays.isEmpty ||
            alarm.repeatDays.contains(now.weekday)) {
          _firedThisMinute.add(alarm.id);
          debugPrint(
            '🔔 AlarmTriggerService: firing alarm ${alarm.id} at ${now.hour}:${now.minute}',
          );
          _fireAlarm(alarm.id);
        }
      }
    }
  }

  void _fireAlarm(String alarmId) {
    // Navigate using the global GoRouter — works whether app is in foreground
    // or was re-opened from a notification tap.
    try {
      AppRouter.router.push('/ringing', extra: alarmId);
    } catch (e) {
      debugPrint('❌ AlarmTriggerService navigation error: $e');
    }
  }
}
