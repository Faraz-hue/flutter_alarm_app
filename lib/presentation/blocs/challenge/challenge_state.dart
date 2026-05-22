import 'package:equatable/equatable.dart';

abstract class ChallengeState extends Equatable {
  const ChallengeState();

  @override
  List<Object?> get props => [];
}

class ChallengeInitial extends ChallengeState {}

class MathChallengeInProgress extends ChallengeState {
  final String problem;
  final double correctAnswer;
  final String? error;
  final String difficulty;

  const MathChallengeInProgress({
    required this.problem,
    required this.correctAnswer,
    required this.difficulty,
    this.error,
  });

  @override
  List<Object?> get props => [problem, correctAnswer, error, difficulty];
}

class MathChallengeSuccess extends ChallengeState {}

class ObjectDetectionInProgress extends ChallengeState {
  final String targetObject;
  final String? statusMessage;

  const ObjectDetectionInProgress({
    required this.targetObject,
    this.statusMessage,
  });

  @override
  List<Object?> get props => [targetObject, statusMessage];
}

class ChallengeCompleted extends ChallengeState {}

class ChallengeFailure extends ChallengeState {
  final String message;

  const ChallengeFailure(this.message);

  @override
  List<Object?> get props => [message];
}
