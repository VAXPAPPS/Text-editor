// Simplified LSP types for our needs

class InitializeParams {
  final int processId;
  final String? rootUri;
  final Map<String, dynamic> capabilities;

  InitializeParams({
    required this.processId,
    this.rootUri,
    this.capabilities = const {},
  });

  Map<String, dynamic> toJson() => {
    'processId': processId,
    'rootUri': rootUri,
    'capabilities': capabilities,
  };
}

class TextDocumentItem {
  final String uri;
  final String languageId;
  final int version;
  final String text;

  TextDocumentItem({
    required this.uri,
    required this.languageId,
    required this.version,
    required this.text,
  });

  Map<String, dynamic> toJson() => {
    'uri': uri,
    'languageId': languageId,
    'version': version,
    'text': text,
  };
}

class VersionedTextDocumentIdentifier {
  final String uri;
  final int version;

  VersionedTextDocumentIdentifier({required this.uri, required this.version});

  Map<String, dynamic> toJson() => {'uri': uri, 'version': version};
}

class TextDocumentContentChangeEvent {
  final String text;

  TextDocumentContentChangeEvent({required this.text});

  Map<String, dynamic> toJson() => {'text': text};
}

class DidChangeTextDocumentParams {
  final VersionedTextDocumentIdentifier textDocument;
  final List<TextDocumentContentChangeEvent> contentChanges;

  DidChangeTextDocumentParams({
    required this.textDocument,
    required this.contentChanges,
  });

  Map<String, dynamic> toJson() => {
    'textDocument': textDocument.toJson(),
    'contentChanges': contentChanges.map((c) => c.toJson()).toList(),
  };
}

class Position {
  final int line;
  final int character;

  Position({required this.line, required this.character});

  factory Position.fromJson(Map<String, dynamic> json) {
    return Position(
      line: json['line'] as int,
      character: json['character'] as int,
    );
  }

  Map<String, dynamic> toJson() => {'line': line, 'character': character};
}

class Range {
  final Position start;
  final Position end;

  Range({required this.start, required this.end});

  factory Range.fromJson(Map<String, dynamic> json) {
    return Range(
      start: Position.fromJson(json['start']),
      end: Position.fromJson(json['end']),
    );
  }

  Map<String, dynamic> toJson() => {
    'start': start.toJson(),
    'end': end.toJson(),
  };
}

class Diagnostic {
  final Range range;
  final int? severity;
  final String message;
  final String? source;

  Diagnostic({
    required this.range,
    this.severity,
    required this.message,
    this.source,
  });

  factory Diagnostic.fromJson(Map<String, dynamic> json) {
    return Diagnostic(
      range: Range.fromJson(json['range']),
      severity: json['severity'] as int?,
      message: json['message'] as String,
      source: json['source'] as String?,
    );
  }
}

class PublishDiagnosticsParams {
  final String uri;
  final List<Diagnostic> diagnostics;

  PublishDiagnosticsParams({required this.uri, required this.diagnostics});

  factory PublishDiagnosticsParams.fromJson(Map<String, dynamic> json) {
    return PublishDiagnosticsParams(
      uri: json['uri'] as String,
      diagnostics: (json['diagnostics'] as List)
          .map((d) => Diagnostic.fromJson(d))
          .toList(),
    );
  }
}

class CompletionParams {
  final TextDocumentIdentifier textDocument;
  final Position position;

  CompletionParams({required this.textDocument, required this.position});

  Map<String, dynamic> toJson() => {
    'textDocument': textDocument.toJson(),
    'position': position.toJson(),
  };
}

class TextDocumentIdentifier {
  final String uri;

  TextDocumentIdentifier({required this.uri});

  Map<String, dynamic> toJson() => {'uri': uri};
}

class CompletionList {
  final bool isIncomplete;
  final List<CompletionItem> items;

  CompletionList({required this.isIncomplete, required this.items});

  factory CompletionList.fromJson(Map<String, dynamic> json) {
    return CompletionList(
      isIncomplete: json['isIncomplete'] as bool,
      items: (json['items'] as List)
          .map((item) => CompletionItem.fromJson(item))
          .toList(),
    );
  }
}

class CompletionItem {
  final String label;
  final int? kind;
  final String? detail;
  final String? documentation;
  final String? insertText;
  final int? insertTextFormat; // 1 = PlainText, 2 = Snippet

  CompletionItem({
    required this.label,
    this.kind,
    this.detail,
    this.documentation,
    this.insertText,
    this.insertTextFormat,
  });

  factory CompletionItem.fromJson(Map<String, dynamic> json) {
    return CompletionItem(
      label: json['label'] as String,
      kind: json['kind'] as int?,
      detail: json['detail'] as String?,
      documentation: json['documentation'] is Map
          ? json['documentation']['value']
          : json['documentation'] as String?,
      insertText: json['insertText'] as String?,
      insertTextFormat: json['insertTextFormat'] as int?,
    );
  }
}

class HoverParams {
  final TextDocumentIdentifier textDocument;
  final Position position;

  HoverParams({required this.textDocument, required this.position});

  Map<String, dynamic> toJson() => {
    'textDocument': textDocument.toJson(),
    'position': position.toJson(),
  };
}

class Hover {
  final List<String> contents;
  final Range? range;

  Hover({required this.contents, this.range});

  factory Hover.fromJson(Map<String, dynamic> json) {
    List<String> contentsList = [];
    final contents = json['contents'];

    if (contents is String) {
      contentsList.add(contents);
    } else if (contents is List) {
      contentsList = contents.map((e) => e.toString()).toList();
    } else if (contents is Map) {
      // MarkupContent
      contentsList.add(contents['value'] as String);
    }

    return Hover(
      contents: contentsList,
      range: json['range'] != null ? Range.fromJson(json['range']) : null,
    );
  }
}
