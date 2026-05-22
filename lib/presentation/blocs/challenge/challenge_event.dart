import 'package:equatable/equatable.dart';

abstract class ChallengeEvent extends Equatable {
  const ChallengeEvent();

  @override
  List<Object?> get props => [];
}

class StartChallenge extends ChallengeEvent {}

class SubmitMathAnswer extends ChallengeEvent {
  final String answer;

  const SubmitMathAnswer(this.answer);

  @override
  List<Object?> get props => [answer];
}

class ObjectDetected extends ChallengeEvent {
  final String detectedObject;

  const ObjectDetected(this.detectedObject);

  @override
  List<Object?> get props => [detectedObject];
}
