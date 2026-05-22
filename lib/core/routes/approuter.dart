import 'package:alarm_app/presentation/pages/add_alarm/add_alarm_page.dart';
import 'package:alarm_app/presentation/pages/challenge/math_challenge_page.dart';
import 'package:alarm_app/presentation/pages/home/home_page.dart';
import 'package:alarm_app/presentation/pages/ringing/ringing_page.dart';
import 'package:alarm_app/presentation/pages/scanner/scanner_page.dart';
import 'package:alarm_app/presentation/pages/statistics/statistics_page.dart';
import 'package:go_router/go_router.dart';

class AppRouter {
  static final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (context, state) => const HomePage()),
      GoRoute(
        path: '/addAlarm',
        builder: (context, state) => const AddAlarmPage(),
      ),
      GoRoute(
        path: '/ringing',
        builder: (context, state) {
          final alarmId = state.extra as String?;
          return RingingPage(alarmId: alarmId ?? '');
        },
      ),
      GoRoute(
        path: '/math-challenge',
        builder: (context, state) {
          final alarmId = state.extra as String?;
          return MathChallengePage(alarmId: alarmId ?? '');
        },
      ),
      GoRoute(
        path: '/scanner',
        builder: (context, state) {
          final alarmId = state.extra as String?;
          return ScannerPage(alarmId: alarmId ?? '');
        },
      ),
      GoRoute(
        path: '/statistics',
        builder: (context, state) => const StatisticsPage(),
      ),
    ],
  );
}
