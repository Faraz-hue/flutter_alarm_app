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
        title: const Text('Wake-Up Challenge'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () => context.push('/statistics'),
          ),
        ],
      ),
      body: BlocBuilder<AlarmListBloc, AlarmListState>(
        builder: (context, state) {
          if (state is AlarmListLoaded) {
            if (state.alarms.isEmpty) {
              return const Center(child: Text('No alarms yet'));
            }

            return ListView.builder(
              itemCount: state.alarms.length,
              itemBuilder: (context, index) {
                return AlarmTile(alarm: state.alarms[index]);
              },
            );
          }

          return const Center(child: CircularProgressIndicator());
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.push('/addAlarm');
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
