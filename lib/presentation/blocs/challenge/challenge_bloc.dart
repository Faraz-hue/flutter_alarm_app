import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'challenge_event.dart';
import 'challenge_state.dart';

class ChallengeBloc extends Bloc<ChallengeEvent, ChallengeState> {
  final Random _random = Random();

  ChallengeBloc() : super(ChallengeInitial()) {
    on<StartChallenge>(_onStartChallenge);
    on<SubmitMathAnswer>(_onSubmitMathAnswer);
    on<ObjectDetected>(_onObjectDetected);
  }

  void _onStartChallenge(StartChallenge event, Emitter<ChallengeState> emit) {
    _generateMathProblem(emit);
  }

  void _onSubmitMathAnswer(SubmitMathAnswer event, Emitter<ChallengeState> emit) {
    final currentState = state;
    if (currentState is MathChallengeInProgress) {
      final userAnswer = double.tryParse(event.answer);
      if (userAnswer == currentState.correctAnswer) {
        emit(MathChallengeSuccess());
        _startObjectDetection(emit);
      } else {
        emit(MathChallengeInProgress(
          problem: currentState.problem,
          correctAnswer: currentState.correctAnswer,
          difficulty: currentState.difficulty,
          error: "Incorrect answer. Try again!",
        ));
      }
    }
  }

  void _onObjectDetected(ObjectDetected event, Emitter<ChallengeState> emit) {
    final currentState = state;
    if (currentState is ObjectDetectionInProgress) {
      if (event.detectedObject.toLowerCase() == currentState.targetObject.toLowerCase()) {
        emit(ChallengeCompleted());
      }
    }
  }

  void _generateMathProblem(Emitter<ChallengeState> emit) {
    int difficultyLevel = _random.nextInt(3); // 0: Easy, 1: Medium, 2: Hard
    String difficulty = "EASY";
    double result = 0;
    String problem = "";

    if (difficultyLevel == 0) {
      difficulty = "EASY";
      int a = _random.nextInt(20) + 1;
      int b = _random.nextInt(20) + 1;
      result = (a + b).toDouble();
      problem = "$a + $b";
    } else if (difficultyLevel == 1) {
      difficulty = "MEDIUM";
      int a = _random.nextInt(15) + 2;
      int b = _random.nextInt(10) + 2;
      result = (a * b).toDouble();
      problem = "$a * $b";
    } else {
      difficulty = "HARD";
      // Ensure integer division: a = b * multiplier
      int b = _random.nextInt(9) + 2;
      int multiplier = _random.nextInt(12) + 2;
      int a = b * multiplier;
      int c = _random.nextInt(20) + 1;
      result = (a / b + c).toDouble();
      problem = "($a / $b) + $c";
    }

    emit(MathChallengeInProgress(
      problem: problem,
      correctAnswer: result,
      difficulty: difficulty,
    ));
  }

  void _startObjectDetection(Emitter<ChallengeState> emit) {
    final objects = ['toothbrush', 'toothpaste', 'soap', 'shower', 'commode'];
    final target = objects[_random.nextInt(objects.length)];
    emit(ObjectDetectionInProgress(targetObject: target));
  }
}
