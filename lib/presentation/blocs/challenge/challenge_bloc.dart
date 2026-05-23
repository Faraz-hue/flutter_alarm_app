import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'challenge_event.dart';
import 'challenge_state.dart';

class ChallengeBloc extends Bloc<ChallengeEvent, ChallengeState> {
  final Random _random = Random();

  String _difficulty = 'MEDIUM';
  int _totalQuestions = 2;
  int _currentQuestion = 0;

  // Objects ML Kit Image Labeling reliably detects
  // These are actual ML Kit label strings (lowercase)
  static const _objectPool = [
    'toothbrush',
    'soap',
    'towel',
    'mirror',
    'comb',
    'bottle', // shampoo/conditioner bottle
    'tap', // water tap / faucet
    'sink',
  ];

  // Maps our target → ML Kit label keywords to match against
  // ML Kit returns labels like "Toothbrush", "Personal care", "Soap", etc.
  static const Map<String, List<String>> _labelKeywords = {
    'toothbrush': ['toothbrush', 'tooth brush', 'dental', 'oral care'],
    'soap': ['soap', 'bar soap', 'personal care', 'hygiene'],
    'towel': ['towel', 'textile', 'linens', 'cloth'],
    'mirror': ['mirror', 'glass', 'reflection'],
    'comb': ['comb', 'hair', 'brush', 'hairbrush'],
    'bottle': ['bottle', 'shampoo', 'conditioner', 'liquid'],
    'tap': ['tap', 'faucet', 'sink', 'plumbing', 'water'],
    'sink': ['sink', 'basin', 'plumbing', 'tap', 'faucet'],
  };

  ChallengeBloc() : super(ChallengeInitial()) {
    on<StartChallenge>(_onStart);
    on<SubmitMathAnswer>(_onSubmitMath);
    on<LabelsDetected>(_onLabelsDetected);
    on<ObjectConfirmed>(_onObjectConfirmed);
  }

  // ── Start ─────────────────────────────────────────────────────────────────

  void _onStart(StartChallenge event, Emitter<ChallengeState> emit) {
    _difficulty = event.difficulty;
    _totalQuestions = event.totalQuestions;
    _currentQuestion = 0;
    _emitNextQuestion(emit);
  }

  // ── Math ──────────────────────────────────────────────────────────────────

  void _onSubmitMath(SubmitMathAnswer event, Emitter<ChallengeState> emit) {
    final s = state;
    if (s is! MathChallengeInProgress) return;

    final userAnswer = double.tryParse(event.answer);
    if (userAnswer == null) {
      emit(s.copyWith(error: 'Enter a valid number.'));
      return;
    }

    if ((userAnswer - s.correctAnswer).abs() < 0.01) {
      if (_currentQuestion >= _totalQuestions) {
        emit(MathChallengeSuccess());
        _emitObjectChallenge(emit);
      } else {
        _emitNextQuestion(emit);
      }
    } else {
      emit(s.copyWith(error: 'Wrong! Try again.'));
    }
  }

  // ── ML Kit label stream ───────────────────────────────────────────────────

  void _onLabelsDetected(LabelsDetected event, Emitter<ChallengeState> emit) {
    final s = state;
    if (s is! ObjectDetectionInProgress) return;

    // Always update the UI with what's currently visible
    emit(
      s.copyWith(
        detectedLabels: event.labels,
        statusMessage: _buildStatusMessage(event.labels, s.targetObject),
      ),
    );

    // Check for a match
    if (_isMatch(event.labels, s.targetObject)) {
      emit(ChallengeCompleted());
    }
  }

  // ── Desktop / debug confirm ───────────────────────────────────────────────

  void _onObjectConfirmed(ObjectConfirmed event, Emitter<ChallengeState> emit) {
    if (state is ObjectDetectionInProgress) {
      emit(ChallengeCompleted());
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void _emitNextQuestion(Emitter<ChallengeState> emit) {
    _currentQuestion++;
    final (problem, answer) = _buildProblem(_difficulty);
    emit(
      MathChallengeInProgress(
        problem: problem,
        correctAnswer: answer,
        difficulty: _difficulty,
        currentQuestion: _currentQuestion,
        totalQuestions: _totalQuestions,
      ),
    );
  }

  void _emitObjectChallenge(Emitter<ChallengeState> emit) {
    final target = _objectPool[_random.nextInt(_objectPool.length)];
    emit(ObjectDetectionInProgress(targetObject: target));
  }

  /// Match detected ML Kit labels against our target keywords
  bool _isMatch(List<String> detectedLabels, String targetObject) {
    final keywords = _labelKeywords[targetObject] ?? [targetObject];
    for (final detected in detectedLabels) {
      final lower = detected.toLowerCase();
      for (final keyword in keywords) {
        if (lower.contains(keyword)) return true;
      }
    }
    return false;
  }

  String _buildStatusMessage(List<String> labels, String target) {
    if (labels.isEmpty) return 'Point camera at the $target...';
    final keywords = _labelKeywords[target] ?? [target];
    // Check if any detected label is even close
    for (final label in labels) {
      for (final kw in keywords) {
        if (label.toLowerCase().contains(kw)) {
          return '✅ $target detected!';
        }
      }
    }
    // Show what it sees so user knows camera is working
    final topLabels = labels.take(2).join(', ');
    return 'Seeing: $topLabels\nLooking for $target...';
  }

  (String, double) _buildProblem(String difficulty) {
    switch (difficulty) {
      case 'EASY':
        final a = _random.nextInt(20) + 1;
        final b = _random.nextInt(20) + 1;
        return ('$a + $b', (a + b).toDouble());
      case 'HARD':
        final b = _random.nextInt(9) + 2;
        final a = b * (_random.nextInt(12) + 2);
        final c = _random.nextInt(20) + 1;
        return ('($a ÷ $b) + $c', (a / b + c).toDouble());
      case 'MEDIUM':
      default:
        final a = _random.nextInt(12) + 2;
        final b = _random.nextInt(10) + 2;
        return ('$a × $b', (a * b).toDouble());
    }
  }
}
