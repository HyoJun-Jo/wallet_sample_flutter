import '../../domain/entities/bookmark.dart';

/// Bookmark data model
class BookmarkModel extends Bookmark {
  const BookmarkModel({
    required super.title,
    required super.url,
    required super.createdAt,
  });

  /// Create from JSON map
  factory BookmarkModel.fromJson(Map<String, dynamic> json) {
    return BookmarkModel(
      title: json['title'] as String,
      url: json['url'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'url': url,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Create from Entity
  factory BookmarkModel.fromEntity(Bookmark entity) {
    return BookmarkModel(
      title: entity.title,
      url: entity.url,
      createdAt: entity.createdAt,
    );
  }
}
