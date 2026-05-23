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
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

class ScannerPage extends StatefulWidget {
  final String alarmId;
  const ScannerPage({super.key, required this.alarmId});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  final ImagePicker _picker = ImagePicker();
  late DateTime _startTime;
  XFile? _pickedFile;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
  }

  Future<void> _pickImage() async {
    try {
      final source = await _chooseSource();
      if (source == null) return;

      final file = await _picker.pickImage(
        source: source,
        imageQuality: 75, // reduce payload size
        maxWidth: 1024,
        maxHeight: 1024,
      );
      if (file == null) return;

      setState(() => _pickedFile = file);
    } catch (e) {
      debugPrint('Image pick error: $e');
    }
  }

  Future<ImageSource?> _chooseSource() async {
    // On desktop there's no camera — go straight to gallery
    final hasCamera = !kIsWeb && (Platform.isAndroid || Platform.isIOS);
    if (!hasCamera) return ImageSource.gallery;

    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Choose photo source',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _sourceButton(
                    icon: Icons.camera_alt_rounded,
                    label: 'Camera',
                    onTap: () => Navigator.pop(ctx, ImageSource.camera),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _sourceButton(
                    icon: Icons.photo_library_rounded,
                    label: 'Gallery',
                    onTap: () => Navigator.pop(ctx, ImageSource.gallery),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _sourceButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Colors.deepPurple.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.deepPurple.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.deepPurpleAccent, size: 32),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ),
  );

  Future<void> _submitImage(ImageVerificationInProgress state) async {
    if (_pickedFile == null) return;
    final bytes = await _pickedFile!.readAsBytes();
    final mime = _pickedFile!.path.toLowerCase().endsWith('.png')
        ? 'image/png'
        : 'image/jpeg';

    if (!mounted) return;
    context.read<ChallengeBloc>().add(
      SubmitImageForVerification(
        imageBytes: bytes,
        mimeType: mime,
        imagePath: _pickedFile!.path,
      ),
    );
    setState(() => _pickedFile = null); // clear preview during verification
  }

  Future<void> _onChallengeComplete() async {
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
            if (state is ImageVerificationInProgress) {
              return _buildUI(state);
            }
            // Transient success flash from math page
            return const Center(child: CircularProgressIndicator());
          },
        ),
      ),
    );
  }

  Widget _buildUI(ImageVerificationInProgress state) {
    return SafeArea(
      child: Column(
        children: [
          // ── Step indicator ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: _stepRow(step: 2),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  // ── Target object card ────────────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 18,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: Colors.deepPurple.withValues(alpha: 0.6),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'PHOTOGRAPH THIS OBJECT',
                          style: TextStyle(
                            color: Colors.white38,
                            fontSize: 11,
                            letterSpacing: 3,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          state.targetObject.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Take a clear photo of a ${state.targetObject} to stop the alarm',
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Error message ─────────────────────────────────────
                  if (state.errorMessage != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.red.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.redAccent,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              state.errorMessage!,
                              style: const TextStyle(
                                color: Colors.redAccent,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // ── Image preview ─────────────────────────────────────
                  if (_pickedFile != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.file(
                        File(_pickedFile!.path),
                        height: 260,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: state.isVerifying
                          ? null
                          : () => setState(() => _pickedFile = null),
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Retake photo'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white38,
                      ),
                    ),
                  ] else ...[
                    // Upload placeholder
                    GestureDetector(
                      onTap: state.isVerifying ? null : _pickImage,
                      child: Container(
                        height: 220,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.deepPurple.withValues(alpha: 0.3),
                            width: 1.5,
                            strokeAlign: BorderSide.strokeAlignInside,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_a_photo_rounded,
                              size: 52,
                              color: Colors.deepPurple.withValues(alpha: 0.6),
                            ),
                            const SizedBox(height: 14),
                            const Text(
                              'Tap to take / upload photo',
                              style: TextStyle(
                                color: Colors.white38,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // ── Bottom action buttons ───────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: state.isVerifying
                ? _buildVerifyingIndicator(state.targetObject)
                : Column(
                    children: [
                      if (_pickedFile != null)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurple,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 8,
                            ),
                            onPressed: () => _submitImage(state),
                            icon: const Icon(Icons.send_rounded),
                            label: const Text(
                              'VERIFY IMAGE',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                        )
                      else
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurple,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 8,
                            ),
                            onPressed: _pickImage,
                            icon: const Icon(Icons.camera_alt_rounded),
                            label: const Text(
                              'TAKE PHOTO',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerifyingIndicator(String target) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.deepPurple.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.deepPurple.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: Colors.deepPurpleAccent,
            ),
          ),
          const SizedBox(width: 14),
          Text(
            'AI is checking for $target...',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _stepRow({required int step}) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      _stepDot(1, 'Math', step == 1),
      _stepLine(),
      _stepDot(2, 'Photo', step == 2),
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
}
