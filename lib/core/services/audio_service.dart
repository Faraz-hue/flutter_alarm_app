import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:io';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final AudioPlayer _player = AudioPlayer();
  Timer? _volumeTimer;
  double _currentVolume = 0.1;
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;
    
    try {
      // Set audio session category for alarms
      if (Platform.isAndroid || Platform.isIOS || Platform.isWindows) {
        await _player.setAsset('assets/sounds/LOUDEST ALARM SOUND!!  FOR 20 MINS.mp3');
        await _player.setLoopMode(LoopMode.one);
        _isInitialized = true;
        debugPrint('✅ Audio initialized successfully');
      } else {
        debugPrint('⚠️ Audio not supported on this platform');
      }
    } catch (e) {
      debugPrint('❌ Error initializing audio: $e');
    }
  }

  Future<void> playAlarm() async {
    try {
      debugPrint('🔊 Attempting to play alarm...');
      
      _currentVolume = 0.1;
      await _player.setVolume(_currentVolume);
      
      // Re-load asset to ensure it's fresh
      await _player.setAsset('assets/sounds/LOUDEST ALARM SOUND!!  FOR 20 MINS.mp3');
      await _player.setLoopMode(LoopMode.one);
      
      await _player.play();
      debugPrint('✅ Alarm playing at volume: $_currentVolume');

      // Start gradual volume increase
      _startVolumeIncrease();
    } catch (e) {
      debugPrint('❌ Error playing alarm: $e');
    }
  }

  void _startVolumeIncrease() {
    _volumeTimer?.cancel();
    _volumeTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_currentVolume < 1.0) {
        _currentVolume += 0.1;
        if (_currentVolume > 1.0) _currentVolume = 1.0;
        _player.setVolume(_currentVolume);
        debugPrint('🔊 Volume increased to: $_currentVolume');
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> stopAlarm() async {
    debugPrint('🛑 Stopping alarm');
    _volumeTimer?.cancel();
    await _player.stop();
  }

  Future<void> setVolume(double volume) async {
    _currentVolume = volume;
    await _player.setVolume(_currentVolume);
    debugPrint('🔊 Volume set to: $_currentVolume');
  }

  void dispose() {
    _volumeTimer?.cancel();
    _player.dispose();
  }
}

