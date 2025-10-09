/// Repository interface pro AI motivaci
///
/// Abstrakce pro získávání motivačních zpráv z AI služby.
abstract class MotivationRepository {
  /// Získat motivační zprávu pro úkol
  ///
  /// [taskText] - text úkolu
  /// [priority] - priorita úkolu (a, b, c)
  /// [tags] - tagy úkolu
  ///
  /// Throws exception při chybě API nebo sítě
  Future<String> getMotivation({
    required String taskText,
    String? priority,
    List<String>? tags,
  });
}
