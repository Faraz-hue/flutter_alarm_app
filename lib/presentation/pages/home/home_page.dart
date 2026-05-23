import 'package:alarm_app/presentation/blocs/alarm_list/alarm_list_bloc.dart';
import 'package:alarm_app/presentation/blocs/alarm_list/alarm_list_state.dart';
import 'package:alarm_app/presentation/widgets/alarm_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Wake-Up Challenge',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart_rounded),
            tooltip: 'Statistics',
            onPressed: () => context.push('/statistics'),
          ),
        ],
      ),
      body: BlocBuilder<AlarmListBloc, AlarmListState>(
        builder: (context, state) {
          if (state is AlarmListLoaded) {
            if (state.alarms.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.alarm_off,
                      size: 80,
                      color: Colors.white.withValues(alpha: 0.15),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No alarms yet',
                      style: TextStyle(fontSize: 20, color: Colors.white54),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Tap + to add your first alarm',
                      style: TextStyle(fontSize: 14, color: Colors.white38),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Row(
                    children: [
                      Icon(
                        Icons.swipe_left,
                        size: 14,
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Swipe left or tap 🗑 to delete',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 80),
                    itemCount: state.alarms.length,
                    itemBuilder: (context, index) {
                      return AlarmTile(alarm: state.alarms[index]);
                    },
                  ),
                ),
              ],
            );
          }

          return const Center(child: CircularProgressIndicator());
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/addAlarm'),
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.add),
      ),
    );
  }
}
