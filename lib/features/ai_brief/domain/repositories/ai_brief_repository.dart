import '../../../../models/todo_item.dart';
import '../entities/brief_config.dart';
import '../entities/brief_response.dart';

/// Repository interface pro AI Brief feature
///
/// Odpovídá za:
/// - Generování AI Brief z úkolů
/// - Validaci task IDs proti DB
abstract class AiBriefRepository {
  /// Generuje AI Brief pro seznam úkolů
  ///
  /// [tasks]: Seznam aktivních úkolů k analýze
  /// [config]: Konfigurace (include subtasks, temperature, etc.)
  ///
  /// Returns: [BriefResponse] s prioritizovanými úkoly a AI komentáři
  /// Throws: [Exception] pokud AI request selže nebo je nevalidní response
  Future<BriefResponse> generateBrief({
    required List<TodoItem> tasks,
    required BriefConfig config,
  });
}
