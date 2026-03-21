import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'models/lsp_message.dart';
import 'models/protocol_generated.dart';

class LSPClient {
  Process? _process;
  final _requestCompleters = <int, Completer<dynamic>>{};
  int _nextRequestId = 1;
  StringBuffer _buffer = StringBuffer();

  // Streams for notifications
  final _diagnosticsController =
      StreamController<PublishDiagnosticsParams>.broadcast();
  Stream<PublishDiagnosticsParams> get diagnostics =>
      _diagnosticsController.stream;

  Future<void> start() async {
    if (_process != null) return;

    try {
      _process = await Process.start('dart', ['language-server']);

      _process!.stdout.transform(utf8.decoder).listen((data) {
        _buffer.write(data);
        _processBuffer();
      });

      _process!.stderr.transform(utf8.decoder).listen((data) {
        developer.log(data, name: 'LSPClient.stderr');
      });
    } catch (e) {
      developer.log('Failed to start LSP', name: 'LSPClient', error: e);
      rethrow;
    }
  }

  Future<void> stop() async {
    _process?.kill();
    _process = null;
    _requestCompleters.clear();
    _buffer.clear();
  }

  Future<dynamic> sendRequest(String method, dynamic params) async {
    final id = _nextRequestId++;
    final completer = Completer<dynamic>();
    _requestCompleters[id] = completer;

    final request = RequestMessage(id: id, method: method, params: params);
    _send(request.toJson());

    return completer.future;
  }

  void sendNotification(String method, dynamic params) {
    final notification = NotificationMessage(method: method, params: params);
    _send(notification.toJson());
  }

  void _send(Map<String, dynamic> json) {
    final jsonString = jsonEncode(json);
    final content = utf8.encode(jsonString);
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

      final lengthStr = content.substring(
        content.indexOf('Content-Length: ') + 16,
        content.indexOf('\r\n', content.indexOf('Content-Length: ')),
      );
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

      if (json.containsKey('id')) {
        // Response or Request
        final id = json['id'];
        if (json.containsKey('method')) {
          // Request from server (not supported yet)
        } else {
          // Response
          final completer = _requestCompleters.remove(id);
          if (completer != null) {
            if (json.containsKey('error')) {
              completer.completeError(ResponseError.fromJson(json['error']));
            } else {
              completer.complete(json['result']);
            }
          }
        }
      } else {
        // Notification
        final method = json['method'];
        final params = json['params'];

        if (method == 'textDocument/publishDiagnostics') {
          _diagnosticsController.add(PublishDiagnosticsParams.fromJson(params));
        }
      }
    } catch (e) {
      developer.log(
        'Error handling LSP message',
        name: 'LSPClient',
        error: e,
      );
    }
  }

  void dispose() {
    stop();
    _diagnosticsController.close();
  }
}
