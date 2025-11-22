import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final analysisServiceProvider = Provider((ref) => AnalysisService(ref));

class DiagnosticsNotifier extends Notifier<List<Diagnostic>> {
  @override
  List<Diagnostic> build() => [];
  void set(List<Diagnostic> diagnostics) => state = diagnostics;
}
final diagnosticsProvider = NotifierProvider<DiagnosticsNotifier, List<Diagnostic>>(DiagnosticsNotifier.new);

class Diagnostic {
  final int line;
  final String message;
  final String severity;
  const Diagnostic(this.line, this.message, this.severity);
}

class AnalysisService {
  final Ref _ref;
  Process? _process;
  StringBuffer _buffer = StringBuffer();

  AnalysisService(this._ref);

  Future<void> start() async {
    if (_process != null) return;

    try {
      print('Starting Dart Analysis Server...');
      _process = await Process.start(
        'dart',
        ['language-server'],
      );

      _process!.stdout.transform(utf8.decoder).listen((data) {
        _buffer.write(data);
        _processBuffer();
      });

      _process!.stderr.transform(utf8.decoder).listen((data) {
        print('LSP Stderr: $data');
      });

      // Send initialize request
      final initializeRequest = jsonEncode({
        'jsonrpc': '2.0',
        'id': 1,
        'method': 'initialize',
        'params': {
          'processId': pid,
          'rootUri': null,
          'capabilities': {},
        }
      });
      
      _send(initializeRequest);

    } catch (e) {
      print('Failed to start LSP: $e');
    }
  }

  void _send(String json) {
    final content = utf8.encode(json);
    final header = 'Content-Length: ${content.length}\r\n\r\n';
    _process?.stdin.write(header);
    _process?.stdin.add(content);
  }

  void _processBuffer() {
    while (true) {
      final content = _buffer.toString();
      if (!content.contains('Content-Length: ')) break;
      
      final headerEnd = content.indexOf('\r\n\r\n');
      if (headerEnd == -1) break;
      
      final lengthStr = content.substring(content.indexOf('Content-Length: ') + 16, content.indexOf('\r\n', content.indexOf('Content-Length: ')));
      final length = int.parse(lengthStr);
      
      if (content.length < headerEnd + 4 + length) break;
      
      final body = content.substring(headerEnd + 4, headerEnd + 4 + length);
      _handleMessage(body);
      
      _buffer = StringBuffer(content.substring(headerEnd + 4 + length));
    }
  }

  void _handleMessage(String body) {
    try {
      final Map<String, dynamic> json = jsonDecode(body);
      if (json['method'] == 'textDocument/publishDiagnostics') {
        final params = json['params'];
        final List<dynamic> diagnosticsJson = params['diagnostics'];
        final diagnostics = diagnosticsJson.map((d) {
          final range = d['range'];
          final start = range['start'];
          return Diagnostic(
            start['line'] + 1, // 1-based
            d['message'],
            d['severity'] == 1 ? 'Error' : 'Warning',
          );
        }).toList();
        
        _ref.read(diagnosticsProvider.notifier).set(diagnostics);
      }
    } catch (e) {
      print('Error parsing LSP message: $e');
    }
  }

  void didOpen(String path, String content) {
    final notification = jsonEncode({
      'jsonrpc': '2.0',
      'method': 'textDocument/didOpen',
      'params': {
        'textDocument': {
          'uri': Uri.file(path).toString(),
          'languageId': 'dart',
          'version': 1,
          'text': content,
        }
      }
    });
    _send(notification);
  }

  void didChange(String path, String content) {
    final notification = jsonEncode({
      'jsonrpc': '2.0',
      'method': 'textDocument/didChange',
      'params': {
        'textDocument': {
          'uri': Uri.file(path).toString(),
          'version': 2, // Increment in real app
        },
        'contentChanges': [
          {'text': content},
        ],
      }
    });
    _send(notification);
  }

  void stop() {
    _process?.kill();
    _process = null;
  }
}
