import 'package:flutter/material.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/services/database_helper.dart';

/// Tab s motivačními prompty
class PromptsTab extends StatefulWidget {
  const PromptsTab({super.key});

  @override
  State<PromptsTab> createState() => _PromptsTabState();
}

class _PromptsTabState extends State<PromptsTab> {
  final DatabaseHelper _db = DatabaseHelper();
  List<Map<String, dynamic>> _prompts = [];
  bool _isLoading = true;

  // Getter pro theme - dostupný ve všech metodách
  ThemeData get theme => Theme.of(context);

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
        backgroundColor: theme.appColors.bg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: theme.appColors.cyan, width: 2),
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
                    Icon(Icons.edit, color: theme.appColors.cyan, size: 28),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        'EDITOVAT PROMPT',
                        style: TextStyle(
                          color: theme.appColors.cyan,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: theme.appColors.base5),
                      onPressed: () => Navigator.of(context).pop(false),
                    ),
                  ],
                ),
                Divider(color: theme.appColors.base3, height: 24),

                _buildDialogField('Kategorie', categoryController, 'práce, domov, sport...'),
                const SizedBox(height: 16),
                _buildDialogField('System Prompt (Jak má AI mluvit)', promptController, 'Jsi můj motivační kouč...', maxLines: 10),
                const SizedBox(height: 16),
                _buildDialogField('Tagy (oddělené čárkou)', tagsController, 'práce, work, job, office'),
                const SizedBox(height: 16),
                _buildDialogField('Styl', styleController, 'profesionální, rodinný, sportovní...'),
                const SizedBox(height: 24),

                // Tlačítka
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text('Zrušit', style: TextStyle(color: theme.appColors.base5)),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () async {
                        final db = await _db.database;
                        final tagsList = tagsController.text.split(',').map((t) => '"${t.trim()}"').join(',');

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

                        if (context.mounted) Navigator.of(context).pop(true);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.appColors.cyan,
                        foregroundColor: theme.appColors.bg,
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

    if (result == true) {
      await _loadPrompts();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✅ Prompt byl úspěšně uložen'),
            backgroundColor: theme.appColors.green,
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
        backgroundColor: theme.appColors.bg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: theme.appColors.green, width: 2),
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
                Row(
                  children: [
                    Icon(Icons.add_circle, color: theme.appColors.green, size: 28),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        'NOVÝ PROMPT',
                        style: TextStyle(
                          color: theme.appColors.green,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: theme.appColors.base5),
                      onPressed: () => Navigator.of(context).pop(false),
                    ),
                  ],
                ),
                Divider(color: theme.appColors.base3, height: 24),

                _buildDialogField('Kategorie', categoryController, 'práce, domov, sport...'),
                const SizedBox(height: 16),
                _buildDialogField('System Prompt (Jak má AI mluvit)', promptController, 'Jsi můj motivační kouč...', maxLines: 10),
                const SizedBox(height: 16),
                _buildDialogField('Tagy (oddělené čárkou)', tagsController, 'práce, work, job, office'),
                const SizedBox(height: 16),
                _buildDialogField('Styl', styleController, 'profesionální, rodinný, sportovní...'),
                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text('Zrušit', style: TextStyle(color: theme.appColors.base5)),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () async {
                        if (categoryController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Kategorie nesmí být prázdná'),
                              backgroundColor: theme.appColors.red,
                            ),
                          );
                          return;
                        }

                        final db = await _db.database;
                        final tagsList = tagsController.text.split(',').map((t) => '"${t.trim()}"').join(',');

                        try {
                          await db.insert('custom_prompts', {
                            'category': categoryController.text.trim(),
                            'system_prompt': promptController.text.trim(),
                            'tags': '[$tagsList]',
                            'style': styleController.text.trim(),
                          });

                          if (context.mounted) Navigator.of(context).pop(true);
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Chyba: $e'),
                                backgroundColor: theme.appColors.red,
                              ),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.appColors.green,
                        foregroundColor: theme.appColors.bg,
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

    if (result == true) {
      await _loadPrompts();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✅ Prompt byl úspěšně přidán'),
            backgroundColor: theme.appColors.green,
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
        backgroundColor: theme.appColors.bg,
        title: Text('Smazat prompt?', style: TextStyle(color: theme.appColors.red)),
        content: Text(
          'Opravdu chceš smazat prompt "${prompt['category']}"?',
          style: TextStyle(color: theme.appColors.fg),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Zrušit', style: TextStyle(color: theme.appColors.base5)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.appColors.red,
              foregroundColor: theme.appColors.bg,
            ),
            child: const Text('Smazat'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final db = await _db.database;
      await db.delete('custom_prompts', where: 'id = ?', whereArgs: [prompt['id']]);

      await _loadPrompts();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('🗑️ Prompt byl smazán'),
            backgroundColor: theme.appColors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        // Info panel
        Container(
          color: theme.appColors.bgAlt,
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: theme.appColors.magenta),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Zde můžeš upravit AI prompty pro různé kategorie úkolů.',
                  style: TextStyle(color: theme.appColors.fg, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
        Divider(height: 1, color: theme.appColors.base3),

        // Seznam promptů
        Expanded(
          child: _prompts.isEmpty
              ? Center(
                  child: Text(
                    'Žádné prompty.\nPřidej první!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: theme.appColors.base5),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: _prompts.length,
                  itemBuilder: (context, index) => _buildPromptCard(_prompts[index]),
                ),
        ),

        // Add button (sticky bottom)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.appColors.bg,
            border: Border(top: BorderSide(color: theme.appColors.base3)),
          ),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _addPrompt,
              icon: const Icon(Icons.add),
              label: const Text('PŘIDAT NOVÝ PROMPT'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.appColors.green,
                foregroundColor: theme.appColors.bg,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPromptCard(Map<String, dynamic> prompt) {
    final tags = (prompt['tags'] as String)
        .replaceAll('[', '')
        .replaceAll(']', '')
        .replaceAll('"', '')
        .split(',')
        .map((t) => t.trim())
        .toList();

    return Card(
      color: theme.appColors.bgAlt,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: theme.appColors.base3),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    prompt['category'] as String,
                    style: TextStyle(
                      color: theme.appColors.cyan,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.edit, color: theme.appColors.cyan, size: 20),
                  onPressed: () => _editPrompt(prompt),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 12),
                IconButton(
                  icon: Icon(Icons.delete, color: theme.appColors.red, size: 20),
                  onPressed: () => _deletePrompt(prompt),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Styl: ${prompt['style']}',
              style: TextStyle(
                color: theme.appColors.base5,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: tags.map((tag) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.appColors.magenta.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: theme.appColors.magenta, width: 1),
                  ),
                  child: Text(
                    tag,
                    style: TextStyle(
                      color: theme.appColors.magenta,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.appColors.base2,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                prompt['system_prompt'] as String,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: theme.appColors.fg,
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

  Widget _buildDialogField(String label, TextEditingController controller, String hint, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: theme.appColors.fg,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: TextStyle(color: theme.appColors.fg),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: theme.appColors.base5),
            filled: true,
            fillColor: theme.appColors.base2,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: theme.appColors.base4),
            ),
          ),
        ),
      ],
    );
  }
}
