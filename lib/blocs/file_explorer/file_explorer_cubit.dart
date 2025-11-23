import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'file_explorer_state.dart';

class FileExplorerCubit extends Cubit<FileExplorerState> {
  FileExplorerCubit() : super(FileExplorerInitial());

  Future<void> openProject(String path) async {
    emit(FileExplorerLoading());
    try {
      final dir = Directory(path);
      if (!await dir.exists()) {
        emit(const FileExplorerError('Directory does not exist'));
        return;
      }

      final files = await dir.list(recursive: true).toList();
      emit(FileExplorerLoaded(path, files));
    } catch (e) {
      emit(FileExplorerError(e.toString()));
    }
  }

  Future<void> refresh() async {
    if (state is FileExplorerLoaded) {
      final currentPath = (state as FileExplorerLoaded).path;
      await openProject(currentPath);
    }
  }
}
