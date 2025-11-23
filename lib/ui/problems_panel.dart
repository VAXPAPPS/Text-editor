import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/analysis/analysis_bloc.dart';
import '../blocs/analysis/analysis_state.dart';
import '../blocs/editor/editor_cubit.dart';

class ProblemsPanel extends StatelessWidget {
  const ProblemsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AnalysisBloc, AnalysisState>(
      builder: (context, state) {
        if (state.diagnostics.isEmpty) {
          return const Center(
            child: Text(
              'No problems found',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        return ListView.builder(
          itemCount: state.diagnostics.length,
          itemBuilder: (context, index) {
            final diagnostic = state.diagnostics[index];
            return ListTile(
              leading: Icon(
                diagnostic.severity == 1 ? Icons.error : Icons.warning,
                color: diagnostic.severity == 1 ? Colors.red : Colors.yellow,
                size: 16,
              ),
              title: Text(
                diagnostic.message,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                'Line ${diagnostic.range.start.line + 1}, Col ${diagnostic.range.start.character + 1}',
                style: const TextStyle(color: Colors.grey, fontSize: 11),
              ),
              dense: true,
              onTap: () {
                context.read<EditorCubit>().jumpToLine(
                  diagnostic.range.start.line + 1,
                );
              },
            );
          },
        );
      },
    );
  }
}
