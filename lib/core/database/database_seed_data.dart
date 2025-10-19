import 'package:sqflite/sqflite.dart';

/// Database seed data - výchozí nastavení, prompty a tag definitions
///
/// Tento soubor obsahuje všechny seed data pro fresh install.
class DatabaseSeedData {
  /// Vložit výchozí AI nastavení
  static Future<void> insertDefaultSettings(Database db) async {
    await db.insert('settings', {
      'id': 1,
      'api_key': null, // User must provide their own OpenRouter API key
      'model': 'mistralai/mistral-medium-3.1',
      'temperature': 1.0,
      'max_tokens': 1000,
      'enabled': 1,
      'tag_delimiter_start': '*',
      'tag_delimiter_end': '*',
      'selected_theme': 'doom_one',
      'has_seen_gesture_hint': 0,
      'show_all': 1,
      'show_today': 1,
      'show_week': 1,
      'show_upcoming': 0,
      'show_overdue': 1,
      // AI Settings
      'openrouter_api_key': null,
      'ai_motivation_model': 'mistralai/mistral-medium-3.1',
      'ai_motivation_temperature': 0.9,
      'ai_motivation_max_tokens': 200,
      'ai_task_model': 'anthropic/claude-3.5-sonnet',
      'ai_task_temperature': 0.3,
      'ai_task_max_tokens': 1000,
      'ai_reward_model': 'anthropic/claude-3.5-sonnet',
      'ai_reward_temperature': 0.9,
      'ai_reward_max_tokens': 1000,
      // AI Tag Suggestions Settings
      'ai_tag_suggestions_model': 'anthropic/claude-3.5-haiku',
      'ai_tag_suggestions_temperature': 1.0,
      'ai_tag_suggestions_max_tokens': 500,
      'ai_tag_suggestions_seed': null,
      'ai_tag_suggestions_top_p': null,
      'ai_tag_suggestions_debounce_ms': 1000, // 1s = spustí až když přestaneš psát
      // Brief Settings
      'brief_include_subtasks': 1,
      'brief_include_pomodoro': 1,
      'brief_completed_today': 1,
      'brief_completed_week': 1,
      'brief_completed_month': 0,
      'brief_completed_year': 0,
      'brief_completed_all': 0,
    });
  }

  /// Vložit výchozí motivační prompty
  ///
  /// NOTE: Tyto prompty jsou jen ukázky! Uživatel si může vytvořit vlastní
  /// v Nastavení → Motivační Prompty podle svých preferencí.
  static Future<void> insertDefaultPrompts(Database db) async {
    // Demo prompt: Profesionální styl
    await db.insert('custom_prompts', {
      'category': 'práce',
      'system_prompt': 'Jsi motivační kouč zaměřený na produktivitu v práci. Motivuj uživatele k dokončení pracovních úkolů s důrazem na profesionalitu a efektivitu. Buď pozitivní, ale asertivní. Používej emoji pro zvýraznění.',
      'tags': '["práce","work","job","office","projekt","meeting"]',
      'style': 'profesionální a motivující',
    });

    // Demo prompt: Rodinný styl
    await db.insert('custom_prompts', {
      'category': 'domov',
      'system_prompt': 'Jsi přátelský asistent zaměřený na domácí úkoly a rodinu. Motivuj uživatele k dokončení domácích činností s důrazem na rodinné hodnoty a pohodlí domova. Buď vlídný a podporující. Používej emoji pro zvýraznění.',
      'tags': '["domov","doma","rodina","family","home"]',
      'style': 'rodinný a vlídný',
    });
  }

  /// Vložit výchozí definice tagů (podle Tauri verze + rozšíření)
  static Future<void> insertDefaultTagDefinitions(Database db) async {
    // Priority tagy
    await db.insert('tag_definitions', {
      'tag_name': 'a',
      'tag_type': 'priority',
      'display_name': 'Vysoká priorita',
      'emoji': '🔴',
      'color': '#ff0000',
      'sort_order': 1,
      'enabled': 1,
    });

    await db.insert('tag_definitions', {
      'tag_name': 'b',
      'tag_type': 'priority',
      'display_name': 'Střední priorita',
      'emoji': '🟡',
      'color': '#ffaa00',
      'sort_order': 2,
      'enabled': 1,
    });

    await db.insert('tag_definitions', {
      'tag_name': 'c',
      'tag_type': 'priority',
      'display_name': 'Nízká priorita',
      'emoji': '🟢',
      'color': '#00ff00',
      'sort_order': 3,
      'enabled': 1,
    });

    // Časové/deadline tagy
    await db.insert('tag_definitions', {
      'tag_name': 'dnes',
      'tag_type': 'date',
      'display_name': 'Dnes',
      'emoji': '⏰',
      'color': '#ff0000',
      'sort_order': 1,
      'enabled': 1,
    });

    await db.insert('tag_definitions', {
      'tag_name': 'zitra',
      'tag_type': 'date',
      'display_name': 'Zítra',
      'emoji': '📅',
      'color': '#ffaa00',
      'sort_order': 2,
      'enabled': 1,
    });

    await db.insert('tag_definitions', {
      'tag_name': 'zatyden',
      'tag_type': 'date',
      'display_name': 'Za týden',
      'emoji': '📆',
      'color': '#00aaff',
      'sort_order': 3,
      'enabled': 1,
    });

    await db.insert('tag_definitions', {
      'tag_name': 'zamesic',
      'tag_type': 'date',
      'display_name': 'Za měsíc',
      'emoji': '📆',
      'color': '#0088ff',
      'sort_order': 4,
      'enabled': 1,
    });

    await db.insert('tag_definitions', {
      'tag_name': 'zarok',
      'tag_type': 'date',
      'display_name': 'Za rok',
      'emoji': '📆',
      'color': '#0066ff',
      'sort_order': 5,
      'enabled': 1,
    });

    // Status tagy
    await db.insert('tag_definitions', {
      'tag_name': 'hotove',
      'tag_type': 'status',
      'display_name': 'Hotové',
      'emoji': '✅',
      'color': '#00ff00',
      'sort_order': 1,
      'enabled': 1,
    });

    await db.insert('tag_definitions', {
      'tag_name': 'todo',
      'tag_type': 'status',
      'display_name': 'K dokončení',
      'emoji': '📝',
      'color': '#ffaa00',
      'sort_order': 2,
      'enabled': 1,
    });
  }
}
