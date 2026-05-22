import 'package:alarm_app/domain/entities/log_entity.dart';
import 'package:alarm_app/presentation/blocs/alarm_list/alarm_list_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class StatisticsPage extends StatelessWidget {
  const StatisticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Wake-Up Statistics')),
      body: FutureBuilder<List<LogEntity>>(
        future: (context.read<AlarmListBloc>().repository).getLogs(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No history yet. Wake up!'));
          }

          final logs = snapshot.data!;
          final total = logs.length;
          final success = logs.where((l) => l.success).length;
          final avgTime = total == 0
              ? 0.0
              : logs.map((l) => l.timeTakenSeconds).reduce((a, b) => a + b) /
                    total;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildStatCard(
                'Success Rate',
                '${(success / total * 100).toStringAsFixed(1)}%',
              ),
              _buildStatCard('Total Wake-Ups', total.toString()),
              _buildStatCard(
                'Avg. Wake-Up Time',
                '${avgTime.toStringAsFixed(1)} sec',
              ),
              const SizedBox(height: 20),
              const Text(
                'Recent Logs',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const Divider(),
              ...logs.reversed
                  .take(10)
                  .map(
                    (log) => ListTile(
                      title: Text(log.success ? 'Success' : 'Failure'),
                      subtitle: Text(log.timestamp.toString().split('.')[0]),
                      trailing: Text('${log.timeTakenSeconds}s'),
                    ),
                  ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String title, String value) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(title, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
