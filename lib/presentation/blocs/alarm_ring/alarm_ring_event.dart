import 'package:equatable/equatable.dart';

abstract class AlarmRingEvent extends Equatable {
  const AlarmRingEvent();

  @override
  List<Object?> get props => [];
}

class StartRinging extends AlarmRingEvent {}

class ReduceVolume extends AlarmRingEvent {
  final double newVolume;

  const ReduceVolume(this.newVolume);

  @override
  List<Object?> get props => [newVolume];
}

class StopRinging extends AlarmRingEvent {}
