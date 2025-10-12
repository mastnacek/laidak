# AI Settings Tab Refactoring - Implementační plán

## 🎯 Cíl

Rozdělit AI nastavení na **2 samostatné sekce**:

1. **Motivace** - uncensored, kreativní model (temp 0.9, 200 tokens)
   - Používá se pro generování motivačních zpráv
   - Doporučený model: `mistralai/mistral-medium` (uncensored)

2. **Rozdělení úkolů (AI Split)** - chytrý, JSON-ready model (temp 0.3, 1000 tokens)
   - Používá se pro seriózní práci - rozdělení úkolů na podúkoly
   - Doporučený model: `anthropic/claude-3.5-sonnet` (JSON-capable, low temp)

---

## 📋 Co je hotovo (commit `1e634e2`)

✅ **SettingsState** - přidáno 6 nových fieldů:
- `openRouterApiKey` (String?)
- `aiMotivationModel` (String, default: `mistralai/mistral-medium`)
- `aiMotivationTemperature` (double, default: 0.9)
- `aiMotivationMaxTokens` (int, default: 200)
- `aiTaskModel` (String, default: `anthropic/claude-3.5-sonnet`)
- `aiTaskTemperature` (double, default: 0.3)
- `aiTaskMaxTokens` (int, default: 1000)

✅ **SettingsCubit** - přidáno 7 nových metod:
- `saveOpenRouterApiKey(String apiKey)`
- `setMotivationModel(String model)`
- `setMotivationTemperature(double temperature)`
- `setMotivationMaxTokens(int maxTokens)`
- `setTaskModel(String model)`
- `setTaskTemperature(double temperature)`
- `setTaskMaxTokens(int maxTokens)`

✅ **DatabaseHelper** - DB verze 14:
- Přidány sloupce do `settings` table
- Migrace pro existující uživatele
- Defaults v `_insertDefaultSettings()`

---

## 🚧 Co zbývá udělat

### KROK 1: Refaktorovat `ai_settings_tab.dart` (933 řádků → rozdělit na sekce)

**Současný problém**:
- Soubor má 933 řádků - příliš dlouhý pro jednu třídu
- Pouze jedno nastavení modelu (pro motivaci)
- Chybí Task Model nastavení

**Navržené řešení**:

#### 1.1 Přidat nové state variables (řádek ~18-30)

```dart
class _AISettingsTabState extends State<AISettingsTab> {
  final DatabaseHelper _db = DatabaseHelper();

  // ===== MOTIVATION MODEL =====
  final TextEditingController _motivationTempController = TextEditingController();
  final TextEditingController _motivationTokensController = TextEditingController();
  String? _selectedMotivationModel;

  // ===== TASK MODEL =====
  final TextEditingController _taskTempController = TextEditingController();
  final TextEditingController _taskTokensController = TextEditingController();
  String? _selectedTaskModel;

  // ===== SHARED =====
  final TextEditingController _apiKeyController = TextEditingController();
  bool _obscureApiKey = true;
  bool _isLoading = true;
  bool _isEnabled = true;

  // Model dropdown state
  List<OpenRouterModel> _availableModels = [];
  bool _isLoadingModels = false;

  // Doporučené modely podle účelu
  final List<String> _motivationModels = [
    'mistralai/mistral-medium',
    'mistralai/mistral-large',
    'anthropic/claude-3-opus', // uncensored capable
    'openai/gpt-4o',
  ];

  final List<String> _taskModels = [
    'anthropic/claude-3.5-sonnet', // JSON king
    'anthropic/claude-3-opus',
    'openai/gpt-4o',
    'google/gemini-pro-1.5',
  ];
```

#### 1.2 Update `dispose()` (řádek ~56-61)

```dart
@override
void dispose() {
  _apiKeyController.dispose();
  _motivationTempController.dispose();
  _motivationTokensController.dispose();
  _taskTempController.dispose();
  _taskTokensController.dispose();
  super.dispose();
}
```

#### 1.3 Update `_loadSettings()` (řádek ~64-76)

```dart
Future<void> _loadSettings() async {
  setState(() => _isLoading = true);
  final settings = await _db.getSettings();

  setState(() {
    // Shared
    _apiKeyController.text = settings['openrouter_api_key'] as String? ?? '';
    _isEnabled = (settings['enabled'] as int) == 1;

    // Motivation
    _selectedMotivationModel = settings['ai_motivation_model'] as String;
    _motivationTempController.text = (settings['ai_motivation_temperature'] as double).toString();
    _motivationTokensController.text = (settings['ai_motivation_max_tokens'] as int).toString();

    // Task
    _selectedTaskModel = settings['ai_task_model'] as String;
    _taskTempController.text = (settings['ai_task_temperature'] as double).toString();
    _taskTokensController.text = (settings['ai_task_max_tokens'] as int).toString();

    _isLoading = false;
  });
}
```

#### 1.4 Update `_saveSettings()` (řádek ~322-350)

```dart
Future<void> _saveSettings() async {
  try {
    await _db.updateSettings(
      // Shared
      openRouterApiKey: _apiKeyController.text.trim(),
      enabled: _isEnabled,

      // Motivation
      aiMotivationModel: _selectedMotivationModel?.trim() ?? 'mistralai/mistral-medium',
      aiMotivationTemperature: double.tryParse(_motivationTempController.text) ?? 0.9,
      aiMotivationMaxTokens: int.tryParse(_motivationTokensController.text) ?? 200,

      // Task
      aiTaskModel: _selectedTaskModel?.trim() ?? 'anthropic/claude-3.5-sonnet',
      aiTaskTemperature: double.tryParse(_taskTempController.text) ?? 0.3,
      aiTaskMaxTokens: int.tryParse(_taskTokensController.text) ?? 1000,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('✅ Nastavení bylo úspěšně uloženo'),
          backgroundColor: theme.appColors.green,
        ),
      );
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Chyba při ukládání: $e'),
          backgroundColor: theme.appColors.red,
        ),
      );
    }
  }
}
```

#### 1.5 Update `build()` - Rozdělit UI na 2 sekce (řádek ~359-911)

**Nová struktura UI**:

```dart
return SingleChildScrollView(
  padding: const EdgeInsets.all(16),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // ===== INFO PANEL =====
      _buildInfoPanel(),
      const SizedBox(height: 24),

      // ===== ENABLE/DISABLE SWITCH =====
      _buildEnableSwitch(),
      const SizedBox(height: 24),

      // ===== API KEY (SHARED) =====
      _buildSectionTitle('🔑 OpenRouter API Klíč (společný pro oba modely)'),
      const SizedBox(height: 8),
      _buildApiKeyField(),
      const SizedBox(height: 32),

      // ===== SEKCE 1: MOTIVACE =====
      _buildDivider('💬 MODEL PRO MOTIVACI', 'Uncensored, kreativní'),
      const SizedBox(height: 16),
      _buildMotivationSection(),
      const SizedBox(height: 32),

      // ===== SEKCE 2: TASK SPLIT =====
      _buildDivider('🧠 MODEL PRO ROZDĚLENÍ ÚKOLŮ', 'Seriózní práce, JSON-ready'),
      const SizedBox(height: 16),
      _buildTaskSection(),
      const SizedBox(height: 32),

      // ===== DEBUG (optional) =====
      _buildDebugSection(),
      const SizedBox(height: 32),

      // ===== SAVE BUTTON =====
      _buildSaveButton(),
      const SizedBox(height: 16),
    ],
  ),
);
```

#### 1.6 Vytvořit helper metody pro UI komponenty

```dart
// Divider s popisem sekce
Widget _buildDivider(String title, String subtitle) {
  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: theme.appColors.cyan.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: theme.appColors.cyan, width: 2),
    ),
    child: Row(
      children: [
        Icon(Icons.settings, color: theme.appColors.cyan, size: 28),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: theme.appColors.cyan,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  color: theme.appColors.base5,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

// Sekce pro Motivation model
Widget _buildMotivationSection() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _buildSectionTitle('🤖 Model'),
      const SizedBox(height: 8),
      _buildModelDropdown(
        selectedModel: _selectedMotivationModel,
        onChanged: (value) => setState(() => _selectedMotivationModel = value),
        recommendedModels: _motivationModels,
      ),
      const SizedBox(height: 16),

      _buildSectionTitle('🌡️ Temperature (Kreativita)'),
      const SizedBox(height: 8),
      _buildTemperatureField(_motivationTempController),
      const SizedBox(height: 16),

      _buildSectionTitle('📏 Max Tokens'),
      const SizedBox(height: 8),
      _buildTokensField(_motivationTokensController),
      const SizedBox(height: 16),

      // Doporučení
      _buildRecommendationBox(
        '💡 Doporučení pro motivaci',
        [
          'Model: mistralai/mistral-medium (uncensored)',
          'Temperature: 0.9 (kreativní)',
          'Max tokens: 200 (krátké zprávy)',
        ],
      ),
    ],
  );
}

// Sekce pro Task model
Widget _buildTaskSection() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _buildSectionTitle('🤖 Model'),
      const SizedBox(height: 8),
      _buildModelDropdown(
        selectedModel: _selectedTaskModel,
        onChanged: (value) => setState(() => _selectedTaskModel = value),
        recommendedModels: _taskModels,
      ),
      const SizedBox(height: 16),

      _buildSectionTitle('🌡️ Temperature (Přesnost)'),
      const SizedBox(height: 8),
      _buildTemperatureField(_taskTempController),
      const SizedBox(height: 16),

      _buildSectionTitle('📏 Max Tokens'),
      const SizedBox(height: 8),
      _buildTokensField(_taskTokensController),
      const SizedBox(height: 16),

      // Doporučení
      _buildRecommendationBox(
        '💡 Doporučení pro rozdělení úkolů',
        [
          'Model: anthropic/claude-3.5-sonnet (JSON expert)',
          'Temperature: 0.3 (přesný)',
          'Max tokens: 1000 (delší odpovědi)',
        ],
      ),
    ],
  );
}

// Recommendation box
Widget _buildRecommendationBox(String title, List<String> points) {
  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: theme.appColors.blue.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: theme.appColors.blue, width: 1),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: theme.appColors.blue,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...points.map((point) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            children: [
              Icon(Icons.check_circle, color: theme.appColors.blue, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  point,
                  style: TextStyle(
                    color: theme.appColors.fg,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        )),
      ],
    ),
  );
}
```

#### 1.7 Refaktorovat `_buildModelDropdown()` - přidat parametry

```dart
Widget _buildModelDropdown({
  required String? selectedModel,
  required ValueChanged<String?> onChanged,
  required List<String> recommendedModels,
}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    decoration: BoxDecoration(
      color: theme.appColors.base2,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: theme.appColors.base4),
    ),
    child: Row(
      children: [
        Expanded(
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _availableModels.any((m) => m.id == selectedModel) ? selectedModel : null,
              isExpanded: true,
              dropdownColor: theme.appColors.base2,
              style: TextStyle(
                color: theme.appColors.fg,
                fontFamily: 'monospace',
                fontSize: 14,
              ),
              hint: Text(
                selectedModel ?? 'Vyber model',
                style: TextStyle(
                  color: theme.appColors.fg,
                  fontFamily: 'monospace',
                ),
                overflow: TextOverflow.ellipsis,
              ),
              items: _buildModelDropdownItems(),
              onChanged: (value) {
                if (value == null) {
                  _showCustomModelDialog(onChanged);
                } else if (!value.startsWith('__')) {
                  onChanged(value);
                }
              },
            ),
          ),
        ),
        if (_isLoadingModels)
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
        else
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            tooltip: 'Načíst modely z OpenRouter API',
            onPressed: _fetchModels,
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(),
          ),
      ],
    ),
  );
}
```

#### 1.8 Update `_showCustomModelDialog()` - přijímá callback

```dart
Future<void> _showCustomModelDialog(ValueChanged<String?> onChanged) async {
  // ... existing dialog code ...

  if (result != null && result.isNotEmpty) {
    onChanged(result);
  }
}
```

---

### KROK 2: Update `AiSplitCubit` - použít `taskModel` místo `aiModel`

**Soubor**: `lib/features/ai_split/presentation/cubit/ai_split_cubit.dart`

**Změny**:

```dart
// PŘED:
final settings = state.settingsState;
final model = settings.aiMotivationModel; // ❌ ŠPATNĚ - používá motivation model

// PO:
final settings = state.settingsState;
final model = settings.aiTaskModel; // ✅ SPRÁVNĚ - používá task model
final temperature = settings.aiTaskTemperature;
final maxTokens = settings.aiTaskMaxTokens;
```

**Konkrétní místo v kódu** (najít pomocí grep):
```bash
grep -n "aiMotivationModel\|settings.ai" lib/features/ai_split/presentation/cubit/ai_split_cubit.dart
```

---

### KROK 3: Přidat tooltips s doporučenými modely

**Kde**: V `ai_settings_tab.dart`, v sekci "Quick select"

**Současný stav** (řádek ~551-592):
- Zobrazují se jen názvy modelů
- Chybí informace o účelu

**Navržené řešení**:

```dart
// Quick select s tooltips
Wrap(
  spacing: 8,
  runSpacing: 8,
  children: recommendedModels.map((model) {
    final isSelected = selectedModel == model;
    final tooltip = _getModelTooltip(model);

    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: () => onChanged(model),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.appColors.cyan.withValues(alpha: 0.2)
                : theme.appColors.base2,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isSelected ? theme.appColors.cyan : theme.appColors.base4,
              width: 1,
            ),
          ),
          child: Text(
            model.split('/').last,
            style: TextStyle(
              color: isSelected ? theme.appColors.cyan : theme.appColors.base5,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }).toList(),
);
```

**Helper metoda**:

```dart
String _getModelTooltip(String model) {
  // Motivace modely
  if (model == 'mistralai/mistral-medium') {
    return '💬 Uncensored, skvělý pro kreativní motivaci';
  }

  // Task modely
  if (model == 'anthropic/claude-3.5-sonnet') {
    return '🧠 JSON expert, přesný a spolehlivý';
  }

  if (model == 'anthropic/claude-3-opus') {
    return '🚀 Nejsilnější model, nejlepší reasoning';
  }

  if (model == 'openai/gpt-4o') {
    return '⚡ Rychlý a levný, dobrá volba';
  }

  return 'Populární model pro AI úkoly';
}
```

---

### KROK 4: Manuální testing checklist

#### 4.1 Settings UI test
- [ ] Otevřít Settings → AI tab
- [ ] Zkontrolovat že se zobrazují 2 sekce (Motivace + Task)
- [ ] Změnit Motivation model → uložit → reload → verify
- [ ] Změnit Task model → uložit → reload → verify
- [ ] Změnit temperature pro oba → verify range 0.0-2.0
- [ ] Změnit max tokens pro oba → verify range 1-4000
- [ ] API klíč se sdílí mezi oběma modely

#### 4.2 Motivace test
- [ ] Otevřít TODO item → kliknout na motivaci
- [ ] Verify že používá `aiMotivationModel`
- [ ] Verify že používá `aiMotivationTemperature`
- [ ] Verify že používá `aiMotivationMaxTokens`

#### 4.3 AI Split test
- [ ] Otevřít TODO item → kliknout na AI Split (🤖)
- [ ] Verify že používá `aiTaskModel`
- [ ] Verify že používá `aiTaskTemperature`
- [ ] Verify že používá `aiTaskMaxTokens`
- [ ] Verify že vrací validní JSON

#### 4.4 Edge cases
- [ ] Co když není API klíč? → Show error
- [ ] Co když změním model na neexistující? → Fallback na default
- [ ] Co když temperature > 2.0? → Validace v cubit

---

## 📝 Poznámky

### Proč 2 různé modely?

1. **Motivace (uncensored, temp 0.9)**:
   - Kreativní, emocionální
   - Může být "odvázanější", subjektivní
   - Krátké zprávy (200 tokens)
   - Modelů: Mistral Medium (uncensored variant)

2. **Task Split (JSON-ready, temp 0.3)**:
   - Přesný, konzistentní
   - Musí vracet validní JSON
   - Delší odpovědi (1000 tokens)
   - Model: Claude 3.5 Sonnet (nejlepší JSON support)

### Doporučené modely

**Pro motivaci**:
- `mistralai/mistral-medium` - uncensored, kreativní ⭐
- `anthropic/claude-3-opus` - emocionálně inteligentní
- `openai/gpt-4o` - rychlý, levný

**Pro task split**:
- `anthropic/claude-3.5-sonnet` - JSON king ⭐
- `anthropic/claude-3-opus` - nejlepší reasoning
- `google/gemini-pro-1.5` - velký context window

---

## 🚀 Implementační kroky (v nové session)

1. **Otevřít `ai_settings_tab.dart`**
2. **Refaktorovat podle kroků 1.1 - 1.8**
3. **Commit**: `✨ feat: AI Settings Tab - split Motivation + Task models`
4. **Update `AiSplitCubit`** - použít `taskModel`
5. **Commit**: `🐛 fix: AiSplitCubit uses taskModel instead of motivationModel`
6. **Přidat tooltips** - podle KROK 3
7. **Commit**: `🎨 style: Add model tooltips with recommendations`
8. **Manuální test** - podle KROK 4
9. **Final commit**: `✅ test: Manual testing AI Settings passed`

---

## 🎯 Výsledek

Po dokončení bude:
- ✅ 2 samostatné sekce v Settings (Motivace + Task)
- ✅ Každá sekce má vlastní model, temp, max_tokens
- ✅ API klíč sdílený (1 input field)
- ✅ Doporučené modely pro každý účel
- ✅ Tooltips vysvětlující účel modelů
- ✅ AiSplitCubit používá správný model (task)
- ✅ Vše otestováno manuálně

---

## 📊 PROGRESS LOG (Session 2025-01-12)

### ✅ Dokončeno (commit `952f7fe`):

**KROK 1.1-1.3**: State variables + načítání settings
- ✅ Přidány controllery pro Motivation: `_motivationTempController`, `_motivationTokensController`, `_selectedMotivationModel`
- ✅ Přidány controllery pro Task: `_taskTempController`, `_taskTokensController`, `_selectedTaskModel`
- ✅ Listy `_motivationModels` a `_taskModels` s doporučenými modely
- ✅ Update `dispose()` - všech 6 controllerů
- ✅ Update `_loadSettings()` - načítání z `openrouter_api_key`, `ai_motivation_*`, `ai_task_*`

**KROK 1.4**: Update _saveSettings()
- ✅ Ukládání do správných DB sloupců (motivation + task separate)
- ✅ Správné defaults (motivation: temp 0.9, 200 tokens; task: temp 0.3, 1000 tokens)

**Doplňkové opravy**:
- ✅ Fix `_showCustomModelDialog()` - přijímá callback jako parametr
- ✅ Fix `_fetchModels()` - fallback používá sloučení `_motivationModels` + `_taskModels`

### ⚠️ Rozpracováno:

**KROK 1.5-1.8**: Refaktoring build() - **NEDOKONČENO**
- ✅ Build() metoda má novou strukturu (volá helper metody)
- ❌ Helper metody **NEJSOU dokončeny** - soubor obsahuje starý linter kód
- ❌ Soubor má ~520 řádků starého kódu používajícího neexistující proměnné:
  - `_selectedModel` (neexistuje, mělo by být `_selectedMotivationModel` / `_selectedTaskModel`)
  - `_temperatureController` (neexistuje, mělo by být `_motivationTempController` / `_taskTempController`)
  - `_maxTokensController` (neexistuje, mělo by být `_motivationTokensController` / `_taskTokensController`)
  - `_popularModels` (neexistuje, mělo by být `_motivationModels` / `_taskModels`)

**Současný stav souboru `ai_settings_tab.dart`**:
- Řádky 1-379: ✅ OK (nové state variables, fixed metody)
- Řádky 380-428: ✅ OK (nová build() struktura)
- Řádky 429-519: ❌ PROBLÉM - starý linter kód (používá neexistující proměnné)
- Potřeba: Kompletně smazat řádky 459-961 a nahradit novými helper metodami

### 🔴 CO ZBÝVÁ V NOVÉ SESSION:

**Priorita 1: Dokončit KROK 1.5-1.8** (~2-3 hodiny)
1. Smazat celý starý kód od řádku 459 do konce souboru
2. Implementovat helper metody podle plánu v aii.md:
   - `_buildEnableSwitch()`
   - `_buildApiKeyField()`
   - `_buildDivider(String title, String subtitle)`
   - `_buildMotivationSection()`
   - `_buildTaskSection()`
   - `_buildModelDropdown({required selectedModel, required onChanged, required recommendedModels})`
   - `_buildTemperatureField(TextEditingController controller)`
   - `_buildTokensField(TextEditingController controller)`
   - `_buildRecommendationBox(String title, List<String> points)`
   - `_buildDebugSection()`
   - `_buildSaveButton()`
   - `_buildSectionTitle(String title)` - **už existuje, nech**
   - `_getTemperatureLabel()` - **potřeba 2 verze** (motivation + task)

**Priorita 2: KROK 2** (~15 min)
- Update `AiSplitCubit` - použít `aiTaskModel` místo `aiMotivationModel`

**Priorita 3: KROK 3** (~30 min)
- Přidat tooltips s doporučenými modely

**Priorita 4: KROK 4** (~30 min)
- Manuální testing

**Očekávaný celkový čas**: 3-4 hodiny

### 📝 Poznámky pro další session:

1. **Soubor je v broken stavu** - build() volá helper metody které neexistují nebo jsou broken
2. **Nelze spustit** - compiler errors kvůli neexistujícím proměnným
3. **Strategie**: Nejprve smazat všechen broken kód (řádky 459-961), pak postupně přidat nové helper metody
4. **Tokeny**: Zbývalo ~70k, což stačí na dokončení
5. **Testing**: Po dokončení KROK 1.5-1.8 udělat commit a manuálně otestovat v emulatoru

---

**Připraveno pro pokračování v nové session! 🚀**
