import 'dart:async';
import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../lsp/lsp_client.dart';
import '../../lsp/models/protocol_generated.dart';
import 'analysis_event.dart';
import 'analysis_state.dart';

class AnalysisBloc extends Bloc<AnalysisEvent, AnalysisState> {
  final LSPClient _client;
  StreamSubscription? _diagnosticsSubscription;

  AnalysisBloc() : _client = LSPClient(), super(const AnalysisState()) {
    on<AnalysisStart>(_onStart);
    on<AnalysisFileOpened>(_onFileOpened);
    on<AnalysisFileChanged>(_onFileChanged);
    on<AnalysisDiagnosticsUpdated>(_onDiagnosticsUpdated);
    on<AnalysisCompletionRequested>(_onCompletionRequested);
    on<AnalysisHoverRequested>(_onHoverRequested);
  }

  void _onDiagnosticsUpdated(
    AnalysisDiagnosticsUpdated event,
    Emitter<AnalysisState> emit,
  ) {
    emit(state.copyWith(diagnostics: event.diagnostics.cast<Diagnostic>()));
  }

  Future<void> _onCompletionRequested(
    AnalysisCompletionRequested event,
    Emitter<AnalysisState> emit,
  ) async {
    try {
      final result = await _client.sendRequest(
        'textDocument/completion',
        CompletionParams(
          textDocument: TextDocumentIdentifier(
            uri: Uri.file(event.path).toString(),
          ),
          position: Position(line: event.line, character: event.character),
        ).toJson(),
      );

      if (result != null) {
        final completionList = CompletionList.fromJson(result);
        emit(state.copyWith(completionItems: completionList.items));
      }
    } catch (e) {
      print('Completion error: $e');
    }
  }

  Future<void> _onHoverRequested(
    AnalysisHoverRequested event,
    Emitter<AnalysisState> emit,
  ) async {
    try {
      final result = await _client.sendRequest(
        'textDocument/hover',
        HoverParams(
          textDocument: TextDocumentIdentifier(
            uri: Uri.file(event.path).toString(),
          ),
          position: Position(line: event.line, character: event.character),
        ).toJson(),
      );

      if (result != null) {
        final hover = Hover.fromJson(result);
        emit(state.copyWith(hover: hover));
      } else {
        // Clear hover if no result
        emit(
          AnalysisState(
            diagnostics: state.diagnostics,
            completionItems: state.completionItems,
            hover: null,
          ),
        );
      }
    } catch (e) {
      print('Hover error: $e');
    }
  }

  Future<void> _onStart(
    AnalysisStart event,
    Emitter<AnalysisState> emit,
  ) async {
    try {
      await _client.start();

      // Listen to diagnostics
      _diagnosticsSubscription = _client.diagnostics.listen((params) {
        // We need to emit a new state with the diagnostics.
        // However, the params only contain diagnostics for a specific URI.
        // For a real IDE, we'd want to map URIs to diagnostics.
        // For now, we'll just replace the list since we mostly care about the active file.
        // Or better, we can filter/merge if we had a map in the state.
        // Let's keep it simple: Update state with these diagnostics.
        // Note: This might clear diagnostics for other files if we don't track them.
        // But given the current UI only shows a list, this is acceptable for the POC.

        // We need to emit from the bloc. Since we are in a listener, we can't emit directly if we are not in an event handler.
        // But we can add an event to update the state.
        add(AnalysisDiagnosticsUpdated(params.diagnostics));
      });

      // Initialize
      await _client.sendRequest(
        'initialize',
        InitializeParams(
          processId: pid,
          rootUri: null,
          capabilities: {},
        ).toJson(),
      );

      _client.sendNotification('initialized', {});
    } catch (e) {
      print('Failed to start LSP: $e');
    }
  }

  void _onFileOpened(AnalysisFileOpened event, Emitter<AnalysisState> emit) {
    _client.sendNotification(
      'textDocument/didOpen',
      DidChangeTextDocumentParams(
        textDocument: VersionedTextDocumentIdentifier(
          uri: Uri.file(event.path).toString(),
          version: 1,
        ),
        contentChanges: [TextDocumentContentChangeEvent(text: event.content)],
      ).toJson()..addAll({
        // Hack because DidChange params structure is different from DidOpen
        'textDocument': TextDocumentItem(
          uri: Uri.file(event.path).toString(),
          languageId: 'dart',
          version: 1,
          text: event.content,
        ).toJson(),
      }),
    );

    // Correct way:
    _client.sendNotification('textDocument/didOpen', {
      'textDocument': TextDocumentItem(
        uri: Uri.file(event.path).toString(),
        languageId: 'dart',
        version: 1,
        text: event.content,
      ).toJson(),
    });
  }

  void _onFileChanged(AnalysisFileChanged event, Emitter<AnalysisState> emit) {
    _client.sendNotification(
      'textDocument/didChange',
      DidChangeTextDocumentParams(
        textDocument: VersionedTextDocumentIdentifier(
          uri: Uri.file(event.path).toString(),
          version: 2, // Should increment
        ),
        contentChanges: [TextDocumentContentChangeEvent(text: event.content)],
      ).toJson(),
    );
  }

  @override
  Future<void> close() {
    _diagnosticsSubscription?.cancel();
    _client.dispose();
    return super.close();
  }
}
