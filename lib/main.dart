import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:window_manager/window_manager.dart';
import 'blocs/file_explorer/file_explorer_cubit.dart';
import 'blocs/editor_tabs/editor_tabs_cubit.dart';
import 'blocs/editor/editor_cubit.dart';
import 'blocs/process/process_bloc.dart';
import 'blocs/analysis/analysis_bloc.dart';
import 'blocs/search/search_bloc.dart';
import 'ui/ide_shell.dart';

Future<void> main() async {
  // Initialize Flutter bindings first to ensure the binary messenger is ready
  WidgetsFlutterBinding.ensureInitialized();


  // Initialize window manager for desktop controls
  await windowManager.ensureInitialized();

  WindowOptions windowOptions = const WindowOptions(
    size: Size(1000, 700),
    center: true,
    titleBarStyle: TitleBarStyle.hidden, // يخفي شريط مدير النوافذ
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });
  runApp(const FlutterIdeApp());
}

class FlutterIdeApp extends StatelessWidget {
  const FlutterIdeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => FileExplorerCubit()),
        BlocProvider(create: (_) => EditorTabsCubit()),
        BlocProvider(create: (_) => EditorCubit()),
        BlocProvider(create: (_) => ProcessBloc()),
        BlocProvider(create: (_) => AnalysisBloc()),
        BlocProvider(create: (_) => SearchBloc()),
      ],
      child: MaterialApp(
        title: 'Flutter IDE',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          colorScheme: ColorScheme.dark(
            primary: Colors.blue,
            surface: const Color.fromARGB(0, 30, 30, 30),
          ),
          textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
          useMaterial3: true,
        ),
        home: const IDEShell(),
      ),
    );
  }
}
