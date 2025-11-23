import 'package:equatable/equatable.dart';
import '../../lsp/models/protocol_generated.dart';

class AnalysisState extends Equatable {
  final List<Diagnostic> diagnostics;
  final List<CompletionItem> completionItems;
  final Hover? hover;

  const AnalysisState({
    this.diagnostics = const [],
    this.completionItems = const [],
    this.hover,
  });

  AnalysisState copyWith({
    List<Diagnostic>? diagnostics,
    List<CompletionItem>? completionItems,
    Hover? hover,
  }) {
    return AnalysisState(
      diagnostics: diagnostics ?? this.diagnostics,
      completionItems: completionItems ?? this.completionItems,
      hover: hover ?? this.hover,
    );
  }

  @override
  List<Object?> get props => [diagnostics, completionItems, hover];
}
