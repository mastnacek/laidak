import 'package:flutter/material.dart';

/// Typ demo v Help System
enum DemoType {
  tagParsing, // Live parsing tagů (bez API)
  aiSplit, // AI Split s OpenRouter API
  motivationPrompt, // Motivační prompty s OpenRouter API
}

/// Model sekce v Help System (Card-based layout)
class HelpSection {
  final String id;
  final String title;
  final IconData icon;
  final String description;
  final List<String> examples;
  final bool hasInteractiveDemo;
  final DemoType? demoType;
  final bool requiresApiKey;

  const HelpSection({
    required this.id,
    required this.title,
    required this.icon,
    required this.description,
    required this.examples,
    this.hasInteractiveDemo = false,
    this.demoType,
    this.requiresApiKey = false,
  });

  /// Seznam všech help sekcí (podle help.md - Varianta B)
  static List<HelpSection> get allSections => [
        // 1. Tagy a TagParser (Must-have)
        const HelpSection(
          id: 'tags',
          title: '🏷️ Jak používat tagy?',
          icon: Icons.label,
          description:
              'Tagy ti pomáhají organizovat úkoly pomocí priorit, dat a vlastních kategorií.',
          examples: [
            '*a* *dnes* Zavolat doktorovi → Priorita A, Deadline dnes',
            '*b* *15.1.* Koupit dárek mámě → Priorita B, Deadline 15.1.',
            '*c* Uklidit garáž *domov* → Priorita C, Tag: domov',
            '*a* *zitra* *koupit* Nové boty → Priorita A, Deadline zítra, Akce: koupit',
          ],
          hasInteractiveDemo: true,
          demoType: DemoType.tagParsing,
          requiresApiKey: false,
        ),

        // 2. AI Rozdělení úkolu (Should-have)
        const HelpSection(
          id: 'ai_split',
          title: '🤖 AI Rozdělení úkolu',
          icon: Icons.auto_awesome,
          description:
              'AI ti pomůže rozdělit složitý úkol na menší, zvladatelné kroky.',
          examples: [
            'Input: "Naplánovat dovolenou v Itálii"',
            'Output:',
            '1. Zjistit termín dovolené',
            '2. Vybrat destinaci (Řím vs. Florencie)',
            '3. Rezervovat letenky',
            '4. Najít ubytování',
            '5. Naplánovat aktivity',
            '6. Zařídit pojištění',
          ],
          hasInteractiveDemo: true,
          demoType: DemoType.aiSplit,
          requiresApiKey: true,
        ),

        // 3. Motivační prompty (Should-have)
        const HelpSection(
          id: 'motivation',
          title: '💬 Motivační prompty',
          icon: Icons.psychology,
          description:
              'Vlastní AI prompty pro motivaci podle typu úkolu. AI ti pomůže překonat prokrastinaci.',
          examples: [
            'Úkol: "Napsat seminární práci"',
            'Typ: Motivační',
            'AI Response: "💪 Tvoje seminární práce bude skvělá! Začni s úvodem dnes..."',
          ],
          hasInteractiveDemo: true,
          demoType: DemoType.motivationPrompt,
          requiresApiKey: true,
        ),

        // 4. Režimy zobrazení (Must-have - statické info)
        const HelpSection(
          id: 'views',
          title: '📊 Režimy zobrazení (Views)',
          icon: Icons.filter_alt,
          description:
              'Filtruj úkoly podle časových kategorií pro lepší přehled.',
          examples: [
            '📋 Všechny - Kompletní seznam úkolů',
            '📅 Dnes - Úkoly s deadline dnes',
            '🗓️ Týden - Nadcházející týden',
            '⏰ Nadcházející - Všechny úkoly s deadline',
            '⚠️ Po termínu - Overdue úkoly (červeně)',
            '👁️ Hotové - Dokončené úkoly',
          ],
          hasInteractiveDemo: false,
          requiresApiKey: false,
        ),

        // 5. Vyhledávání a řazení (Must-have - statické info)
        const HelpSection(
          id: 'search_sort',
          title: '🔍 Vyhledávání a řazení',
          icon: Icons.search,
          description:
              'Rychle najdi úkol nebo seřaď podle priority, data nebo stavu.',
          examples: [
            '🔍 Search: Lupa vlevo od input pole - live filtering',
            '🔴 Priorita: Seřaď podle A → B → C',
            '📅 Deadline: Seřaž podle nejbližšího termínu',
            '✅ Status: Nedokončené úkoly první',
            '🆕 Datum: Seřaž podle data vytvoření',
          ],
          hasInteractiveDemo: false,
          requiresApiKey: false,
        ),

        // 6. Nastavení (Should-have - link na SettingsPage)
        const HelpSection(
          id: 'settings',
          title: '⚙️ Nastavení a konfigurace',
          icon: Icons.settings,
          description:
              'Nastav OpenRouter API klíč, vyber AI model, uprav custom prompty a téma aplikace.',
          examples: [
            'OpenRouter API key: sk-or-v1-...',
            'Model: mistralai/mistral-medium-3.1, claude-3.5-sonnet',
            'Temperature: 0.0 (konzistentní) - 2.0 (kreativní)',
            'Max Tokens: 100-4000 (délka odpovědi)',
            'Témata: Doom One, Blade Runner, Osaka Jade, AMOLED',
          ],
          hasInteractiveDemo: false,
          requiresApiKey: false,
        ),
      ];
}
