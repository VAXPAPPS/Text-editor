import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/editor/editor_cubit.dart';
import '../blocs/editor/editor_state.dart';

class StatusBar extends StatelessWidget {
  const StatusBar({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EditorCubit, EditorState>(
      builder: (context, state) {
        final cursorLine = state.cursorLine;
        final cursorCol = state.cursorCol;

        return Container(
          height: 24,
          color: const Color(0xFF007ACC), // VS Code blue-ish
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              const Icon(Icons.code, size: 14, color: Colors.white),
              const SizedBox(width: 8),
              const Text(
                'Ready',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
              const Spacer(),
              Text(
                'Ln $cursorLine, Col $cursorCol',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
              const SizedBox(width: 16),
              const Text(
                'UTF-8',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
              const SizedBox(width: 16),
              const Text(
                'Dart',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ],
          ),
        );
      },
    );
  }
}
