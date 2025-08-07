import 'package:equatable/equatable.dart';

/// Category entity representing book categories/genres
/// 
/// Contains category information with support for hierarchical
/// organization through parent-child relationships.
class Category extends Equatable {
  final String id;
  final String name;
  final String? description;
  final String? parentId;
  final DateTime createdAt;

  const Category({
    required this.id,
    required this.name,
    this.description,
    this.parentId,
    required this.createdAt,
  });

  /// Create a copy of this category with updated fields
  Category copyWith({
    String? id,
    String? name,
    String? description,
    String? parentId,
    DateTime? createdAt,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      parentId: parentId ?? this.parentId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Check if this is a root category (no parent)
  bool get isRoot => parentId == null;

  /// Check if this is a child category (has parent)
  bool get isChild => parentId != null;

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        parentId,
        createdAt,
      ];

  @override
  String toString() => 'Category(id: $id, name: $name)';
}
