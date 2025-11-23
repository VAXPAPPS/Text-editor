import 'package:equatable/equatable.dart';

abstract class ProcessEvent extends Equatable {
  const ProcessEvent();

  @override
  List<Object?> get props => [];
}

class ProcessRun extends ProcessEvent {
  final String projectPath;
  const ProcessRun(this.projectPath);

  @override
  List<Object?> get props => [projectPath];
}

class ProcessHotReload extends ProcessEvent {}

class ProcessHotRestart extends ProcessEvent {}

class ProcessStop extends ProcessEvent {}
