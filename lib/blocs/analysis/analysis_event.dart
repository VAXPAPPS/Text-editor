import 'package:equatable/equatable.dart';

abstract class AnalysisEvent extends Equatable {
  const AnalysisEvent();

  @override
  List<Object?> get props => [];
}

class AnalysisStart extends AnalysisEvent {}

class AnalysisFileOpened extends AnalysisEvent {
  final String path;
  final String content;
  const AnalysisFileOpened(this.path, this.content);

  @override
  List<Object?> get props => [path, content];
}

class AnalysisFileChanged extends AnalysisEvent {
  final String path;
  final String content;
  const AnalysisFileChanged(this.path, this.content);

  @override
  List<Object?> get props => [path, content];
}

class AnalysisDiagnosticsUpdated extends AnalysisEvent {
  final List<dynamic>
  diagnostics; // Using dynamic to avoid circular dependency issues for now, but ideally should be Diagnostic
  const AnalysisDiagnosticsUpdated(this.diagnostics);

  @override
  List<Object?> get props => [diagnostics];
}

class AnalysisCompletionRequested extends AnalysisEvent {
  final String path;
  final int line;
  final int character;
  const AnalysisCompletionRequested(this.path, this.line, this.character);

  @override
  List<Object?> get props => [path, line, character];
}

class AnalysisHoverRequested extends AnalysisEvent {
  final String path;
  final int line;
  final int character;
  const AnalysisHoverRequested(this.path, this.line, this.character);

  @override
  List<Object?> get props => [path, line, character];
}
