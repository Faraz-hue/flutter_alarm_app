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
