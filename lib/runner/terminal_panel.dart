import 'package:flutter/material.dart';
import 'package:xterm/xterm.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'process_service.dart';

class TerminalPanel extends ConsumerStatefulWidget {
  const TerminalPanel({super.key});

  @override
  ConsumerState<TerminalPanel> createState() => _TerminalPanelState();
}

class _TerminalPanelState extends ConsumerState<TerminalPanel> {
  late final Terminal _terminal;
  late final TerminalController _controller;

  @override
  void initState() {
    super.initState();
    _terminal = Terminal(
      maxLines: 10000,
    );
    _controller = TerminalController();
    
    _terminal.write('Welcome to Flutter IDE Terminal\r\n\$ ');
  }

  @override
  Widget build(BuildContext context) {
    // Listen to process output
    ref.listen(processOutputProvider, (previous, next) {
      next.whenData((data) {
        _terminal.write(data);
      });
    });

    return Container(
      color: Colors.black,
      child: TerminalView(
        _terminal,
        controller: _controller,
        autofocus: false,
        backgroundOpacity: 0,
      ),
    );
  }
}
