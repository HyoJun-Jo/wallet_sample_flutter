import 'package:equatable/equatable.dart';

/// Bookmark entity
class Bookmark extends Equatable {
  final String title;
  final String url;
  final DateTime createdAt;

  const Bookmark({
    required this.title,
    required this.url,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [title, url, createdAt];
}
