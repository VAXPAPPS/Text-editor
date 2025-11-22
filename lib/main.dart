import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:window_manager/window_manager.dart';
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
  runApp(const ProviderScope(child: FlutterIdeApp()));
}

class FlutterIdeApp extends StatelessWidget {
  const FlutterIdeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter IDE',
      debugShowCheckedModeBanner: false,
      // theme: ThemeData(
      //   brightness: Brightness.dark,
      //   colorScheme: ColorScheme.dark(
      //     primary: Colors.blue,
      //     surface: const Color.fromARGB(0, 30, 30, 30),
      //   ),
      //   textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
      //   useMaterial3: true,
      // ),
      home: const IDEShell(),
    );
  }
}
