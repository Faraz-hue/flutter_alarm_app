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
  final String difficulty;
  final int currentQuestion;
  final int totalQuestions;
  final String? error;

  const MathChallengeInProgress({
    required this.problem,
    required this.correctAnswer,
    required this.difficulty,
    required this.currentQuestion,
    required this.totalQuestions,
    this.error,
  });

  MathChallengeInProgress copyWith({String? error}) => MathChallengeInProgress(
    problem: problem,
    correctAnswer: correctAnswer,
    difficulty: difficulty,
    currentQuestion: currentQuestion,
    totalQuestions: totalQuestions,
    error: error,
  );

  @override
  List<Object?> get props => [
    problem,
    correctAnswer,
    difficulty,
    currentQuestion,
    totalQuestions,
    error,
  ];
}

class MathChallengeSuccess extends ChallengeState {}

/// Live camera scanning — ML Kit Image Labeling
class ObjectDetectionInProgress extends ChallengeState {
  final String targetObject;
  final List<String> detectedLabels; // what ML Kit currently sees
  final String? statusMessage;

  const ObjectDetectionInProgress({
    required this.targetObject,
    this.detectedLabels = const [],
    this.statusMessage,
  });

  ObjectDetectionInProgress copyWith({
    List<String>? detectedLabels,
    String? statusMessage,
  }) => ObjectDetectionInProgress(
    targetObject: targetObject,
    detectedLabels: detectedLabels ?? this.detectedLabels,
    statusMessage: statusMessage ?? this.statusMessage,
  );

  @override
  List<Object?> get props => [targetObject, detectedLabels, statusMessage];
}

class ChallengeCompleted extends ChallengeState {}

class ChallengeFailure extends ChallengeState {
  final String message;
  const ChallengeFailure(this.message);
  @override
  List<Object?> get props => [message];
}
