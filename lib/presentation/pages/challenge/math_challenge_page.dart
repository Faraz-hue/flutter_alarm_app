import 'package:alarm_app/presentation/blocs/challenge/challenge_bloc.dart';
import 'package:alarm_app/presentation/blocs/challenge/challenge_event.dart';
import 'package:alarm_app/presentation/blocs/challenge/challenge_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class MathChallengePage extends StatefulWidget {
  final String alarmId;

  const MathChallengePage({super.key, required this.alarmId});

  @override
  State<MathChallengePage> createState() => _MathChallengePageState();
}

class _MathChallengePageState extends State<MathChallengePage> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<ChallengeBloc>().add(StartChallenge());
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(title: const Text('Math Challenge')),
        body: BlocConsumer<ChallengeBloc, ChallengeState>(
          listener: (context, state) {
            if (state is MathChallengeSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Correct! Now find the object.')),
              );
              context.pushReplacement('/scanner', extra: widget.alarmId);
            }
          },
          builder: (context, state) {
            if (state is MathChallengeInProgress) {
              return Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Level: ${state.difficulty}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Solve this to prove you are awake:',
                      style: TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      state.problem,
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 40),
                    TextField(
                      controller: _controller,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 24),
                      decoration: InputDecoration(
                        hintText: 'Enter answer',
                        errorText: state.error,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          context.read<ChallengeBloc>().add(
                            SubmitMathAnswer(_controller.text),
                          );
                          _controller.clear();
                        },
                        child: const Text('SUBMIT'),
                      ),
                    ),
                  ],
                ),
              );
            }
            return const Center(child: CircularProgressIndicator());
          },
        ),
      ),
    );
  }
}
