import 'dart:io';
import 'package:equatable/equatable.dart';

abstract class FileExplorerState extends Equatable {
  const FileExplorerState();

  @override
  List<Object?> get props => [];

  String? get projectPath => null;
}

class FileExplorerInitial extends FileExplorerState {}

class FileExplorerLoading extends FileExplorerState {}

class FileExplorerLoaded extends FileExplorerState {
  final String path;
  final List<FileSystemEntity> files;

  const FileExplorerLoaded(this.path, this.files);

  @override
  String? get projectPath => path;

  @override
  List<Object?> get props => [path, files];
}

class FileExplorerError extends FileExplorerState {
  final String message;

  const FileExplorerError(this.message);

  @override
  List<Object?> get props => [message];
}
