import 'package:alarm_app/presentation/blocs/alarm_ring/alarm_ring_bloc.dart';
import 'package:alarm_app/presentation/blocs/alarm_ring/alarm_ring_event.dart';
import 'package:alarm_app/presentation/blocs/alarm_ring/alarm_ring_state.dart';
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

class _RingingPageState extends State<RingingPage> {
  @override
  void initState() {
    super.initState();
    context.read<AlarmRingBloc>().add(StartRinging());
    WakelockPlus.enable();
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.red.shade900, Colors.black, Colors.red.shade900],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withValues(alpha: 0.5),
                      blurRadius: 40,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.alarm_on,
                  size: 120,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 60),
              const Text(
                'WAKE UP!',
                style: TextStyle(
                  fontSize: 56,
                  letterSpacing: 4,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Challenge Required to Stop',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 18,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 60),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Icon(Icons.volume_down, color: Colors.white54),
                        Text(
                          'Gradual Volume',
                          style: TextStyle(color: Colors.white54),
                        ),
                        Icon(Icons.volume_up, color: Colors.white54),
                      ],
                    ),
                    BlocBuilder<AlarmRingBloc, AlarmRingState>(
                      builder: (context, state) {
                        return Slider(
                          value: state.volume,
                          activeColor: Colors.redAccent,
                          inactiveColor: Colors.white24,
                          onChanged: (value) {
                            context.read<AlarmRingBloc>().add(
                              ReduceVolume(value),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 20,
                  ),
                ),
                onPressed: () {
                  context.push('/math-challenge', extra: widget.alarmId);
                },
                child: const Text('GO TO CHALLENGE'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
