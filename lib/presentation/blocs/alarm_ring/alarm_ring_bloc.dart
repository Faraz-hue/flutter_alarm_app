import 'package:alarm_app/core/services/audio_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'alarm_ring_event.dart';
import 'alarm_ring_state.dart';

class AlarmRingBloc extends Bloc<AlarmRingEvent, AlarmRingState> {
  final AudioService _audioService = AudioService();

  AlarmRingBloc() : super(const AlarmRinging(0.1)) {
    on<StartRinging>(_onStartRinging);
    on<ReduceVolume>(_onReduceVolume);
    on<StopRinging>(_onStopRinging);
  }

  Future<void> _onStartRinging(StartRinging event, Emitter<AlarmRingState> emit) async {
    await _audioService.playAlarm();
    emit(const AlarmRinging(0.1));
  }

  Future<void> _onReduceVolume(ReduceVolume event, Emitter<AlarmRingState> emit) async {
    if (state is AlarmRinging) {
      await _audioService.setVolume(event.newVolume);
      emit(AlarmRinging(event.newVolume));
    }
  }

  Future<void> _onStopRinging(StopRinging event, Emitter<AlarmRingState> emit) async {
    await _audioService.stopAlarm();
    emit(const AlarmDismissed());
  }
}
