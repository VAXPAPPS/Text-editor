import 'package:equatable/equatable.dart';

abstract class ProcessState extends Equatable {
  const ProcessState();

  @override
  List<Object?> get props => [];
}

class ProcessInitial extends ProcessState {}

class ProcessRunning extends ProcessState {}

class ProcessStopped extends ProcessState {}

class ProcessOutput extends ProcessState {
  final String output;
  const ProcessOutput(this.output);

  @override
  List<Object?> get props => [output];
}
