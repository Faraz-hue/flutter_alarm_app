// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'package:alarm_app/core/services/audio_service.dart';
import 'package:alarm_app/core/services/notification_service.dart';
import 'package:alarm_app/domain/entities/log_entity.dart';
import 'package:alarm_app/presentation/blocs/alarm_list/alarm_list_bloc.dart';
import 'package:alarm_app/presentation/blocs/alarm_ring/alarm_ring_bloc.dart';
import 'package:alarm_app/presentation/blocs/alarm_ring/alarm_ring_event.dart';
import 'package:alarm_app/presentation/blocs/challenge/challenge_bloc.dart';
import 'package:alarm_app/presentation/blocs/challenge/challenge_event.dart';
import 'package:alarm_app/presentation/blocs/challenge/challenge_state.dart';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';

class ScannerPage extends StatefulWidget {
  final String alarmId;
  const ScannerPage({super.key, required this.alarmId});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  CameraController? _camera;
  ImageLabeler? _labeler;
  bool _isBusy = false;
  bool _completed = false;
  late DateTime _startTime;

  // Only run on real mobile devices
  final bool _isMobile = !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
    if (_isMobile) _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;

      _camera = CameraController(
        cameras[0],
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
      );
      await _camera!.initialize();

      // ML Kit Image Labeling — on-device, no internet needed
      final options = ImageLabelerOptions(confidenceThreshold: 0.55);
      _labeler = ImageLabeler(options: options);

      _camera!.startImageStream(_onCameraFrame);
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('❌ Camera init error: $e');
    }
  }

  Future<void> _onCameraFrame(CameraImage frame) async {
    if (_isBusy || _labeler == null || _completed) return;
    _isBusy = true;

    try {
      final inputImage = _buildInputImage(frame);
      if (inputImage == null) return;

      final labels = await _labeler!.processImage(inputImage);

      if (!mounted) return;

      // Send all label texts to the bloc
      final labelTexts = labels.map((l) => l.label).toList();
      debugPrint('🏷️ ML Kit labels: $labelTexts');

      context.read<ChallengeBloc>().add(LabelsDetected(labelTexts));
    } catch (e) {
      debugPrint('Frame processing error: $e');
    } finally {
      _isBusy = false;
    }
  }

  InputImage? _buildInputImage(CameraImage frame) {
    final camera = _camera!.description;

    InputImageRotation rotation = InputImageRotation.rotation0deg;
    if (Platform.isAndroid) {
      switch (camera.sensorOrientation) {
        case 90:
          rotation = InputImageRotation.rotation90deg;
          break;
        case 180:
          rotation = InputImageRotation.rotation180deg;
          break;
        case 270:
          rotation = InputImageRotation.rotation270deg;
          break;
      }
    }

    final format = InputImageFormatValue.fromRawValue(frame.format.raw);
    if (format == null) return null;

    // For multi-plane (Android NV21) concatenate all planes
    final WriteBuffer buffer = WriteBuffer();
    for (final plane in frame.planes) {
      buffer.putUint8List(plane.bytes);
    }
    final bytes = buffer.done().buffer.asUint8List();

    return InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: Size(frame.width.toDouble(), frame.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: frame.planes[0].bytesPerRow,
      ),
    );
  }

  Future<void> _onChallengeComplete() async {
    if (_completed) return;
    _completed = true;
    _camera?.stopImageStream();

    try {
      context.read<AlarmRingBloc>().add(StopRinging());
    } catch (_) {}
    await AudioService().stopAlarm();
    await NotificationService.cancel(widget.alarmId.hashCode);

    try {
      final repo = context.read<AlarmListBloc>().repository;
      final timeTaken = DateTime.now().difference(_startTime).inSeconds;
      await repo.saveLog(
        LogEntity(
          alarmId: widget.alarmId,
          timestamp: DateTime.now(),
          success: true,
          timeTakenSeconds: timeTaken,
        ),
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFF0D0D1A),
        body: BlocConsumer<ChallengeBloc, ChallengeState>(
          listener: (context, state) async {
            if (state is ChallengeCompleted) {
              await _onChallengeComplete();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('🎉 Challenge complete! Good morning!'),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 2),
                  ),
                );
                context.go('/');
              }
            }
          },
          builder: (context, state) {
            if (state is ObjectDetectionInProgress) {
              return _buildScannerUI(state);
            }
            return const Center(child: CircularProgressIndicator());
          },
        ),
      ),
    );
  }

  Widget _buildScannerUI(ObjectDetectionInProgress state) {
    return Stack(
      children: [
        // ── Camera preview / desktop background ──────────────────────
        Positioned.fill(
          child: _isMobile && _camera != null && _camera!.value.isInitialized
              ? CameraPreview(_camera!)
              : _desktopBackground(state.targetObject),
        ),

        // ── Dark gradient overlay at top and bottom ──────────────────
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.75),
                  Colors.transparent,
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.85),
                ],
                stops: const [0.0, 0.25, 0.65, 1.0],
              ),
            ),
          ),
        ),

        // ── Content ──────────────────────────────────────────────────
        SafeArea(
          child: Column(
            children: [
              // Step indicator
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: _stepRow(step: 2),
              ),

              // Target object card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.deepPurple.withValues(alpha: 0.7),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'POINT CAMERA AT',
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: 11,
                          letterSpacing: 3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        state.targetObject.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(),

              // ── Live label feed ──────────────────────────────────
              if (_isMobile && state.detectedLabels.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _labelFeed(state),
                ),

              const SizedBox(height: 12),

              // ── Status message ───────────────────────────────────
              if (state.statusMessage != null)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: state.statusMessage!.startsWith('✅')
                        ? Colors.green.withValues(alpha: 0.2)
                        : Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: state.statusMessage!.startsWith('✅')
                          ? Colors.green.withValues(alpha: 0.6)
                          : Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Text(
                    state.statusMessage!,
                    style: TextStyle(
                      color: state.statusMessage!.startsWith('✅')
                          ? Colors.greenAccent
                          : Colors.white60,
                      fontSize: 13,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

              const SizedBox(height: 16),

              // ── Bottom action ────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: _isMobile ? _mobileHint() : _desktopConfirmButton(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Shows real-time labels as chips so user sees camera is working
  Widget _labelFeed(ObjectDetectionInProgress state) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 6,
      runSpacing: 6,
      children: state.detectedLabels.take(5).map((label) {
        final isMatch = label.toLowerCase().contains(
          state.targetObject.toLowerCase().split(' ')[0],
        );
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isMatch
                ? Colors.green.withValues(alpha: 0.25)
                : Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isMatch
                  ? Colors.green.withValues(alpha: 0.7)
                  : Colors.white.withValues(alpha: 0.15),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isMatch ? Colors.greenAccent : Colors.white54,
              fontSize: 12,
              fontWeight: isMatch ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _mobileHint() => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: Colors.greenAccent,
          shape: BoxShape.circle,
        ),
      ),
      const SizedBox(width: 8),
      const Text(
        'Camera is scanning automatically',
        style: TextStyle(color: Colors.white38, fontSize: 13),
      ),
    ],
  );

  Widget _desktopConfirmButton() => SizedBox(
    width: double.infinity,
    child: ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      onPressed: () => context.read<ChallengeBloc>().add(ObjectConfirmed()),
      icon: const Icon(Icons.check_circle_outline),
      label: Text(
        'I HAVE THE ${(context.read<ChallengeBloc>().state as ObjectDetectionInProgress).targetObject.toUpperCase()} — CONFIRM',
        style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
      ),
    ),
  );

  Widget _desktopBackground(String target) => Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.deepPurple.shade900, const Color(0xFF0D0D1A)],
      ),
    ),
    child: Center(
      child: Icon(
        _iconFor(target),
        size: 130,
        color: Colors.white.withValues(alpha: 0.06),
      ),
    ),
  );

  IconData _iconFor(String object) {
    switch (object) {
      case 'toothbrush':
        return Icons.cleaning_services;
      case 'soap':
        return Icons.soap;
      case 'towel':
        return Icons.dry_cleaning;
      case 'mirror':
        return Icons.rectangle_outlined;
      case 'bottle':
        return Icons.local_drink;
      case 'tap':
      case 'sink':
        return Icons.water_drop;
      default:
        return Icons.search;
    }
  }

  // ── Step indicator widgets ────────────────────────────────────────────────

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

  @override
  void dispose() {
    _camera?.dispose();
    _labeler?.close();
    super.dispose();
  }
}
