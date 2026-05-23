import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'challenge_event.dart';
import 'challenge_state.dart';

class ChallengeBloc extends Bloc<ChallengeEvent, ChallengeState> {
  final Random _random = Random();

  String _difficulty = 'MEDIUM';
  int _totalQuestions = 2;
  int _currentQuestion = 0;

  static const _objects = [
    'toothbrush',
    'soap',
    'toothpaste tube',
    'towel',
    'shampoo bottle',
    'water tap',
    'mirror',
    'comb',
  ];

  ChallengeBloc() : super(ChallengeInitial()) {
    on<StartChallenge>(_onStart);
    on<SubmitMathAnswer>(_onSubmitMath);
    on<SubmitImageForVerification>(_onSubmitImage);
    on<ImageVerified>(_onImageVerified);
  }

  // ── StartChallenge ────────────────────────────────────────────────────────

  void _onStart(StartChallenge event, Emitter<ChallengeState> emit) {
    _difficulty = event.difficulty;
    _totalQuestions = event.totalQuestions;
    _currentQuestion = 0;
    _emitNextQuestion(emit);
  }

  // ── Math answer ───────────────────────────────────────────────────────────

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
        _emitImageChallenge(emit);
      } else {
        _emitNextQuestion(emit);
      }
    } else {
      emit(s.copyWith(error: 'Wrong answer! Try again.'));
    }
  }

  // ── Image verification ────────────────────────────────────────────────────

  Future<void> _onSubmitImage(
    SubmitImageForVerification event,
    Emitter<ChallengeState> emit,
  ) async {
    final s = state;
    if (s is! ImageVerificationInProgress) return;

    emit(s.copyWith(isVerifying: true, errorMessage: null));

    try {
      final result = await _verifyWithGemini(
        imageBytes: event.imageBytes,
        mimeType: event.mimeType,
        targetObject: s.targetObject,
      );

      _deleteTempFile(event.imagePath);
      add(ImageVerified(success: result.success, message: result.message));
    } catch (e) {
      debugPrint('❌ Verification error: $e');
      _deleteTempFile(event.imagePath);
      add(
        ImageVerified(
          success: false,
          message: 'Verification failed. Please try again.',
        ),
      );
    }
  }

  void _onImageVerified(ImageVerified event, Emitter<ChallengeState> emit) {
    final s = state;
    if (s is! ImageVerificationInProgress) return;

    if (event.success) {
      emit(ChallengeCompleted());
    } else {
      emit(
        ImageVerificationInProgress(
          targetObject: s.targetObject,
          isVerifying: false,
          errorMessage: event.message,
        ),
      );
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

  void _emitImageChallenge(Emitter<ChallengeState> emit) {
    final target = _objects[_random.nextInt(_objects.length)];
    emit(ImageVerificationInProgress(targetObject: target));
  }

  void _deleteTempFile(String path) {
    try {
      final f = File(path);
      f.exists().then((exists) {
        if (exists) {
          f.delete();
          debugPrint('🗑️ Deleted temp image: $path');
        }
      });
    } catch (e) {
      debugPrint('⚠️ Could not delete temp file: $e');
    }
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

  // ── Gemini Vision API (FREE) ──────────────────────────────────────────────

  Future<({bool success, String message})> _verifyWithGemini({
    required List<int> imageBytes,
    required String mimeType,
    required String targetObject,
  }) async {
    final apiKey = dotenv.maybeGet('GEMINI_API_KEY') ?? '';
    if (apiKey.isEmpty) {
      throw Exception(
        'GEMINI_API_KEY not found in .env file.\n'
        'Get a free key at aistudio.google.com',
      );
    }

    final base64Image = base64Encode(imageBytes);

    // Gemini 1.5 Flash — free, fast, great at object detection
    const model = 'gemini-1.5-flash';
    final url =
        'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey';

    final prompt =
        '''
You are verifying that a user photographed the correct object to stop their alarm.
Required object: "$targetObject"

Look at the image and determine if "$targetObject" is clearly visible.

Be LENIENT:
- Partial visibility is fine
- Any angle, any lighting, just woke up quality is fine
- Any brand counts (Lux, Dove, etc. all count as "soap")
- Toothbrush with toothpaste on it counts as "toothbrush"
- Blurry or dark photos are okay if the object is identifiable

Respond with ONLY this JSON (no markdown, no extra text):
{"found": true, "confidence": 0.95, "message": "Toothbrush clearly visible!"}
or
{"found": false, "confidence": 0.1, "message": "No toothbrush found. Please photograph your toothbrush."}
''';

    final requestBody = jsonEncode({
      'contents': [
        {
          'parts': [
            {
              'inline_data': {'mime_type': mimeType, 'data': base64Image},
            },
            {'text': prompt},
          ],
        },
      ],
      'generationConfig': {
        'temperature': 0.1, // low temperature = consistent answers
        'maxOutputTokens': 150,
        'responseMimeType': 'application/json', // force JSON output
      },
    });

    debugPrint('🤖 Sending image to Gemini Vision for: "$targetObject"');

    final response = await http
        .post(
          Uri.parse(url),
          headers: {'Content-Type': 'application/json'},
          body: requestBody,
        )
        .timeout(const Duration(seconds: 30));

    debugPrint('📡 Gemini response status: ${response.statusCode}');

    if (response.statusCode != 200) {
      debugPrint('❌ Gemini API error ${response.statusCode}: ${response.body}');
      throw Exception('Gemini API error ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;

    // Extract text from Gemini response structure
    final candidates = decoded['candidates'] as List<dynamic>? ?? [];
    if (candidates.isEmpty) {
      throw Exception('No response from Gemini');
    }

    final parts = (candidates[0]['content']?['parts'] as List<dynamic>?) ?? [];
    final rawText = parts
        .whereType<Map>()
        .where((p) => p['text'] != null)
        .map((p) => p['text'] as String)
        .join('');

    debugPrint('🤖 Gemini raw response: $rawText');

    // Clean and parse JSON
    final cleaned = rawText
        .replaceAll(RegExp(r'```json\s*'), '')
        .replaceAll(RegExp(r'```\s*'), '')
        .trim();

    // Find the JSON object
    final jsonMatch = RegExp(r'\{.*\}', dotAll: true).firstMatch(cleaned);
    if (jsonMatch == null) {
      debugPrint('❌ Cannot parse JSON from: $cleaned');
      throw Exception('Unexpected response format');
    }

    final json = jsonDecode(jsonMatch.group(0)!) as Map<String, dynamic>;
    final found = json['found'] as bool? ?? false;
    final confidence = (json['confidence'] as num?)?.toDouble() ?? 0.0;
    final message = json['message'] as String? ?? '';

    debugPrint('✅ Result: found=$found, confidence=$confidence, msg=$message');

    // 0.60 threshold — lenient for just-woke-up photos
    return (success: found && confidence >= 0.60, message: message);
  }
}
