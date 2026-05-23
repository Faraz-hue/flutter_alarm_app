import 'package:alarm_app/presentation/blocs/challenge/challenge_bloc.dart';
import 'package:alarm_app/presentation/blocs/challenge/challenge_event.dart';
import 'package:alarm_app/presentation/blocs/challenge/challenge_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class MathChallengePage extends StatefulWidget {
  final String alarmId;
  final String difficulty;
  final int mathQuestions;

  const MathChallengePage({
    super.key,
    required this.alarmId,
    this.difficulty = 'MEDIUM',
    this.mathQuestions = 2,
  });

  @override
  State<MathChallengePage> createState() => _MathChallengePageState();
}

class _MathChallengePageState extends State<MathChallengePage> {
  final TextEditingController _ctrl = TextEditingController();
  final FocusNode _focus = FocusNode();
  bool _navigating = false;

  @override
  void initState() {
    super.initState();
    context.read<ChallengeBloc>().add(
      StartChallenge(
        difficulty: widget.difficulty,
        totalQuestions: widget.mathQuestions,
      ),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    context.read<ChallengeBloc>().add(SubmitMathAnswer(text));
    _ctrl.clear();
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFF0D0D1A),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false,
          title: const Text(
            'Math Challenge',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
        ),
        body: BlocConsumer<ChallengeBloc, ChallengeState>(
          listener: (context, state) {
            // Navigate to scanner when math is done
            if (state is MathChallengeSuccess && !_navigating) {
              _navigating = true;
              Future.delayed(const Duration(milliseconds: 500), () {
                if (mounted) {
                  context.pushReplacement('/scanner', extra: widget.alarmId);
                }
              });
            }
            // Also handle if bloc jumps straight to ObjectDetectionInProgress
            if (state is ObjectDetectionInProgress && !_navigating) {
              _navigating = true;
              Future.delayed(const Duration(milliseconds: 300), () {
                if (mounted) {
                  context.pushReplacement('/scanner', extra: widget.alarmId);
                }
              });
            }
          },
          builder: (context, state) {
            if (state is MathChallengeInProgress) {
              return _buildMathUI(context, state);
            }
            if (state is MathChallengeSuccess) {
              return _buildSuccessFlash();
            }
            return const Center(child: CircularProgressIndicator());
          },
        ),
      ),
    );
  }

  Widget _buildMathUI(BuildContext context, MathChallengeInProgress state) {
    final diffColor = _diffColor(state.difficulty);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        children: [
          _stepRow(step: 1),
          const SizedBox(height: 24),

          // Difficulty badge + question counter
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: diffColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: diffColor, width: 1.2),
                ),
                child: Text(
                  state.difficulty,
                  style: TextStyle(
                    color: diffColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              Text(
                'Question ${state.currentQuestion} of ${state.totalQuestions}',
                style: const TextStyle(color: Colors.white54, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Progress dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(state.totalQuestions, (i) {
              final done = i < state.currentQuestion - 1;
              final current = i == state.currentQuestion - 1;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: current ? 28 : 10,
                height: 10,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5),
                  color: done
                      ? Colors.green
                      : current
                      ? Colors.deepPurple
                      : Colors.white12,
                ),
              );
            }),
          ),
          const SizedBox(height: 20),

          const Text(
            'Solve this to prove you\'re awake:',
            style: TextStyle(fontSize: 15, color: Colors.white54),
          ),
          const SizedBox(height: 16),

          // Problem box
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.deepPurple.withValues(alpha: 0.4),
                width: 1.5,
              ),
            ),
            child: Text(
              state.problem,
              style: const TextStyle(
                fontSize: 56,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 2,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 28),

          // Answer input
          TextField(
            controller: _ctrl,
            focusNode: _focus,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 30, color: Colors.white),
            decoration: InputDecoration(
              hintText: '?',
              hintStyle: const TextStyle(color: Colors.white24, fontSize: 30),
              errorText: state.error,
              errorStyle: const TextStyle(
                color: Colors.redAccent,
                fontSize: 13,
              ),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.06),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: Colors.deepPurple,
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Colors.redAccent, width: 2),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Colors.redAccent, width: 2),
              ),
            ),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 24),

          // Submit button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 6,
              ),
              onPressed: _submit,
              child: const Text(
                'SUBMIT ANSWER',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessFlash() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_rounded, color: Colors.green, size: 90),
          SizedBox(height: 20),
          Text(
            'All correct!',
            style: TextStyle(
              fontSize: 32,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Now find the object...',
            style: TextStyle(color: Colors.white54),
          ),
        ],
      ),
    );
  }

  Widget _stepRow({required int step}) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      _stepDot(1, 'Math', step == 1),
      _stepLine(),
      _stepDot(2, 'Scan', step == 2),
    ],
  );

  Widget _stepDot(int n, String label, bool active) => Column(
    children: [
      Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: active ? Colors.deepPurple : Colors.white12,
        ),
        alignment: Alignment.center,
        child: Text(
          '$n',
          style: TextStyle(
            color: active ? Colors.white : Colors.white38,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      const SizedBox(height: 4),
      Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: active ? Colors.deepPurpleAccent : Colors.white38,
        ),
      ),
    ],
  );

  Widget _stepLine() => Container(
    width: 40,
    height: 2,
    margin: const EdgeInsets.only(bottom: 20, left: 4, right: 4),
    color: Colors.white12,
  );

  Color _diffColor(String d) {
    switch (d) {
      case 'EASY':
        return Colors.green;
      case 'HARD':
        return Colors.redAccent;
      default:
        return Colors.orange;
    }
  }
}
