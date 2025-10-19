import '../../../todo_list/domain/entities/todo.dart';
import '../../../ai_split/domain/entities/subtask.dart';
import '../../../pomodoro/domain/entities/pomodoro_session.dart';

/// Kontext úkolu pro AI chat
///
/// Obsahuje všechna relevantní data pro AI asistenta:
/// - Hlavní úkol (task, priority, deadline, tags)
/// - Podúkoly (subtasks) včetně completion stavu
/// - Pomodoro sessions (čas strávený na úkolu)
/// - AI metadata (recommendations, deadline analysis)
class TaskContext {
  /// Hlavní TODO úkol
  final Todo todo;

  /// Podúkoly (pokud existují)
  final List<Subtask> subtasks;

  /// Pomodoro sessions (historie práce na úkolu)
  final List<PomodoroSession> pomodoroSessions;

  const TaskContext({
    required this.todo,
    this.subtasks = const [],
    this.pomodoroSessions = const [],
  });

  /// Vytvoř system prompt pro AI
  ///
  /// Toto je první message v konverzaci, která dává AI kontext.
  String toSystemPrompt() {
    final buffer = StringBuffer();

    buffer.writeln('Jsi AI asistent pomáhající s TODO úkolem.');
    buffer.writeln('');
    buffer.writeln('KONTEXT ÚKOLU:');
    buffer.writeln('Název: ${todo.task}');

    if (todo.priority != null) {
      buffer.writeln('Priorita: ${todo.priority!.toUpperCase()}');
    }

    if (todo.dueDate != null) {
      buffer.writeln('Deadline: ${_formatDate(todo.dueDate!)}');
    }

    if (todo.tags.isNotEmpty) {
      buffer.writeln('Tagy: ${todo.tags.join(", ")}');
    }

    buffer.writeln('Stav: ${todo.isCompleted ? "✅ Hotovo" : "⏳ Aktivní"}');

    // Podúkoly
    if (subtasks.isNotEmpty) {
      final completed = subtasks.where((s) => s.completed).length;
      buffer.writeln('');
      buffer.writeln('PODÚKOLY ($completed/${subtasks.length} hotovo):');
      for (var subtask in subtasks) {
        buffer.writeln('${subtask.completed ? "✅" : "☐"} ${subtask.subtaskNumber}. ${subtask.text}');
      }
    }

    // Pomodoro sessions
    if (pomodoroSessions.isNotEmpty) {
      final totalMinutes = pomodoroSessions.fold<int>(
        0,
        (sum, session) => sum + session.duration.inMinutes,
      );
      buffer.writeln('');
      buffer.writeln('HISTORIE PRÁCE:');
      buffer.writeln('🍅 Pomodoro sessions: ${pomodoroSessions.length}x');
      buffer.writeln('⏱️ Celkový čas: $totalMinutes minut');
    }

    // AI metadata
    if (todo.aiRecommendations != null && todo.aiRecommendations!.isNotEmpty) {
      buffer.writeln('');
      buffer.writeln('AI DOPORUČENÍ:');
      buffer.writeln(todo.aiRecommendations);
    }

    if (todo.aiDeadlineAnalysis != null && todo.aiDeadlineAnalysis!.isNotEmpty) {
      buffer.writeln('');
      buffer.writeln('AI ANALÝZA TERMÍNU:');
      buffer.writeln(todo.aiDeadlineAnalysis);
    }

    buffer.writeln('');
    buffer.writeln('---');
    buffer.writeln('Tvoje role: Pomáhej uživateli s tímto úkolem. Buď konstruktivní, konkrétní a praktický.');
    buffer.writeln('');
    buffer.writeln('# FORMATTING RULES');
    buffer.writeln('Formátuj odpovědi pomocí Markdown pro lepší čitelnost:');
    buffer.writeln('- Používej **tučný text** pro důležitá slova, čísla úkolů, deadlines');
    buffer.writeln('- Používej *kurzívu* pro zdůraznění');
    buffer.writeln('- Používej číslované seznamy (1., 2., 3.) pro kroky nebo postupy');
    buffer.writeln('- Používej odrážky (-, •) pro seznamy');
    buffer.writeln('- Používej nadpisy (# Nadpis) pro strukturu delších odpovědí');

    return buffer.toString();
  }

  /// Format date to Czech format
  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }

  /// Počet dokončených podúkolů
  int get completedSubtasks => subtasks.where((s) => s.completed).length;

  /// Celkový čas strávený na úkolu (v minutách)
  int get totalPomodoroMinutes => pomodoroSessions.fold<int>(
    0,
    (sum, session) => sum + session.duration.inMinutes,
  );
}
