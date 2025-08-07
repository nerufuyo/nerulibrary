import 'package:equatable/equatable.dart';

/// Author entity representing book authors
/// 
/// Contains author information including biographical data
/// and metadata for display and organization.
class Author extends Equatable {
  final String id;
  final String name;
  final String? bio;
  final DateTime? birthDate;
  final DateTime? deathDate;
  final String? nationality;
  final String? imageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Author({
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

  /// Create a copy of this author with updated fields
  Author copyWith({
    String? id,
    String? name,
    String? bio,
    DateTime? birthDate,
    DateTime? deathDate,
    String? nationality,
    String? imageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Author(
      id: id ?? this.id,
      name: name ?? this.name,
      bio: bio ?? this.bio,
      birthDate: birthDate ?? this.birthDate,
      deathDate: deathDate ?? this.deathDate,
      nationality: nationality ?? this.nationality,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Check if author is deceased
  bool get isDeceased => deathDate != null;

  /// Get author's age (if known)
  int? get age {
    if (birthDate == null) return null;
    final endDate = deathDate ?? DateTime.now();
    return endDate.year - birthDate!.year;
  }

  /// Get author's lifespan as a string
  String get lifespanString {
    if (birthDate == null && deathDate == null) return '';
    
    final birth = birthDate?.year.toString() ?? '?';
    final death = deathDate?.year.toString() ?? (isDeceased ? '?' : 'present');
    
    return '($birth - $death)';
  }

  /// Get full author name with lifespan
  String get displayName {
    final lifespan = lifespanString;
    return lifespan.isEmpty ? name : '$name $lifespan';
  }

  @override
  List<Object?> get props => [
        id,
        name,
        bio,
        birthDate,
        deathDate,
        nationality,
        imageUrl,
        createdAt,
        updatedAt,
      ];

  @override
  String toString() => 'Author(id: $id, name: $name)';
}
