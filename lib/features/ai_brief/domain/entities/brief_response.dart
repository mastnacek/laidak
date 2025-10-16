import 'package:equatable/equatable.dart';
import 'brief_section.dart';

/// Odpověď AI Brief obsahující sekce s prioritizovanými úkoly
///
/// Obsahuje:
/// - [sections]: Seznam sekcí (Focus Now, Key Insights, Motivation)
/// - [generatedAt]: Timestamp generování (pro cache validitu)
class BriefResponse extends Equatable {
  /// Seznam sekcí (Focus Now, Key Insights, Motivation)
  final List<BriefSection> sections;

  /// Timestamp generování (pro cache validitu)
  final DateTime generatedAt;

  const BriefResponse({
    required this.sections,
    required this.generatedAt,
  });

  /// Vytvoří BriefResponse z JSON
  factory BriefResponse.fromJson(Map<String, dynamic> json) {
    return BriefResponse(
      sections: (json['sections'] as List<dynamic>)
          .map((s) => BriefSection.fromJson(s as Map<String, dynamic>))
          .toList(),
      generatedAt: DateTime.parse(json['generated_at'] as String),
    );
  }

  /// Převede BriefResponse na JSON
  Map<String, dynamic> toJson() {
    return {
      'sections': sections.map((s) => s.toJson()).toList(),
      'generated_at': generatedAt.toIso8601String(),
    };
  }

  /// Validuje task IDs proti seznamu existujících úkolů
  ///
  /// Odstraní task IDs, které AI "halucinovala" (neexistují v DB)
  /// Používá se pro ochranu před AI chybami
  BriefResponse validate(List<int> validTodoIds) {
    final validatedSections = sections.map((section) {
      // Filtruj jen IDs, které skutečně existují
      final validIds = section.taskIds
          .where((id) => validTodoIds.contains(id))
          .toList();

      // Log případné hallucinations (pro debugging)
      final invalidIds = section.taskIds
          .where((id) => !validTodoIds.contains(id))
          .toList();

      if (invalidIds.isNotEmpty) {
        print('⚠️ AI Brief hallucination: Neplatné task IDs odstraněny: $invalidIds');
      }

      return section.copyWith(taskIds: validIds);
    }).toList();

    return BriefResponse(
      sections: validatedSections,
      generatedAt: generatedAt,
    );
  }

  /// Zkontroluje, zda je cache stále validní (1 hodina)
  bool get isCacheValid {
    final now = DateTime.now();
    final age = now.difference(generatedAt);
    return age < const Duration(hours: 1);
  }

  /// Získá zbývající čas validity cache (v minutách)
  int get cacheValidityMinutesRemaining {
    if (!isCacheValid) return 0;

    final now = DateTime.now();
    final age = now.difference(generatedAt);
    final remaining = const Duration(hours: 1) - age;

    return remaining.inMinutes;
  }

  @override
  List<Object?> get props => [sections, generatedAt];

  @override
  String toString() {
    return 'BriefResponse(sections: ${sections.length}, generatedAt: $generatedAt, cacheValid: $isCacheValid)';
  }
}
