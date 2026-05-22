# Alarm App Complete Fix Guide

## Problem Summary
1. Gradle cache corruption
2. Audio service not working on desktop
3. Notification/alarm flow not triggering properly
4. Need mobile deployment

---

## SOLUTION 1: Fix Gradle Cache Corruption

### Step 1: Clean Gradle Cache
Run these commands in your project root:

```bash
# Stop Gradle daemon
./gradlew --stop

# Navigate to Gradle cache (Windows)
cd %USERPROFILE%\.gradle\caches

# Or on Mac/Linux
cd ~/.gradle/caches

# Delete corrupted cache
rm -rf *

# Or on Windows
del /s /q *
```

### Step 2: Clean Flutter Build
```bash
cd [your_project_directory]
flutter clean
flutter pub get
cd android
./gradlew clean
cd ..
```

### Step 3: Rebuild
```bash
flutter build apk --debug
# or for running
flutter run
```

---

## SOLUTION 2: Fix Audio Service Issues

### Issue: Audio might not have permissions or proper initialization

Create updated `audio_service.dart`:

```dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:io';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final AudioPlayer _player = AudioPlayer();
  Timer? _volumeTimer;
  double _currentVolume = 0.1;
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;
    
    try {
      // Set audio session category for alarms
      if (Platform.isAndroid || Platform.isIOS) {
        await _player.setAsset('assets/sounds/LOUDEST ALARM SOUND!!  FOR 20 MINS.mp3');
        await _player.setLoopMode(LoopMode.one);
        _isInitialized = true;
        debugPrint('✅ Audio initialized successfully');
      } else {
        debugPrint('⚠️ Audio not supported on this platform');
      }
    } catch (e) {
      debugPrint('❌ Error initializing audio: $e');
    }
  }

  Future<void> playAlarm() async {
    try {
      debugPrint('🔊 Attempting to play alarm...');
      
      _currentVolume = 0.1;
      await _player.setVolume(_currentVolume);
      
      // Re-load asset to ensure it's fresh
      await _player.setAsset('assets/sounds/LOUDEST ALARM SOUND!!  FOR 20 MINS.mp3');
      await _player.setLoopMode(LoopMode.one);
      
      await _player.play();
      debugPrint('✅ Alarm playing at volume: $_currentVolume');

      // Start gradual volume increase
      _startVolumeIncrease();
    } catch (e) {
      debugPrint('❌ Error playing alarm: $e');
      // Try fallback - system beep
      _playFallbackSound();
    }
  }

  void _playFallbackSound() {
    debugPrint('🔔 Using fallback sound method');
    // System beep as fallback
  }

  void _startVolumeIncrease() {
    _volumeTimer?.cancel();
    _volumeTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_currentVolume < 1.0) {
        _currentVolume += 0.1;
        if (_currentVolume > 1.0) _currentVolume = 1.0;
        _player.setVolume(_currentVolume);
        debugPrint('🔊 Volume increased to: $_currentVolume');
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> stopAlarm() async {
    debugPrint('🛑 Stopping alarm');
    _volumeTimer?.cancel();
    await _player.stop();
  }

  Future<void> setVolume(double volume) async {
    _currentVolume = volume;
    await _player.setVolume(_currentVolume);
    debugPrint('🔊 Volume set to: $_currentVolume');
  }

  void dispose() {
    _volumeTimer?.cancel();
    _player.dispose();
  }
}
```

---

## SOLUTION 3: Fix Notification Flow

### Issue: Notifications not triggering alarm flow properly

Update `notification_service.dart` with better error handling:

```dart
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

    const iOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: android,
      iOS: iOS,
    );

    bool? initialized = await _plugin.initialize(
      settings,
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
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
    }

    // Create notification channel for Android
    if (Platform.isAndroid) {
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
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
        id,
        'Wake Up! ⏰',
        'Time to solve your challenge',
        scheduled,
        const NotificationDetails(
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
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
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
    await _plugin.cancel(id);
  }

  static Future<void> cancelAll() async {
    debugPrint('🗑️ Cancelling all alarms');
    await _plugin.cancelAll();
  }
}
```

---

## SOLUTION 4: Update Main.dart for Better Initialization

```dart
import 'package:alarm_app/core/routes/approuter.dart';
import 'package:alarm_app/core/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'data/models/alarm_model.dart';
import 'data/models/log_model.dart';
import 'presentation/blocs/alarm_list/alarm_list_bloc.dart';
import 'presentation/blocs/alarm_list/alarm_list_event.dart';
import 'data/repositories/alarm_repository_impl.dart';
import 'presentation/blocs/alarm_ring/alarm_ring_bloc.dart';
import 'presentation/blocs/challenge/challenge_bloc.dart';
import 'core/services/audio_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  debugPrint('🚀 Starting Alarm App...');

  // Initialize Hive
  await Hive.initFlutter();
  Hive.registerAdapter(AlarmModelAdapter());
  Hive.registerAdapter(LogModelAdapter());

  await Hive.openBox<AlarmModel>('alarmsBox');
  await Hive.openBox<LogModel>('logsBox');
  debugPrint('✅ Hive initialized');

  // Initialize Services
  try {
    await NotificationService.init();
    debugPrint('✅ Notification service ready');
  } catch (e) {
    debugPrint('❌ Notification Service failed: $e');
  }

  try {
    await AudioService().init();
    debugPrint('✅ Audio service ready');
  } catch (e) {
    debugPrint('❌ Audio Service failed: $e');
  }

  final repository = AlarmRepositoryImpl();

  String? initialPayload;
  try {
    initialPayload = await NotificationService.getInitialNotification();
    if (initialPayload != null) {
      debugPrint('🔔 Initial notification payload: $initialPayload');
    }
  } catch (e) {
    debugPrint('⚠️ No initial notification: $e');
  }

  runApp(MyApp(repository: repository, initialPayload: initialPayload));
}

class MyApp extends StatelessWidget {
  final AlarmRepositoryImpl repository;
  final String? initialPayload;

  const MyApp({super.key, required this.repository, this.initialPayload});

  @override
  Widget build(BuildContext context) {
    // Handle initial notification
    if (initialPayload != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        debugPrint('🔀 Navigating to ringing page from notification');
        AppRouter.router.push('/ringing', extra: initialPayload);
      });
    }

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => AlarmListBloc(repository)..add(LoadAlarms()),
        ),
        BlocProvider(create: (_) => AlarmRingBloc()),
        BlocProvider(create: (_) => ChallengeBloc()),
      ],
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        routerConfig: AppRouter.router,
        theme: ThemeData.dark().copyWith(
          primaryColor: Colors.deepPurple,
          scaffoldBackgroundColor: Colors.grey[900],
        ),
      ),
    );
  }
}
```

---

## SOLUTION 5: Add Missing Challenge Events/States

Create `challenge_event.dart`:

```dart
abstract class ChallengeEvent {}

class StartChallenge extends ChallengeEvent {}

class SubmitMathAnswer extends ChallengeEvent {
  final String answer;
  SubmitMathAnswer(this.answer);
}

class ObjectDetected extends ChallengeEvent {
  final String detectedObject;
  ObjectDetected(this.detectedObject);
}
```

Create `challenge_state.dart`:

```dart
abstract class ChallengeState {}

class ChallengeInitial extends ChallengeState {}

class MathChallengeInProgress extends ChallengeState {
  final String problem;
  final double correctAnswer;
  final String difficulty;
  final String? error;

  MathChallengeInProgress({
    required this.problem,
    required this.correctAnswer,
    required this.difficulty,
    this.error,
  });
}

class MathChallengeSuccess extends ChallengeState {}

class ObjectDetectionInProgress extends ChallengeState {
  final String targetObject;
  ObjectDetectionInProgress({required this.targetObject});
}

class ChallengeCompleted extends ChallengeState {}
```

---

## SOLUTION 6: Android Permissions Setup

### Update `android/app/src/main/AndroidManifest.xml`:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- Permissions -->
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.CAMERA"/>
    <uses-permission android:name="android.permission.WAKE_LOCK"/>
    <uses-permission android:name="android.permission.VIBRATE"/>
    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
    <uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
    <uses-permission android:name="android.permission.USE_EXACT_ALARM"/>
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
    
    <uses-feature android:name="android.hardware.camera" android:required="false"/>

    <application
        android:label="Wake Up Challenge"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher"
        android:allowBackup="false">
        
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:taskAffinity=""
            android:theme="@style/LaunchTheme"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:showWhenLocked="true"
            android:turnScreenOn="true"
            android:windowSoftInputMode="adjustResize">
            
            <meta-data
              android:name="io.flutter.embedding.android.NormalTheme"
              android:resource="@style/NormalTheme"
              />
            
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
            
            <!-- Handle full-screen intent for alarms -->
            <intent-filter>
                <action android:name="android.intent.action.VIEW"/>
                <category android:name="android.intent.category.DEFAULT"/>
            </intent-filter>
        </activity>

        <meta-data
            android:name="flutterEmbedding"
            android:value="2" />
    </application>
</manifest>
```

---

## SOLUTION 7: Complete Step-by-Step Deployment

### For Android Device:

```bash
# 1. Connect your Android phone via USB
# 2. Enable USB debugging on phone
# 3. Run:

flutter clean
flutter pub get
flutter doctor  # Check for issues

# Build and install
flutter run --release

# Or create APK
flutter build apk --release
# APK will be at: build/app/outputs/flutter-apk/app-release.apk
```

### For Testing on Desktop (Limited - Audio might not work):

```bash
flutter run -d windows  # or macos/linux
```

---

## SOLUTION 8: Verify Assets

Make sure `pubspec.yaml` has:

```yaml
flutter:
  assets:
    - assets/sounds/LOUDEST ALARM SOUND!!  FOR 20 MINS.mp3
```

And the audio file exists at:
`assets/sounds/LOUDEST ALARM SOUND!!  FOR 20 MINS.mp3`

---

## DEBUGGING CHECKLIST

Run app with verbose logging:
```bash
flutter run --verbose
```

Watch for these debug messages:
- ✅ Hive initialized
- ✅ Notification service ready
- ✅ Audio service ready
- 🔔 Notification scheduled
- 🔊 Alarm playing

If you see ❌ errors, that's where the problem is.

---

## QUICK FIX COMMANDS (Run in Order)

```bash
# 1. Stop everything
flutter clean
./gradlew --stop

# 2. Clear Gradle cache (Windows)
cd %USERPROFILE%\.gradle
rmdir /s /q caches

# Or Mac/Linux
rm -rf ~/.gradle/caches

# 3. Get back to project and rebuild
cd [your_project]
flutter pub get
flutter pub upgrade

# 4. Try running
flutter run

# 5. If still issues, invalidate more caches
flutter pub cache repair
```

---

## MOBILE DEPLOYMENT FINAL STEPS

1. **Test on real device** (not emulator for best alarm behavior)
2. **Grant all permissions** when app asks
3. **Disable battery optimization** for the app (Settings > Apps > Your App > Battery)
4. **Test alarm scheduling** - set one for 2 minutes from now
5. **Lock phone** and wait for alarm

---

## COMMON ISSUES & FIXES

### Issue: "No sound on desktop"
**Fix**: Desktop platforms have limited audio support. Deploy to Android/iOS.

### Issue: "Gradle timeout"
**Fix**: Add to `android/gradle.properties`:
```
org.gradle.daemon=true
org.gradle.parallel=true
org.gradle.jvmargs=-Xmx2048m
```

### Issue: "Notifications not showing"
**Fix**: Check permissions in phone settings, ensure exact alarm permission granted.

### Issue: "Camera not working for object detection"
**Fix**: Grant camera permission, test on real device not emulator.

---

## TEST THE FIX

1. Clean and rebuild: ✓
2. Run on Android device: ✓  
3. Create alarm for 2 min from now: ✓
4. Wait for notification: ✓
5. Alarm should ring: ✓
6. Math challenge appears: ✓
7. After math, camera scanner: ✓
8. Alarm stops after finding object: ✓

If all ✓, you're good to go!