import '../../domain/entities/author.dart';

/// Author data model for database mapping
/// 
/// Handles conversion between database records and Author entities
/// with proper serialization and deserialization logic.
class AuthorModel {
  final String id;
  final String name;
  final String? bio;
  final String? birthDate;
  final String? deathDate;
  final String? nationality;
  final String? imageUrl;
  final int createdAt;
  final int updatedAt;

  const AuthorModel({
    required this.id,
    required this.name,
    this.bio,
    this.birthDate,
    this.deathDate,
    this.nationality,
    this.imageUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create AuthorModel from database map
  factory AuthorModel.fromMap(Map<String, dynamic> map) {
    return AuthorModel(
      id: map['id'] as String,
      name: map['name'] as String,
      bio: map['bio'] as String?,
      birthDate: map['birth_date'] as String?,
      deathDate: map['death_date'] as String?,
      nationality: map['nationality'] as String?,
      imageUrl: map['image_url'] as String?,
      createdAt: map['created_at'] as int,
      updatedAt: map['updated_at'] as int,
    );
  }

  /// Convert AuthorModel to database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'bio': bio,
      'birth_date': birthDate,
      'death_date': deathDate,
      'nationality': nationality,
      'image_url': imageUrl,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  /// Create AuthorModel from Author entity
  factory AuthorModel.fromEntity(Author author) {
    return AuthorModel(
      id: author.id,
      name: author.name,
      bio: author.bio,
      birthDate: author.birthDate?.toIso8601String(),
      deathDate: author.deathDate?.toIso8601String(),
      nationality: author.nationality,
      imageUrl: author.imageUrl,
      createdAt: author.createdAt.millisecondsSinceEpoch,
      updatedAt: author.updatedAt.millisecondsSinceEpoch,
    );
  }

  /// Convert AuthorModel to Author entity
  Author toEntity() {
    return Author(
      id: id,
      name: name,
      bio: bio,
      birthDate: birthDate != null ? DateTime.tryParse(birthDate!) : null,
      deathDate: deathDate != null ? DateTime.tryParse(deathDate!) : null,
      nationality: nationality,
      imageUrl: imageUrl,
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdAt),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(updatedAt),
    );
  }

  @override
  String toString() => 'AuthorModel(id: $id, name: $name)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AuthorModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
