import 'package:equatable/equatable.dart';

abstract class GitEvent extends Equatable {
  const GitEvent();

  @override
  List<Object> get props => [];
}

class GitStarted extends GitEvent {
  final String projectPath;
  const GitStarted(this.projectPath);
  @override
  List<Object> get props => [projectPath];
}

class GitRefresh extends GitEvent {}

class GitStageFile extends GitEvent {
  final String filePath;
  const GitStageFile(this.filePath);
  @override
  List<Object> get props => [filePath];
}

class GitUnstageFile extends GitEvent {
  final String filePath;
  const GitUnstageFile(this.filePath);
  @override
  List<Object> get props => [filePath];
}

class GitCommit extends GitEvent {
  final String message;
  const GitCommit(this.message);
  @override
  List<Object> get props => [message];
}
