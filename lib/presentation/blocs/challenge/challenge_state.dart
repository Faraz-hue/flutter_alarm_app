import 'package:equatable/equatable.dart';

abstract class ChallengeState extends Equatable {
  const ChallengeState();
  @override
  List<Object?> get props => [];
}

class ChallengeInitial extends ChallengeState {}

/// Solving one of N math questions
class MathChallengeInProgress extends ChallengeState {
  final String problem;
  final double correctAnswer;
  final String difficulty;
  final int currentQuestion; // 1-based
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

/// All math questions solved — brief success flash
class MathChallengeSuccess extends ChallengeState {}

/// Waiting for user to take + upload a photo
class ImageVerificationInProgress extends ChallengeState {
  final String targetObject;
  final bool isVerifying; // true while API call is running
  final String? errorMessage; // set when API says wrong object

  const ImageVerificationInProgress({
    required this.targetObject,
    this.isVerifying = false,
    this.errorMessage,
  });

  ImageVerificationInProgress copyWith({
    bool? isVerifying,
    String? errorMessage,
  }) => ImageVerificationInProgress(
    targetObject: targetObject,
    isVerifying: isVerifying ?? this.isVerifying,
    errorMessage: errorMessage,
  );

  @override
  List<Object?> get props => [targetObject, isVerifying, errorMessage];
}

/// Everything done — alarm can be stopped
class ChallengeCompleted extends ChallengeState {}

class ChallengeFailure extends ChallengeState {
  final String message;
  const ChallengeFailure(this.message);
  @override
  List<Object?> get props => [message];
}
