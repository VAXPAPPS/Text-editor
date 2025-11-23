import 'package:equatable/equatable.dart';

class SearchResult extends Equatable {
  final String filePath;
  final int lineNumber;
  final String lineContent;
  final int index;

  const SearchResult({
    required this.filePath,
    required this.lineNumber,
    required this.lineContent,
    required this.index,
  });

  @override
  List<Object> get props => [filePath, lineNumber, lineContent, index];
}

abstract class SearchState extends Equatable {
  const SearchState();

  @override
  List<Object> get props => [];
}

class SearchInitial extends SearchState {}

class SearchLoading extends SearchState {}

class SearchLoaded extends SearchState {
  final List<SearchResult> results;
  final String query;

  const SearchLoaded(this.results, this.query);

  @override
  List<Object> get props => [results, query];
}

class SearchError extends SearchState {
  final String message;

  const SearchError(this.message);

  @override
  List<Object> get props => [message];
}
