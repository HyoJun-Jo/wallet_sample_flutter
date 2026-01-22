import '../../domain/entities/bookmark.dart';

/// Bookmark data model
class BookmarkModel {
  final String title;
  final String url;
  final DateTime createdAt;

  const BookmarkModel({
    required this.title,
    required this.url,
    required this.createdAt,
  });

  factory BookmarkModel.fromJson(Map<String, dynamic> json) {
    return BookmarkModel(
      title: json['title'] as String,
      url: json['url'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'url': url,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory BookmarkModel.fromEntity(Bookmark entity) {
    return BookmarkModel(
      title: entity.title,
      url: entity.url,
      createdAt: entity.createdAt,
    );
  }

  Bookmark toEntity() {
    return Bookmark(
      title: title,
      url: url,
      createdAt: createdAt,
    );
  }
}
