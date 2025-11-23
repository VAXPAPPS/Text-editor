import 'dart:io';
import 'package:flutter/material.dart';
import 'package:xterm/xterm.dart';

class InteractiveTerminal extends StatefulWidget {
  const InteractiveTerminal({super.key});

  @override
  State<InteractiveTerminal> createState() => _InteractiveTerminalState();
}

class _InteractiveTerminalState extends State<InteractiveTerminal> {
  late final Terminal terminal;
  late final TerminalController controller;
  Process? shell;

  @override
  void initState() {
    super.initState();
    terminal = Terminal(maxLines: 10000);
    controller = TerminalController();
    _startShell();
  }

  void _startShell() async {
    shell = await Process.start('bash', [
      '-i',
    ], workingDirectory: Directory.current.path);

    terminal.onOutput = (data) {
      shell?.stdin.add(data.codeUnits);
    };

    shell?.stdout.listen((data) {
      terminal.write(String.fromCharCodes(data));
    });

    shell?.stderr.listen((data) {
      terminal.write(String.fromCharCodes(data));
    });
  }

  @override
  void dispose() {
    shell?.kill();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color.fromARGB(68, 0, 0, 0),
      child: TerminalView(
        terminal,
        controller: controller,
        autofocus: true,
        backgroundOpacity: 0,
      ),
    );
  }
}
