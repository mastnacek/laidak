import 'package:flutter/material.dart';
import '../theme/doom_one_theme.dart';
import '../services/database_helper.dart';

/// Stránka s nastavením AI motivace
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final DatabaseHelper _db = DatabaseHelper();
  List<Map<String, dynamic>> _prompts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPrompts();
  }

  /// Načíst všechny prompty z databáze
  Future<void> _loadPrompts() async {
    setState(() => _isLoading = true);
    final prompts = await _db.getAllPrompts();
    setState(() {
      _prompts = prompts;
      _isLoading = false;
    });
  }

  /// Zobrazit dialog pro editaci promptu
  Future<void> _editPrompt(Map<String, dynamic> prompt) async {
    final categoryController = TextEditingController(text: prompt['category']);
    final promptController = TextEditingController(text: prompt['system_prompt']);
    final tagsController = TextEditingController(
      text: (prompt['tags'] as String)
          .replaceAll('[', '')
          .replaceAll(']', '')
          .replaceAll('"', ''),
    );
    final styleController = TextEditingController(text: prompt['style']);

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: DoomOneTheme.bg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: DoomOneTheme.cyan, width: 2),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: BoxConstraints(
            maxWidth: 700,
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Icon(Icons.edit, color: DoomOneTheme.cyan, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'EDITOVAT PROMPT',
                        style: TextStyle(
                          color: DoomOneTheme.cyan,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: DoomOneTheme.base5),
                      onPressed: () => Navigator.of(context).pop(false),
                    ),
                  ],
                ),
                Divider(color: DoomOneTheme.base3, height: 24),

                // Kategorie
                Text(
                  'Kategorie',
                  style: TextStyle(
                    color: DoomOneTheme.fg,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: categoryController,
                  style: TextStyle(color: DoomOneTheme.fg),
                  decoration: InputDecoration(
                    hintText: 'práce, domov, sport...',
                    hintStyle: TextStyle(color: DoomOneTheme.base5),
                    filled: true,
                    fillColor: DoomOneTheme.base2,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: DoomOneTheme.base4),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // System Prompt
                Text(
                  'System Prompt (Jak má AI mluvit)',
                  style: TextStyle(
                    color: DoomOneTheme.fg,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: promptController,
                  maxLines: 10,
                  style: TextStyle(color: DoomOneTheme.fg),
                  decoration: InputDecoration(
                    hintText: 'Jsi můj motivační kouč...',
                    hintStyle: TextStyle(color: DoomOneTheme.base5),
                    filled: true,
                    fillColor: DoomOneTheme.base2,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: DoomOneTheme.base4),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Tagy
                Text(
                  'Tagy (oddělené čárkou)',
                  style: TextStyle(
                    color: DoomOneTheme.fg,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: tagsController,
                  style: TextStyle(color: DoomOneTheme.fg),
                  decoration: InputDecoration(
                    hintText: 'práce, work, job, office',
                    hintStyle: TextStyle(color: DoomOneTheme.base5),
                    filled: true,
                    fillColor: DoomOneTheme.base2,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: DoomOneTheme.base4),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Styl
                Text(
                  'Styl',
                  style: TextStyle(
                    color: DoomOneTheme.fg,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: styleController,
                  style: TextStyle(color: DoomOneTheme.fg),
                  decoration: InputDecoration(
                    hintText: 'profesionální, rodinný, sportovní...',
                    hintStyle: TextStyle(color: DoomOneTheme.base5),
                    filled: true,
                    fillColor: DoomOneTheme.base2,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: DoomOneTheme.base4),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Tlačítka
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text(
                        'Zrušit',
                        style: TextStyle(color: DoomOneTheme.base5),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () async {
                        // Uložit do databáze
                        final db = await _db.database;

                        // Formátovat tagy jako JSON array
                        final tagsList = tagsController.text
                            .split(',')
                            .map((t) => '"${t.trim()}"')
                            .join(',');

                        await db.update(
                          'custom_prompts',
                          {
                            'category': categoryController.text.trim(),
                            'system_prompt': promptController.text.trim(),
                            'tags': '[$tagsList]',
                            'style': styleController.text.trim(),
                          },
                          where: 'id = ?',
                          whereArgs: [prompt['id']],
                        );

                        if (context.mounted) {
                          Navigator.of(context).pop(true);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: DoomOneTheme.cyan,
                        foregroundColor: DoomOneTheme.bg,
                      ),
                      child: const Text('Uložit'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // Pokud byl prompt upraven, reload
    if (result == true) {
      await _loadPrompts();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Prompt byl úspěšně uložen'),
            backgroundColor: DoomOneTheme.green,
          ),
        );
      }
    }
  }

  /// Přidat nový prompt
  Future<void> _addPrompt() async {
    final categoryController = TextEditingController();
    final promptController = TextEditingController(
      text: 'Jsi motivační kouč. Tvým úkolem je motivovat uživatele k dokončení úkolu. Buď stručný, inspirativní a konkrétní. Používej emoji.',
    );
    final tagsController = TextEditingController();
    final styleController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: DoomOneTheme.bg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: DoomOneTheme.green, width: 2),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: BoxConstraints(
            maxWidth: 700,
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Icon(Icons.add_circle, color: DoomOneTheme.green, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'NOVÝ PROMPT',
                        style: TextStyle(
                          color: DoomOneTheme.green,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: DoomOneTheme.base5),
                      onPressed: () => Navigator.of(context).pop(false),
                    ),
                  ],
                ),
                Divider(color: DoomOneTheme.base3, height: 24),

                // Kategorie
                Text(
                  'Kategorie',
                  style: TextStyle(
                    color: DoomOneTheme.fg,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: categoryController,
                  style: TextStyle(color: DoomOneTheme.fg),
                  decoration: InputDecoration(
                    hintText: 'práce, domov, sport...',
                    hintStyle: TextStyle(color: DoomOneTheme.base5),
                    filled: true,
                    fillColor: DoomOneTheme.base2,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: DoomOneTheme.base4),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // System Prompt
                Text(
                  'System Prompt (Jak má AI mluvit)',
                  style: TextStyle(
                    color: DoomOneTheme.fg,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: promptController,
                  maxLines: 10,
                  style: TextStyle(color: DoomOneTheme.fg),
                  decoration: InputDecoration(
                    hintText: 'Jsi můj motivační kouč...',
                    hintStyle: TextStyle(color: DoomOneTheme.base5),
                    filled: true,
                    fillColor: DoomOneTheme.base2,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: DoomOneTheme.base4),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Tagy
                Text(
                  'Tagy (oddělené čárkou)',
                  style: TextStyle(
                    color: DoomOneTheme.fg,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: tagsController,
                  style: TextStyle(color: DoomOneTheme.fg),
                  decoration: InputDecoration(
                    hintText: 'práce, work, job, office',
                    hintStyle: TextStyle(color: DoomOneTheme.base5),
                    filled: true,
                    fillColor: DoomOneTheme.base2,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: DoomOneTheme.base4),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Styl
                Text(
                  'Styl',
                  style: TextStyle(
                    color: DoomOneTheme.fg,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: styleController,
                  style: TextStyle(color: DoomOneTheme.fg),
                  decoration: InputDecoration(
                    hintText: 'profesionální, rodinný, sportovní...',
                    hintStyle: TextStyle(color: DoomOneTheme.base5),
                    filled: true,
                    fillColor: DoomOneTheme.base2,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: DoomOneTheme.base4),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Tlačítka
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text(
                        'Zrušit',
                        style: TextStyle(color: DoomOneTheme.base5),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () async {
                        if (categoryController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Kategorie nesmí být prázdná'),
                              backgroundColor: DoomOneTheme.red,
                            ),
                          );
                          return;
                        }

                        // Uložit do databáze
                        final db = await _db.database;

                        // Formátovat tagy jako JSON array
                        final tagsList = tagsController.text
                            .split(',')
                            .map((t) => '"${t.trim()}"')
                            .join(',');

                        try {
                          await db.insert(
                            'custom_prompts',
                            {
                              'category': categoryController.text.trim(),
                              'system_prompt': promptController.text.trim(),
                              'tags': '[$tagsList]',
                              'style': styleController.text.trim(),
                            },
                          );

                          if (context.mounted) {
                            Navigator.of(context).pop(true);
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Chyba: $e'),
                                backgroundColor: DoomOneTheme.red,
                              ),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: DoomOneTheme.green,
                        foregroundColor: DoomOneTheme.bg,
                      ),
                      child: const Text('Přidat'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // Pokud byl prompt přidán, reload
    if (result == true) {
      await _loadPrompts();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Prompt byl úspěšně přidán'),
            backgroundColor: DoomOneTheme.green,
          ),
        );
      }
    }
  }

  /// Smazat prompt
  Future<void> _deletePrompt(Map<String, dynamic> prompt) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: DoomOneTheme.bg,
        title: Text(
          'Smazat prompt?',
          style: TextStyle(color: DoomOneTheme.red),
        ),
        content: Text(
          'Opravdu chceš smazat prompt "${prompt['category']}"?',
          style: TextStyle(color: DoomOneTheme.fg),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Zrušit', style: TextStyle(color: DoomOneTheme.base5)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: DoomOneTheme.red,
              foregroundColor: DoomOneTheme.bg,
            ),
            child: const Text('Smazat'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final db = await _db.database;
      await db.delete(
        'custom_prompts',
        where: 'id = ?',
        whereArgs: [prompt['id']],
      );

      await _loadPrompts();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Prompt byl smazán'),
            backgroundColor: DoomOneTheme.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NASTAVENÍ MOTIVACE'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Hlavička s popisem
                Container(
                  color: DoomOneTheme.bgAlt,
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: DoomOneTheme.blue),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Zde můžeš upravit AI prompty pro různé kategorie úkolů.',
                          style: TextStyle(
                            color: DoomOneTheme.fg,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: DoomOneTheme.base3),

                // Seznam promptů
                Expanded(
                  child: _prompts.isEmpty
                      ? Center(
                          child: Text(
                            'Žádné prompty.\nPřidej první!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: DoomOneTheme.base5,
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(8),
                          itemCount: _prompts.length,
                          itemBuilder: (context, index) {
                            final prompt = _prompts[index];
                            return _buildPromptCard(prompt);
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addPrompt,
        backgroundColor: DoomOneTheme.green,
        foregroundColor: DoomOneTheme.bg,
        child: const Icon(Icons.add),
      ),
    );
  }

  /// Vytvořit kartu s promptem
  Widget _buildPromptCard(Map<String, dynamic> prompt) {
    final tags = (prompt['tags'] as String)
        .replaceAll('[', '')
        .replaceAll(']', '')
        .replaceAll('"', '')
        .split(',')
        .map((t) => t.trim())
        .toList();

    return Card(
      color: DoomOneTheme.bgAlt,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: DoomOneTheme.base3),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Kategorie + akce
            Row(
              children: [
                Expanded(
                  child: Text(
                    prompt['category'] as String,
                    style: TextStyle(
                      color: DoomOneTheme.cyan,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.edit, color: DoomOneTheme.cyan, size: 20),
                  onPressed: () => _editPrompt(prompt),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 12),
                IconButton(
                  icon: Icon(Icons.delete, color: DoomOneTheme.red, size: 20),
                  onPressed: () => _deletePrompt(prompt),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Styl
            Text(
              'Styl: ${prompt['style']}',
              style: TextStyle(
                color: DoomOneTheme.base5,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 8),

            // Tagy
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: tags.map((tag) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: DoomOneTheme.magenta.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: DoomOneTheme.magenta, width: 1),
                  ),
                  child: Text(
                    tag,
                    style: TextStyle(
                      color: DoomOneTheme.magenta,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),

            // System prompt (zkrácený)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: DoomOneTheme.base2,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                prompt['system_prompt'] as String,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: DoomOneTheme.fg,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
