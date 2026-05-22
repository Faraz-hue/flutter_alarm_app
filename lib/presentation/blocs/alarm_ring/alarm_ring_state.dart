import 'package:equatable/equatable.dart';

abstract class AlarmRingState extends Equatable {
  final double volume;

  const AlarmRingState(this.volume);

  @override
  List<Object?> get props => [volume];
}

class AlarmRinging extends AlarmRingState {
  const AlarmRinging(super.volume);
}

class AlarmDismissed extends AlarmRingState {
  const AlarmDismissed() : super(0.0);
}
