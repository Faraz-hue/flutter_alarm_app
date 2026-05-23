import 'package:equatable/equatable.dart';

abstract class ChallengeEvent extends Equatable {
  const ChallengeEvent();
  @override
  List<Object?> get props => [];
}

/// Start challenge with chosen difficulty and question count (from alarm settings)
class StartChallenge extends ChallengeEvent {
  final String difficulty; // 'EASY' | 'MEDIUM' | 'HARD'
  final int totalQuestions; // 1-5

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

/// User uploaded an image — bytes + mimeType for Anthropic Vision
class SubmitImageForVerification extends ChallengeEvent {
  final List<int> imageBytes;
  final String mimeType; // 'image/jpeg' | 'image/png'
  final String imagePath; // local path to delete after verification

  const SubmitImageForVerification({
    required this.imageBytes,
    required this.mimeType,
    required this.imagePath,
  });

  @override
  List<Object?> get props => [mimeType, imagePath];
}

/// Internal: Anthropic confirmed the object
class ImageVerified extends ChallengeEvent {
  final bool success;
  final String message;
  const ImageVerified({required this.success, required this.message});
  @override
  List<Object?> get props => [success, message];
}
