import 'package:flutter_test/flutter_test.dart';
import 'package:todo/features/ai_brief/domain/entities/brief_response.dart';
import 'package:todo/features/ai_brief/domain/entities/brief_section.dart';

void main() {
  group('BriefResponse', () {
    test('fromJson parsuje JSON správně', () {
      // Arrange
      final json = {
        'sections': [
          {
            'type': 'focus_now',
            'title': '🎯 FOCUS NOW',
            'commentary': 'Top 3 urgentní úkoly',
            'task_ids': [1, 2, 3],
          },
          {
            'type': 'key_insights',
            'title': '📊 KEY INSIGHTS',
            'commentary': 'Závislosti a quick wins',
            'task_ids': [4, 5],
          },
        ],
        'generated_at': '2025-10-13T14:30:00.000',
      };

      // Act
      final briefResponse = BriefResponse.fromJson(json);

      // Assert
      expect(briefResponse.sections.length, 2);
      expect(briefResponse.sections[0].type, 'focus_now');
      expect(briefResponse.sections[0].taskIds, [1, 2, 3]);
      expect(briefResponse.sections[1].type, 'key_insights');
      expect(briefResponse.sections[1].taskIds, [4, 5]);
      expect(briefResponse.generatedAt.year, 2025);
      expect(briefResponse.generatedAt.month, 10);
      expect(briefResponse.generatedAt.day, 13);
    });

    test('validate odstraní neplatné task IDs', () {
      // Arrange
      final sections = [
        BriefSection(
          type: 'focus_now',
          title: '🎯 FOCUS NOW',
          commentary: 'Test',
          taskIds: [1, 999, 2], // 999 je neplatný
        ),
      ];
      final briefResponse = BriefResponse(
        sections: sections,
        generatedAt: DateTime.now(),
      );

      final validTaskIds = [1, 2]; // pouze 1 a 2 jsou platné

      // Act
      final validated = briefResponse.validate(validTaskIds);

      // Assert
      expect(validated.sections[0].taskIds, [1, 2]); // 999 odstraněn
      expect(validated.sections[0].taskIds.contains(999), false);
    });

    test('validate zachová prázdnou sekci pokud všechny task IDs jsou neplatné',
        () {
      // Arrange
      final sections = [
        BriefSection(
          type: 'focus_now',
          title: '🎯 FOCUS NOW',
          commentary: 'Test',
          taskIds: [999, 888], // všechny neplatné
        ),
      ];
      final briefResponse = BriefResponse(
        sections: sections,
        generatedAt: DateTime.now(),
      );

      final validTaskIds = [1, 2]; // žádný z 999, 888 není platný

      // Act
      final validated = briefResponse.validate(validTaskIds);

      // Assert
      expect(validated.sections[0].taskIds, isEmpty);
    });

    test('isCacheValid vrací true pro data mladší než 1 hodinu', () {
      // Arrange
      final briefResponse = BriefResponse(
        sections: [],
        generatedAt: DateTime.now().subtract(const Duration(minutes: 30)),
      );

      // Act & Assert
      expect(briefResponse.isCacheValid, true);
    });

    test('isCacheValid vrací false pro data starší než 1 hodinu', () {
      // Arrange
      final briefResponse = BriefResponse(
        sections: [],
        generatedAt: DateTime.now().subtract(const Duration(hours: 2)),
      );

      // Act & Assert
      expect(briefResponse.isCacheValid, false);
    });

    test('toJson serializuje správně', () {
      // Arrange
      final sections = [
        BriefSection(
          type: 'focus_now',
          title: '🎯 FOCUS NOW',
          commentary: 'Test commentary',
          taskIds: [1, 2, 3],
        ),
      ];
      final generatedAt = DateTime(2025, 10, 13, 14, 30);
      final briefResponse = BriefResponse(
        sections: sections,
        generatedAt: generatedAt,
      );

      // Act
      final json = briefResponse.toJson();

      // Assert
      expect(json['sections'], isA<List>());
      expect(json['sections'].length, 1);
      expect(json['sections'][0]['type'], 'focus_now');
      expect(json['sections'][0]['task_ids'], [1, 2, 3]);
      expect(json['generated_at'], isA<String>());
    });
  });
}
