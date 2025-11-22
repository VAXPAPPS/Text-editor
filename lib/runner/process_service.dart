import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers.dart';

final processServiceProvider = Provider((ref) => ProcessService(ref));

final processOutputProvider = StreamProvider<String>((ref) {
  final service = ref.watch(processServiceProvider);
  return service.outputStream;
});

class ProcessService {
  final Ref _ref;
  Process? _process;
  // ignore: close_sinks
  final _outputController = StreamController<String>.broadcast();

  ProcessService(this._ref);

  Stream<String> get outputStream => _outputController.stream;

  Future<void> runFlutterApp() async {
    final projectPath = _ref.read(projectPathProvider);
    if (projectPath == null) {
      _outputController.add('Error: No project open.\r\n');
      return;
    }

    if (_process != null) {
      _outputController.add('Error: App already running. Stop it first.\r\n');
      return;
    }

    try {
      _outputController.add('Starting "flutter run -d linux" in $projectPath...\r\n');
      
      _process = await Process.start(
        'flutter',
        ['run', '-d', 'linux'],
        workingDirectory: projectPath,
        runInShell: true,
      );

      _process!.stdout.transform(utf8.decoder).listen((data) {
        _outputController.add(data.replaceAll('\n', '\r\n'));
      });

      _process!.stderr.transform(utf8.decoder).listen((data) {
        _outputController.add(data.replaceAll('\n', '\r\n'));
      });

      _process!.exitCode.then((code) {
        _outputController.add('Process exited with code $code.\r\n');
        _process = null;
      });

    } catch (e) {
      _outputController.add('Failed to start process: $e\r\n');
    }
  }

  void hotReload() {
    if (_process != null) {
      _outputController.add('Performing Hot Reload...\r\n');
      _process!.stdin.write('r');
    }
  }

  void hotRestart() {
    if (_process != null) {
      _outputController.add('Performing Hot Restart...\r\n');
      _process!.stdin.write('R');
    }
  }

  void stop() {
    if (_process != null) {
      _outputController.add('Stopping app...\r\n');
      _process!.stdin.write('q');
      // _process!.kill(); // 'q' should exit gracefully
    }
  }
}
