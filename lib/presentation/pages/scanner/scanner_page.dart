import 'package:alarm_app/domain/entities/log_entity.dart';
import 'package:alarm_app/presentation/blocs/alarm_list/alarm_list_bloc.dart';
import 'package:alarm_app/presentation/blocs/challenge/challenge_bloc.dart';
import 'package:alarm_app/presentation/blocs/challenge/challenge_event.dart';
import 'package:alarm_app/presentation/blocs/challenge/challenge_state.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import 'package:go_router/go_router.dart';
import 'package:alarm_app/core/services/notification_service.dart';
import 'package:alarm_app/presentation/blocs/alarm_ring/alarm_ring_bloc.dart';
import 'package:alarm_app/presentation/blocs/alarm_ring/alarm_ring_event.dart';
import 'dart:io';

class ScannerPage extends StatefulWidget {
  final String alarmId;

  const ScannerPage({super.key, required this.alarmId});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  CameraController? _cameraController;
  ObjectDetector? _objectDetector;
  bool _isBusy = false;
  late DateTime _startTime;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      debugPrint('Camera/ML Kit not supported on this platform');
      return;
    }
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

    _cameraController = CameraController(
      cameras[0],
      ResolutionPreset.medium,
      enableAudio: false,
    );

    await _cameraController!.initialize();

    final options = ObjectDetectorOptions(
      mode: DetectionMode.stream,
      classifyObjects: true,
      multipleObjects: false,
    );
    _objectDetector = ObjectDetector(options: options);

    _cameraController!.startImageStream(_processCameraImage);

    if (mounted) setState(() {});
  }

  void _processCameraImage(CameraImage image) async {
    if (_isBusy || _objectDetector == null) return;
    if (!Platform.isAndroid && !Platform.isIOS) return;
    _isBusy = true;


    try {
      final WriteBuffer allBytes = WriteBuffer();
      for (final Plane plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();

      final Size imageSize = Size(
        image.width.toDouble(),
        image.height.toDouble(),
      );
      final camera = (await availableCameras())[0];
      final sensorOrientation = camera.sensorOrientation;
      InputImageRotation? rotation;
      if (Platform.isAndroid) {
        var rotationValue = sensorOrientation;
        switch (rotationValue) {
          case 0:
            rotation = InputImageRotation.rotation0deg;
            break;
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
      rotation ??= InputImageRotation.rotation0deg;

      final inputImageFormat =
          InputImageFormatValue.fromRawValue(image.format.raw) ??
          InputImageFormat.nv21;

      final inputImage = InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: imageSize,
          rotation: rotation,
          format: inputImageFormat,
          bytesPerRow: image.planes[0].bytesPerRow,
        ),
      );

      final objects = await _objectDetector!.processImage(inputImage);

      for (final DetectedObject object in objects) {
        for (final Label label in object.labels) {
          if (mounted) {
            final currentState = context.read<ChallengeBloc>().state;
            if (currentState is ObjectDetectionInProgress) {
              if (label.text.toLowerCase().contains(
                currentState.targetObject.toLowerCase(),
              )) {
                context.read<ChallengeBloc>().add(ObjectDetected(label.text));
                _cameraController?.stopImageStream();
                break;
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error processing image: $e');
    } finally {
      _isBusy = false;
    }
  }

  Future<void> _saveCompletionLog(bool success) async {
    final repository = context.read<AlarmListBloc>().repository;
    final timeTaken = DateTime.now().difference(_startTime).inSeconds;

    await repository.saveLog(
      LogEntity(
        alarmId: widget.alarmId,
        timestamp: DateTime.now(),
        success: success,
        timeTakenSeconds: timeTaken,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(title: const Text('Find the Object')),
        body: BlocConsumer<ChallengeBloc, ChallengeState>(
          listener: (context, state) {
            if (state is ChallengeCompleted) {
              NotificationService.cancel(widget.alarmId.hashCode);
              context.read<AlarmRingBloc>().add(StopRinging());
              _saveCompletionLog(true);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Well done! You are fully awake.'),
                ),
              );
              context.go('/');
            }
          },
          builder: (context, state) {
            if (state is ObjectDetectionInProgress) {
              return Stack(
                children: [
                  if (_cameraController != null &&
                      _cameraController!.value.isInitialized)
                    CameraPreview(_cameraController!)
                  else
                    const Center(child: CircularProgressIndicator()),
                  Align(
                    alignment: Alignment.topCenter,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      color: Colors.black54,
                      width: double.infinity,
                      child: Text(
                        'SCAN ${state.targetObject.toUpperCase()} TO STOP ALARM',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 50),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'GO TO THE BATHROOM',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 30,
                                vertical: 15,
                              ),
                            ),
                            onPressed: () {
                              context.read<ChallengeBloc>().add(
                                ObjectDetected(state.targetObject),
                              );
                            },
                            icon: const Icon(Icons.check_circle),
                            label: const Text('CONFIRM OBJECT (DEBUG)'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }
            return const Center(child: CircularProgressIndicator());
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _objectDetector?.close();
    super.dispose();
  }
}
