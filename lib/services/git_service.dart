import 'dart:io';
import 'package:path/path.dart' as p;

class GitService {
  Future<bool> isGitRepo(String projectPath) async {
    final gitDir = Directory(p.join(projectPath, '.git'));
    return await gitDir.exists();
  }

  Future<void> init(String projectPath) async {
    await Process.run('git', ['init'], workingDirectory: projectPath);
  }

  Future<List<GitFileStatus>> getStatus(String projectPath) async {
    final result = await Process.run('git', [
      'status',
      '--porcelain',
    ], workingDirectory: projectPath);

    if (result.exitCode != 0) {
      throw Exception('Failed to get git status: ${result.stderr}');
    }

    final lines = (result.stdout as String).split('\n');
    final statuses = <GitFileStatus>[];

    for (var line in lines) {
      if (line.trim().isEmpty) continue;

      // XY Path
      // X: Index status, Y: Work tree status
      final x = line.length > 0 ? line[0] : ' ';
      final y = line.length > 1 ? line[1] : ' ';
      final path = line.substring(3).trim();

      statuses.add(
        GitFileStatus(path: path, indexStatus: x, workTreeStatus: y),
      );
    }

    return statuses;
  }

  Future<void> stageFile(String projectPath, String filePath) async {
    await Process.run('git', ['add', filePath], workingDirectory: projectPath);
  }

  Future<void> unstageFile(String projectPath, String filePath) async {
    await Process.run('git', [
      'reset',
      'HEAD',
      filePath,
    ], workingDirectory: projectPath);
  }

  Future<void> commit(String projectPath, String message) async {
    await Process.run('git', [
      'commit',
      '-m',
      message,
    ], workingDirectory: projectPath);
  }
}

class GitFileStatus {
  final String path;
  final String indexStatus; // 'M', 'A', 'D', etc.
  final String workTreeStatus;

  GitFileStatus({
    required this.path,
    required this.indexStatus,
    required this.workTreeStatus,
  });

  bool get isStaged => indexStatus != ' ' && indexStatus != '?';
  bool get isModified => workTreeStatus != ' ';
  bool get isUntracked => indexStatus == '?' && workTreeStatus == '?';
}
