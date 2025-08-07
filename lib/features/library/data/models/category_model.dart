import '../../domain/entities/category.dart';

/// Category data model for database mapping
/// 
/// Handles conversion between database records and Category entities
/// with proper serialization and deserialization logic.
class CategoryModel {
  final String id;
  final String name;
  final String? description;
  final String? parentId;
  final int createdAt;

  const CategoryModel({
    required this.id,
    required this.name,
    this.description,
    this.parentId,
    required this.createdAt,
  });

  /// Create CategoryModel from database map
  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      parentId: map['parent_id'] as String?,
      createdAt: map['created_at'] as int,
    );
  }

  /// Convert CategoryModel to database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'parent_id': parentId,
      'created_at': createdAt,
    };
  }

  /// Create CategoryModel from Category entity
  factory CategoryModel.fromEntity(Category category) {
    return CategoryModel(
      id: category.id,
      name: category.name,
      description: category.description,
      parentId: category.parentId,
      createdAt: category.createdAt.millisecondsSinceEpoch,
    );
  }

  /// Convert CategoryModel to Category entity
  Category toEntity() {
    return Category(
      id: id,
      name: name,
      description: description,
      parentId: parentId,
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdAt),
    );
  }

  @override
  String toString() => 'CategoryModel(id: $id, name: $name)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CategoryModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
