import 'package:alarm_app/presentation/blocs/alarm_list/alarm_list_bloc.dart';
import 'package:alarm_app/presentation/blocs/alarm_ring/alarm_ring_bloc.dart';
import 'package:alarm_app/presentation/blocs/alarm_ring/alarm_ring_event.dart';
import 'package:alarm_app/presentation/blocs/alarm_ring/alarm_ring_state.dart';
import 'package:alarm_app/presentation/blocs/challenge/challenge_bloc.dart';
import 'package:alarm_app/presentation/blocs/challenge/challenge_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class RingingPage extends StatefulWidget {
  final String alarmId;
  const RingingPage({super.key, required this.alarmId});

  @override
  State<RingingPage> createState() => _RingingPageState();
}

class _RingingPageState extends State<RingingPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;
  late Animation<double> _scale;

  String _difficulty = 'MEDIUM';
  int _mathQuestions = 2;

  @override
  void initState() {
    super.initState();

    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);

    _scale = Tween<double>(
      begin: 0.88,
      end: 1.12,
    ).animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut));

    // Start audio
    context.read<AlarmRingBloc>().add(StartRinging());

    // Load alarm settings so we can pass them to math challenge
    _loadAlarmSettings();

    try {
      WakelockPlus.enable();
    } catch (_) {}
  }

  Future<void> _loadAlarmSettings() async {
    try {
      final repo = context.read<AlarmListBloc>().repository;
      final alarms = await repo.getAlarms();
      final alarm = alarms.where((a) => a.id == widget.alarmId).firstOrNull;
      if (alarm != null && mounted) {
        setState(() {
          _difficulty = alarm.difficulty;
          _mathQuestions = alarm.mathQuestions;
        });
      }
    } catch (e) {
      debugPrint('Could not load alarm settings: $e');
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    try {
      WakelockPlus.disable();
    } catch (_) {}
    super.dispose();
  }

  void _startChallenge() {
    context.read<ChallengeBloc>().add(
      StartChallenge(difficulty: _difficulty, totalQuestions: _mathQuestions),
    );
    context.push(
      '/math-challenge',
      extra: {
        'alarmId': widget.alarmId,
        'difficulty': _difficulty,
        'mathQuestions': _mathQuestions,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF3D0000), Color(0xFF0A0000), Color(0xFF3D0000)],
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                const SizedBox(height: 10),

                // Pulsing alarm icon
                ScaleTransition(
                  scale: _scale,
                  child: Container(
                    width: 170,
                    height: 170,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.red.withValues(alpha: 0.12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withValues(alpha: 0.55),
                          blurRadius: 55,
                          spreadRadius: 18,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.alarm_on,
                      size: 90,
                      color: Colors.white,
                    ),
                  ),
                ),

                Column(
                  children: [
                    const Text(
                      'WAKE UP!',
                      style: TextStyle(
                        fontSize: 54,
                        letterSpacing: 8,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.15),
                        ),
                      ),
                      child: const Text(
                        'Solve the challenge to stop the alarm',
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: 15,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Show alarm settings
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _chip(
                          _difficulty,
                          _difficulty == 'EASY'
                              ? Colors.green
                              : _difficulty == 'HARD'
                              ? Colors.red
                              : Colors.orange,
                        ),
                        const SizedBox(width: 8),
                        _chip(
                          '$_mathQuestions math Q${_mathQuestions > 1 ? 's' : ''}',
                          Colors.deepPurple,
                        ),
                        const SizedBox(width: 8),
                        _chip('+ 1 photo', Colors.blueAccent),
                      ],
                    ),
                  ],
                ),

                // Volume slider
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 44),
                  child: Column(
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Icon(Icons.volume_mute, color: Colors.white38),
                          Text(
                            'Alarm Volume',
                            style: TextStyle(
                              color: Colors.white38,
                              fontSize: 13,
                            ),
                          ),
                          Icon(Icons.volume_up, color: Colors.white38),
                        ],
                      ),
                      const SizedBox(height: 4),
                      BlocBuilder<AlarmRingBloc, AlarmRingState>(
                        builder: (context, state) {
                          return Slider(
                            value: state.volume.clamp(0.0, 1.0),
                            activeColor: Colors.redAccent,
                            inactiveColor: Colors.white24,
                            onChanged: (v) => context.read<AlarmRingBloc>().add(
                              ReduceVolume(v),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                // Start challenge button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF3D0000),
                        padding: const EdgeInsets.symmetric(vertical: 22),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        elevation: 10,
                      ),
                      onPressed: _startChallenge,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.psychology, size: 26),
                          SizedBox(width: 12),
                          Text(
                            'START CHALLENGE',
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _chip(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.18),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withValues(alpha: 0.5)),
    ),
    child: Text(
      label,
      style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
    ),
  );
}
