import 'package:flutter_bloc/flutter_bloc.dart';
import 'git_event.dart';
import 'git_state.dart';
import '../../services/git_service.dart';

class GitBloc extends Bloc<GitEvent, GitState> {
  final GitService _gitService;
  String? _projectPath;

  GitBloc(this._gitService) : super(GitInitial()) {
    on<GitStarted>(_onStarted);
    on<GitRefresh>(_onRefresh);
    on<GitStageFile>(_onStageFile);
    on<GitUnstageFile>(_onUnstageFile);
    on<GitCommit>(_onCommit);
  }

  Future<void> _onStarted(GitStarted event, Emitter<GitState> emit) async {
    _projectPath = event.projectPath;
    await _loadStatus(emit);
  }

  Future<void> _onRefresh(GitRefresh event, Emitter<GitState> emit) async {
    await _loadStatus(emit);
  }

  Future<void> _onStageFile(GitStageFile event, Emitter<GitState> emit) async {
    if (_projectPath == null) return;
    try {
      await _gitService.stageFile(_projectPath!, event.filePath);
      add(GitRefresh());
    } catch (e) {
      emit(GitError(e.toString()));
    }
  }

  Future<void> _onUnstageFile(
    GitUnstageFile event,
    Emitter<GitState> emit,
  ) async {
    if (_projectPath == null) return;
    try {
      await _gitService.unstageFile(_projectPath!, event.filePath);
      add(GitRefresh());
    } catch (e) {
      emit(GitError(e.toString()));
    }
  }

  Future<void> _onCommit(GitCommit event, Emitter<GitState> emit) async {
    if (_projectPath == null) return;
    try {
      await _gitService.commit(_projectPath!, event.message);
      add(GitRefresh());
    } catch (e) {
      emit(GitError(e.toString()));
    }
  }

  Future<void> _loadStatus(Emitter<GitState> emit) async {
    if (_projectPath == null) return;
    emit(GitLoading());
    try {
      final isRepo = await _gitService.isGitRepo(_projectPath!);
      if (!isRepo) {
        // Not a git repo, maybe init? For now just show empty or error
        // Or we could have a specific state for "NotGitRepo"
        emit(GitError('Not a git repository'));
        return;
      }

      final status = await _gitService.getStatus(_projectPath!);
      emit(GitLoaded(changedFiles: status, projectPath: _projectPath!));
    } catch (e) {
      emit(GitError(e.toString()));
    }
  }
}
