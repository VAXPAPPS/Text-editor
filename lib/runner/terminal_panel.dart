import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xterm/xterm.dart';
import '../blocs/process/process_bloc.dart';

class TerminalPanel extends StatefulWidget {
  const TerminalPanel({super.key});

  @override
  State<TerminalPanel> createState() => _TerminalPanelState();
}

class _TerminalPanelState extends State<TerminalPanel> {
  late final Terminal _terminal;
  late final TerminalController _controller;
  StreamSubscription? _outputSubscription;

  @override
  void initState() {
    super.initState();
    _terminal = Terminal(maxLines: 10000);
    _controller = TerminalController();

    _terminal.write('Welcome to Flutter IDE Terminal\r\n\$ ');

    // Listen to process output stream
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _outputSubscription = context.read<ProcessBloc>().outputStream.listen((
        data,
      ) {
        _terminal.write(data);
      });
    });
  }

  @override
  void dispose() {
    _outputSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color.fromARGB(68, 0, 0, 0),
      child: TerminalView(
        _terminal,
        controller: _controller,
        autofocus: false,
        backgroundOpacity: 0,
      ),
    );
  }
}
