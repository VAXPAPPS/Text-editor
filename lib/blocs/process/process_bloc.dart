import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'process_event.dart';
import 'process_state.dart';

class ProcessBloc extends Bloc<ProcessEvent, ProcessState> {
  Process? _process;
  // ignore: close_sinks
  final _outputController = StreamController<String>.broadcast();

  Stream<String> get outputStream => _outputController.stream;

  ProcessBloc() : super(ProcessInitial()) {
    on<ProcessRun>(_onRun);
    on<ProcessHotReload>(_onHotReload);
    on<ProcessHotRestart>(_onHotRestart);
    on<ProcessStop>(_onStop);
  }

  Future<void> _onRun(ProcessRun event, Emitter<ProcessState> emit) async {
    if (_process != null) {
      _outputController.add('Error: App already running. Stop it first.\r\n');
      return;
    }

    try {
      _outputController.add(
        'Starting "flutter run -d linux" in ${event.projectPath}...\r\n',
      );
      emit(ProcessRunning());

      _process = await Process.start(
        'flutter',
        ['run', '-d', 'linux'],
        workingDirectory: event.projectPath,
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
        add(ProcessStop()); // Trigger state update
      });
    } catch (e) {
      _outputController.add('Failed to start process: $e\r\n');
      emit(ProcessStopped());
    }
  }

  void _onHotReload(ProcessHotReload event, Emitter<ProcessState> emit) {
    if (_process != null) {
      _outputController.add('Performing Hot Reload...\r\n');
      _process!.stdin.write('r');
    }
  }

  void _onHotRestart(ProcessHotRestart event, Emitter<ProcessState> emit) {
    if (_process != null) {
      _outputController.add('Performing Hot Restart...\r\n');
      _process!.stdin.write('R');
    }
  }

  void _onStop(ProcessStop event, Emitter<ProcessState> emit) {
    if (_process != null) {
      _outputController.add('Stopping app...\r\n');
      _process!.stdin.write('q');
      // _process!.kill();
    }
    emit(ProcessStopped());
  }

  @override
  Future<void> close() {
    _outputController.close();
    return super.close();
  }
}
