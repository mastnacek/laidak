import 'package:equatable/equatable.dart';
import '../../domain/entities/tag_definition.dart';

/// Base state pro Tag Management
abstract class TagManagementState extends Equatable {
  const TagManagementState();

  @override
  List<Object?> get props => [];
}

/// Počáteční stav
class TagManagementInitial extends TagManagementState {
  const TagManagementInitial();
}

/// Načítání tagů
class TagManagementLoading extends TagManagementState {
  const TagManagementLoading();
}

/// Tagy úspěšně načteny
class TagManagementLoaded extends TagManagementState {
  final List<TagDefinition> tags;
  final String tagDelimiterStart;
  final String tagDelimiterEnd;

  const TagManagementLoaded({
    required this.tags,
    required this.tagDelimiterStart,
    required this.tagDelimiterEnd,
  });

  @override
  List<Object?> get props => [tags, tagDelimiterStart, tagDelimiterEnd];

  /// Vytvořit kopii se změněnými hodnotami
  TagManagementLoaded copyWith({
    List<TagDefinition>? tags,
    String? tagDelimiterStart,
    String? tagDelimiterEnd,
  }) {
    return TagManagementLoaded(
      tags: tags ?? this.tags,
      tagDelimiterStart: tagDelimiterStart ?? this.tagDelimiterStart,
      tagDelimiterEnd: tagDelimiterEnd ?? this.tagDelimiterEnd,
    );
  }

  /// Seskupit tagy podle typu
  Map<TagType, List<TagDefinition>> get tagsByType {
    final grouped = <TagType, List<TagDefinition>>{};
    for (final tag in tags) {
      grouped.putIfAbsent(tag.tagType, () => []).add(tag);
    }
    return grouped;
  }
}

/// Chyba při načítání nebo operaci
class TagManagementError extends TagManagementState {
  final String message;

  const TagManagementError(this.message);

  @override
  List<Object?> get props => [message];
}

/// Úspěšné provedení operace (add, update, delete, toggle)
class TagManagementOperationSuccess extends TagManagementState {
  final String message;
  final List<TagDefinition> tags;
  final String tagDelimiterStart;
  final String tagDelimiterEnd;

  const TagManagementOperationSuccess({
    required this.message,
    required this.tags,
    required this.tagDelimiterStart,
    required this.tagDelimiterEnd,
  });

  @override
  List<Object?> get props => [message, tags, tagDelimiterStart, tagDelimiterEnd];
}
