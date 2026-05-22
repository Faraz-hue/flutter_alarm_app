import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:alarm_app/core/routes/approuter.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    debugPrint('🔔 Initializing Notification Service...');

    tz.initializeTimeZones();

    String timeZoneName = 'Asia/Karachi';

    if (!Platform.isWindows && !Platform.isLinux) {
      try {
        timeZoneName = await FlutterTimezone.getLocalTimezone();
        debugPrint('✅ Timezone: $timeZoneName');
      } catch (e) {
        debugPrint('⚠️ Timezone error: $e');
      }
    }

    try {
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (e) {
      debugPrint('⚠️ Error setting timezone: $e');
      tz.setLocalLocation(tz.getLocation('Asia/Karachi'));
    }

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');

    final settings = InitializationSettings(
      android: android,
      iOS: kIsWeb || !Platform.isIOS
          ? null
          : const DarwinInitializationSettings(
              requestAlertPermission: true,
              requestBadgePermission: true,
              requestSoundPermission: true,
            ),
      windows: kIsWeb || !Platform.isWindows
          ? null
          : const WindowsInitializationSettings(
              appName: 'Wake Up Challenge',
              appUserModelId: 'com.example.alarm_app',
              guid: 'd49b0314-ee7a-4aa8-bdf2-b714fb8d6952',
            ),
    );

    bool? initialized = await _plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: (response) {
        debugPrint('🔔 Notification tapped! Payload: ${response.payload}');
        if (response.payload != null) {
          AppRouter.router.push('/ringing', extra: response.payload);
        }
      },
    );

    debugPrint('✅ Notifications initialized: $initialized');

    // Request permissions on iOS
    if (Platform.isIOS) {
      await _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }

    // Create notification channel for Android
    if (Platform.isAndroid) {
      await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(
            const AndroidNotificationChannel(
              'alarm_channel_id',
              'Alarms',
              description: 'Wake up alarms',
              importance: Importance.max,
              playSound: true,
              enableVibration: true,
              showBadge: true,
            ),
          );
      debugPrint('✅ Android notification channel created');
    }
  }

  static Future<String?> getInitialNotification() async {
    try {
      if (Platform.isLinux) return null;

      final details = await _plugin.getNotificationAppLaunchDetails();
      if (details != null && details.didNotificationLaunchApp) {
        debugPrint('🚀 App launched from notification');
        return details.notificationResponse?.payload;
      }
    } catch (e) {
      debugPrint('⚠️ Error getting initial notification: $e');
    }
    return null;
  }

  static Future<void> scheduleAlarm({
    required int id,
    required int hour,
    required int minute,
    List<int>? repeatDays,
  }) async {
    debugPrint('⏰ Scheduling alarm: $id at $hour:$minute');

    final now = tz.TZDateTime.now(tz.local);

    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    debugPrint('📅 Scheduled for: $scheduled');

    try {
      await _plugin.zonedSchedule(
        id: id,
        title: 'Wake Up! ⏰',
        body: 'Time to solve your challenge',
        scheduledDate: scheduled,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'alarm_channel_id',
            'Alarms',
            channelDescription: 'Wake up alarms',
            importance: Importance.max,
            priority: Priority.high,
            fullScreenIntent: true,
            audioAttributesUsage: AudioAttributesUsage.alarm,
            category: AndroidNotificationCategory.alarm,
            playSound: true,
            sound: RawResourceAndroidNotificationSound('alarm_sound'),
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            sound: 'alarm_sound.caf',
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: (repeatDays != null && repeatDays.isNotEmpty)
            ? DateTimeComponents.time
            : null,
        payload: id.toString(),
      );

      debugPrint('✅ Alarm scheduled successfully');
    } catch (e) {
      debugPrint('❌ Error scheduling alarm: $e');
    }
  }

  static Future<void> cancel(int id) async {
    debugPrint('🗑️ Cancelling alarm: $id');
    await _plugin.cancel(id: id);
  }

  static Future<void> cancelAll() async {
    debugPrint('🗑️ Cancelling all alarms');
    await _plugin.cancelAll();
  }
}
