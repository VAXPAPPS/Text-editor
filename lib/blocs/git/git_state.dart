import 'package:equatable/equatable.dart';
import '../../services/git_service.dart';

abstract class GitState extends Equatable {
  const GitState();

  @override
  List<Object> get props => [];
}

class GitInitial extends GitState {}

class GitLoading extends GitState {}

class GitLoaded extends GitState {
  final List<GitFileStatus> changedFiles;
  final String projectPath;

  const GitLoaded({required this.changedFiles, required this.projectPath});

  @override
  List<Object> get props => [changedFiles, projectPath];
}

class GitError extends GitState {
  final String message;
  const GitError(this.message);
  @override
  List<Object> get props => [message];
}
