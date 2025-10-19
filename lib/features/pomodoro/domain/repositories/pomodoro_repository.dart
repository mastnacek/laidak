import '../entities/pomodoro_config.dart';
import '../entities/pomodoro_session.dart';

/// PomodoroRepository - Repository interface pro Pomodoro feature
///
/// Abstraktní interface definující operace s Pomodoro sessions a config.
/// Implementace v `data/repositories/pomodoro_repository_impl.dart`.
///
/// **Odpovědnost**:
/// - CRUD operace s PomodoroSession (SQLite)
/// - Persistence PomodoroConfig (SharedPreferences)
///
/// **Implementační pravidla**:
/// - Interface je v domain layer (čistá Dart, bez závislostí)
/// - Implementace je v data layer (konkrétní DB/Storage access)
/// - BLoC používá pouze tento interface (Dependency Inversion)
///
/// Příklad použití:
/// ```dart
/// final repository = PomodoroRepositoryImpl(...);
///
/// // Vytvoř session
/// final session = PomodoroSession(
///   taskId: 5,
///   startedAt: DateTime.now(),
///   duration: Duration(minutes: 25),
///   completed: false,
/// );
/// final saved = await repository.createSession(session);
///
/// // Načti historii pro úkol
/// final history = await repository.getSessionsByTask(5);
///
/// // Ulož config
/// await repository.saveConfig(PomodoroConfig.defaultConfig());
/// ```
abstract class PomodoroRepository {
  // ========== CRUD operations pro PomodoroSession ==========

  /// Vytvoř novou session v databázi
  ///
  /// **Parametry**:
  /// - `session`: PomodoroSession s `id = null` (auto-increment v DB)
  ///
  /// **Vrací**: PomodoroSession s vyplněným `id` z databáze
  ///
  /// **Výjimky**: Vyhodí Exception pokud DB insert selže
  Future<PomodoroSession> createSession(PomodoroSession session);

  /// Aktualizuj existující session (např. při dokončení/přerušení)
  ///
  /// **Parametry**:
  /// - `session`: PomodoroSession s vyplněným `id`
  ///
  /// **Použití**:
  /// - Dokončení: `session.copyWith(completed: true, endedAt: DateTime.now())`
  /// - Přerušení: `session.copyWith(completed: false, endedAt: DateTime.now())`
  ///
  /// **Výjimky**: Vyhodí Exception pokud session.id == null nebo DB update selže
  Future<void> updateSession(PomodoroSession session);

  /// Načti všechny sessions pro daný úkol (seřazené od nejnovější)
  ///
  /// **Parametry**:
  /// - `taskId`: ID úkolu z `todos` tabulky
  ///
  /// **Vrací**: List<PomodoroSession> (prázdný list pokud žádné)
  ///
  /// **SQL**: `SELECT * FROM pomodoro_sessions WHERE task_id = ? ORDER BY started_at DESC`
  Future<List<PomodoroSession>> getSessionsByTask(int taskId);

  /// Načti všechny sessions (pro historii/statistiky)
  ///
  /// **Vrací**: List<PomodoroSession> seřazený podle `started_at DESC`
  ///
  /// **Použití**: History view, statistiky, denní přehled
  Future<List<PomodoroSession>> getAllSessions();

  /// Načti sessions za dnes (od 00:00 do 23:59)
  ///
  /// **Vrací**: List<PomodoroSession> pro dnešní den
  ///
  /// **SQL**: `WHERE started_at >= ? AND started_at < ?`
  Future<List<PomodoroSession>> getTodaySessions();

  /// Smaž session podle ID
  ///
  /// **Parametry**:
  /// - `sessionId`: ID session v databázi
  ///
  /// **Výjimky**: Vyhodí Exception pokud session neexistuje
  Future<void> deleteSession(int sessionId);

  // ========== Config persistence (SharedPreferences) ==========

  /// Ulož PomodoroConfig do SharedPreferences
  ///
  /// **Parametry**:
  /// - `config`: PomodoroConfig instance
  ///
  /// **Persistence**: JSON serialization do SharedPreferences
  /// - Key: `pomodoro_config`
  /// - Value: JSON string (toJson())
  Future<void> saveConfig(PomodoroConfig config);

  /// Načti PomodoroConfig ze SharedPreferences
  ///
  /// **Vrací**: PomodoroConfig (nebo defaultní hodnoty pokud neexistuje)
  ///
  /// **Fallback**: Pokud není uloženo, vrátí `PomodoroConfig.defaultConfig()`
  Future<PomodoroConfig> loadConfig();

  // ========== Statistiky (optional, budoucí rozšíření) ==========

  /// Počet dokončených Pomodoro sessions pro úkol
  ///
  /// **SQL**: `SELECT COUNT(*) FROM pomodoro_sessions WHERE task_id = ? AND completed = 1`
  Future<int> getCompletedSessionCount(int taskId);

  /// Celková doba strávená na úkolu (součet dokončených sessions)
  ///
  /// **Vrací**: Duration (součet `duration` všech completed sessions)
  Future<Duration> getTotalTimeForTask(int taskId);

  /// Počet Pomodoro sessions dnes
  ///
  /// **Použití**: Dashboard, daily stats
  Future<int> getTodaySessionCount();
}
