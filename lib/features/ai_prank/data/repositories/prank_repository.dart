import '../../../todo_list/domain/entities/todo.dart';

/// Repository pro generování AI pranků a dobrých skutků (good deeds)
abstract class PrankRepository {
  /// Vygeneruje prank tip po dokončení úkolu (lichý počet dokončených úkolů)
  ///
  /// Vrací:
  /// - Markdown formátovaný text s pochvalou + prank tipem
  ///
  /// Throws:
  /// - ArgumentError pokud completedTodo je prázdný
  /// - StateError pokud API klíč není nastaven
  /// - Exception pokud API call selže
  Future<String> generatePrank({
    required Todo completedTodo,
  });

  /// Vygeneruje good deed tip po dokončení úkolu (sudý počet dokončených úkolů)
  ///
  /// Vrací:
  /// - Markdown formátovaný text s pochvalou + tipem na dobrý skutek
  ///
  /// Throws:
  /// - ArgumentError pokud completedTodo je prázdný
  /// - StateError pokud API klíč není nastaven
  /// - Exception pokud API call selže
  Future<String> generateGoodDeed({
    required Todo completedTodo,
  });
}
