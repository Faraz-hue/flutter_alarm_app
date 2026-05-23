import 'package:equatable/equatable.dart';

abstract class ChallengeEvent extends Equatable {
  const ChallengeEvent();
  @override
  List<Object?> get props => [];
}

class StartChallenge extends ChallengeEvent {
  final String difficulty;
  final int totalQuestions;

  const StartChallenge({this.difficulty = 'MEDIUM', this.totalQuestions = 2});

  @override
  List<Object?> get props => [difficulty, totalQuestions];
}

class SubmitMathAnswer extends ChallengeEvent {
  final String answer;
  const SubmitMathAnswer(this.answer);
  @override
  List<Object?> get props => [answer];
}

/// ML Kit detected labels from the live camera frame
class LabelsDetected extends ChallengeEvent {
  final List<String> labels;
  const LabelsDetected(this.labels);
  @override
  List<Object?> get props => [labels];
}

/// User confirmed object (desktop fallback / debug)
class ObjectConfirmed extends ChallengeEvent {}
