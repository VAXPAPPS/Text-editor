import 'package:equatable/equatable.dart';

abstract class SearchEvent extends Equatable {
  const SearchEvent();

  @override
  List<Object> get props => [];
}

class SearchStarted extends SearchEvent {
  final String query;
  final String projectPath;

  const SearchStarted(this.query, this.projectPath);

  @override
  List<Object> get props => [query, projectPath];
}

class SearchCleared extends SearchEvent {}

class SearchReplaceAll extends SearchEvent {
  final String query;
  final String replacement;
  final String projectPath;

  const SearchReplaceAll(this.query, this.replacement, this.projectPath);

  @override
  List<Object> get props => [query, replacement, projectPath];
}
