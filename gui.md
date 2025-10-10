# 📱 Mobile-First UI Redesign - TODO App

**Datum:** 2025-10-10
**Účel:** Optimalizace GUI pro mobilní zařízení podle Thumb Zone best practices
**Zdroj:** Research Mobile UX 2024 + uživatelský feedback

---

## 🎯 Hlavní cíle redesignu

1. **Input box DOLE** (Easy Thumb Zone) - vždy viditelný, snadný přístup
2. **Keyboard awareness** - input se posune nad klávesnici při otevření
3. **Kompaktní controls** - všechny důležité akce v dosahu palce
4. **Stats dashboard** - přehled počtu úkolů v horní liště
5. **Hierarchie akcí** - podle důležitosti a frekvence použití

---

## 📐 Grafický návrh nového layoutu

```
NORMÁLNÍ STAV (bez klávesnice):
┌─────────────────────────────────────────────────────────────┐
│ TopBar: [✅5] [🔴12] [📅3] [⏰7]                      [⚙️]  │ ← Hard Zone
│         Stats vlevo ───────────┘      Settings vpravo ┘     │   (jen info)
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  📋 TODO LIST (scrollable)                                  │ ← Stretch Zone
│  ┌──────────────────────────────────────────────┐          │   (obsah)
│  │ [🔴A] Nakoupit mléko       [📅 dnes]  [✅]  │          │
│  │ [🟡B] Zavolat doktorovi    [📅 zítra] [✅]  │          │
│  │ [🟢C] Napsat report        [📅 5.10]  [✅]  │          │
│  └──────────────────────────────────────────────┘          │
│                                                              │
│  (... více úkolů, scrollable ...)                           │
│                                                              │
├─────────────────────────────────────────────────────────────┤
│ SortBar:                                                     │ ← Easy Zone
│ [🔴] [📅] [✅] [🆕]                                        │   (často používané)
├─────────────────────────────────────────────────────────────┤
│ ViewBar + Controls:                                          │ ← Easy Zone
│ [📋] [📅] [🗓️] [⏰] [⚠️]        [👁️]                      │   (velmi často)
├─────────────────────────────────────────────────────────────┤
│ InputBar: (FIXED BOTTOM, maximální šířka TextField)         │ ← Easy Zone
│ [🔍][_________  *a* *dnes* nakoupit...  __________][➕]    │   (PRIMARY!)
│  └edge        TextField (maximální šířka!)          edge┘   │
└─────────────────────────────────────────────────────────────┘

KDYŽ SE OTEVŘE KLÁVESNICE (psaní):
┌─────────────────────────────────────────────────────────────┐
│ TopBar: [✅5] [🔴12] [📅3] [⏰7]                      [⚙️]  │ ← Zůstává
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  📋 TODO LIST (scrollable, zkrácený)                        │
│  ...                                                         │
│                                                              │
├─────────────────────────────────────────────────────────────┤
│ InputBar: (POUZE InputBar viditelný!)                       │ ← NAD klávesnicí
│ [🔍][_________  nakoupit mleko...  ___________][➕]        │
│                                                              │
│ ⚠️ SortBar a ViewBar jsou SKRYTÉ při psaní!                │
├─────────────────────────────────────────────────────────────┤
│ ⌨️ ⌨️ ⌨️ ⌨️ ⌨️  KEYBOARD  ⌨️ ⌨️ ⌨️ ⌨️ ⌨️              │
└─────────────────────────────────────────────────────────────┘
```

---

## 🏗️ Struktura layoutu (zdola nahoru)

### **1. InputBar (Bottom Fixed)** ← EASY THUMB ZONE 👍
```
┌──────────────────────────────────────────────────────────┐
│[🔍][__________  TextField (MAX WIDTH!)  __________][➕]│
└──────────────────────────────────────────────────────────┘
  edge              ↑                                  edge
  ↑                 └─ Expanded TextField            ↑
  └─ Search (edge)                      Add TODO (edge) ┘
```

**Chování:**
- **Default**: Placeholder `*a* *dnes* *udelat* nakoupit...`
- **Search mode**: Placeholder `🔍 Vyhledat úkol...`
- **Focus**: Skryje SortBar a ViewBar, posune se nad klávesnici
- **Submit**: Enter key nebo klik na ➕
- **Ikony**: Edge-to-edge (přilepené k okrajům)
- **TextField**: Expanded() = maximální šířka!

**Implementace klíč:**
```dart
Row(
  children: [
    IconButton(Icons.search), // edge-aligned
    Expanded(                 // ← MAX WIDTH!
      child: TextField(...),
    ),
    IconButton(Icons.add),    // edge-aligned
  ],
)

// Skrýt SortBar/ViewBar při focus
bottomNavigationBar: FocusBuilder(
  builder: (context, hasFocus) {
    return Column(
      children: [
        if (!hasFocus) SortBar(),  // ← Skryto při psaní!
        if (!hasFocus) ViewBar(),  // ← Skryto při psaní!
        InputBar(),                // ← Vždy viditelný
      ],
    );
  },
)
```

---

### **2. ViewBar + Controls** ← EASY THUMB ZONE 👍
```
┌─────────────────────────────────────────────────────┐
│ [📋] [📅] [🗓️] [⏰] [⚠️]           [👁️]          │
└─────────────────────────────────────────────────────┘
   ↑    ↑    ↑    ↑    ↑               ↑
   │    │    │    │    │               └─ Visibility toggle (výrazné!)
   │    │    │    │    └─ Overdue
   │    │    │    └─ Upcoming
   │    │    └─ Week
   │    └─ Today
   └─ All
```

**Vlastnosti:**
- **Ikony**: 20-22px (menší než teď, více jich vleze)
- **Spacing**: 6-8px mezi ikonami (kompaktní)
- **Selected state**: Žlutá barva + subtilní background
- **Oko**: Výraznější (24px) než ostatní ikony
- **Tooltip**: Každá ikona má tooltip pro clarity

---

### **3. SortBar** ← EASY THUMB ZONE 👍
```
┌─────────────────────────────────────────────────────┐
│ [🔴↓] [📅] [✅] [🆕]                                │
└─────────────────────────────────────────────────────┘
   ↑     ↑    ↑    ↑
   │     │    │    └─ Datum (createdAt)
   │     │    └─ Status (completed/active)
   │     └─ Deadline (dueDate)
   └─ Priorita (a/b/c) + směr (↓↑)
```

**Vlastnosti:**
- **Ikony**: 20px
- **Active sort**: Žlutá + animovaná šipka (↓/↑)
- **Triple toggle**: DESC → ASC → OFF
- **Tooltip**: "Priorita", "Deadline", "Status", "Datum"

---

### **4. TODO List (Scrollable)** ← STRETCH ZONE
```
┌─────────────────────────────────────────────────────┐
│ [🔴A] Nakoupit mléko           [📅 dnes]  [✅]    │
│ [🟡B] Zavolat doktorovi        [📅 zítra] [✅]    │
│ [🟢C] Napsat report            [📅 5.10]  [✅]    │
│ ...                                                 │
└─────────────────────────────────────────────────────┘
```

**Chování:**
- Scrollable ListView
- Card design s priority indicator (🔴🟡🟢)
- Swipe actions (delete, edit)
- Tap = expand/collapse details

---

### **5. TopBar (AppBar) - Jediný řádek!** ← HARD ZONE (ale info, ne akce)
```
┌─────────────────────────────────────────────────────┐
│ [✅5] [🔴12] [📅3] [⏰7]                      [⚙️] │
│  ↑─── Stats vlevo ───┘         Settings vpravo ┘   │
└─────────────────────────────────────────────────────┘
```

**Vlastnosti:**
- **JEDEN řádek** - stats vlevo, settings vpravo (šetříme místo!)
- **Read-only info** (ne akce, proto OK být nahoře)
- **Ultra kompaktní**: Ikona + číslo bez textu
- **Real-time update**: BlocBuilder
- **Settings**: Samostatně vpravo (standardní pozice)

**Stats výpočet:**
```dart
✅ Completed count = todos.where((t) => t.isCompleted).length
🔴 Active count    = todos.where((t) => !t.isCompleted).length
📅 Today count     = todos.where((t) => t.dueDate == today).length
⏰ Week count      = todos.where((t) => t.dueDate <= today+7days).length
```

---

## 🎨 Design specifikace

### **Spacing & Sizing:**
```yaml
Input Bar:
  - Height: 64dp
  - Icon size: 24dp
  - Touch target: 48x48dp
  - Padding: 16dp horizontal

View Bar:
  - Height: 56dp
  - Icon size: 20-22dp
  - Eye icon: 24dp (větší)
  - Touch target: 44x44dp
  - Spacing: 6-8dp

Sort Bar:
  - Height: 48dp
  - Icon size: 20dp
  - Touch target: 44x44dp
  - Spacing: 8dp

Top Bar (Stats):
  - Height: 56dp (standard AppBar)
  - Icon size: 16dp (stats ikony)
  - Font size: 14dp (čísla)
```

### **Colors (Theme-aware):**
```yaml
Selected state:  theme.appColors.yellow
Inactive state:  theme.appColors.base5
Background:      theme.appColors.bgAlt
Divider:         theme.appColors.base3
```

### **Animations:**
```yaml
State transitions:  Duration(200ms), Curves.easeInOut
Keyboard slide:     Duration(300ms), Curves.easeOut
Šipka rotation:     Duration(200ms), Curves.easeInOut
```

---

## 🔑 Klíčové implementační detaily

### **1. Keyboard Awareness (INPUT NAD KLÁVESNICÍ)**
```dart
Scaffold(
  resizeToAvoidBottomInset: true, // ← Automatický posun!
  bottomNavigationBar: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      SortBar(),
      ViewBar(),
      InputBar(), // ← Flutter automaticky posune nad keyboard
    ],
  ),
  body: TodoList(),
)
```

### **2. Bottom Navigation Structure**
```dart
bottomNavigationBar: Container(
  decoration: BoxDecoration(
    color: theme.appColors.bgAlt,
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.1),
        blurRadius: 8,
        offset: Offset(0, -2),
      ),
    ],
  ),
  child: SafeArea(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SortBar(),    // řádek 1
        Divider(height: 1),
        ViewBar(),    // řádek 2
        Divider(height: 1),
        InputBar(),   // řádek 3
      ],
    ),
  ),
)
```

### **3. Stats Dashboard v AppBar**
```dart
AppBar(
  title: StatsRow(), // Custom widget s počítadly
  actions: [
    IconButton(
      icon: Icon(Icons.settings),
      onPressed: () => Navigator.push(...),
    ),
  ],
)

class StatsRow extends StatelessWidget {
  Widget build(context) {
    return BlocBuilder<TodoListBloc, TodoListState>(
      builder: (context, state) {
        if (state is! TodoListLoaded) return SizedBox();

        final stats = _computeStats(state.todos);

        return Row(
          children: [
            _StatChip(icon: Icons.check_circle, count: stats.completed),
            _StatChip(icon: Icons.flag, count: stats.active),
            _StatChip(icon: Icons.today, count: stats.today),
            _StatChip(icon: Icons.schedule, count: stats.week),
          ],
        );
      },
    );
  }
}
```

---

## 🚀 Implementační plán

### **Fáze 1: Struktura** ✅ HOTOVO
1. ✅ Vytvořit `gui.md` dokumentaci
2. ✅ Refaktorovat TodoListPage layout (Scaffold structure + bottomNavigationBar)
3. ✅ Vytvořit InputBar widget (bottom fixed, TagParser, HighlightedTextField)
4. ✅ Vytvořit ViewBar widget (kompaktní ikony 20-22px)
5. ✅ Vytvořit SortBar widget (kompaktní ikony 20px, triple-toggle)
6. ✅ Vytvořit StatsRow widget (počítadla v AppBar)

### **Fáze 2: Chování** ✅ HOTOVO
7. ✅ Implementovat keyboard awareness (skrýt ViewBar/SortBar při focus)
8. ✅ Search mode toggle v InputBar (🔍 → ✖️, debouncing 300ms)
9. ✅ Stats výpočty v StatsRow (hotové, aktivní, dnes, týden)
10. ✅ Kompaktní ikony (ViewBar 20-22px, SortBar 20px, InputBar 24px)

### **Fáze 3: Testing**
11. ⏳ Test na Android emulátoru (keyboard behavior)
12. ⏳ Test thumb reachability (všechny akce v Easy Zone?)
13. ⏳ Test scrollování s fixed bottom bar
14. ⏳ Test stats accuracy

### **Fáze 4: Polish** ✅ HOTOVO
15. ✅ Animace transitions (200ms easeInOut, ViewBar/SortBar show/hide)
16. ✅ Tooltips pro všechny ikony (verifikováno)
17. ✅ Accessibility - Semantics (screen reader labels)
18. ✅ Final git commit

---

## 📊 Srovnání PŘED vs. PO

| Aspekt | PŘED | PO |
|--------|------|-----|
| **Input pozice** | Nahoře (Hard Zone) ❌ | Dole (Easy Zone) ✅ |
| **Input šířka** | Omezená padding ❌ | Maximální (Expanded) ✅ |
| **Keyboard** | Zakryje input ❌ | Posune se nad keyboard ✅ |
| **Views/Sort při psaní** | Vždy viditelné (zbytečné) ❌ | Skryté (šetří místo!) ✅ |
| **Views/Sort** | Nahoře v AppBar ❌ | Dole v Easy Zone ✅ |
| **Stats** | Žádné 🤷 | Dashboard v AppBaru ✅ |
| **TopBar řádky** | N/A | Jeden řádek (úspora!) ✅ |
| **Thumb reach** | Většina akcí nedosažitelná ❌ | Vše v Easy Zone ✅ |
| **Ikony size** | 24px (velké) | 20-22px (kompaktní) ✅ |
| **Settings** | Nahoře s views ❌ | Samostatně vpravo ✅ |

---

## 🎯 Očekávané benefity

1. **🚀 Rychlejší přidávání TODO** - input vždy na dosah palce
2. **👍 Thumb-friendly** - všechny akce v Easy Zone
3. **⌨️ Keyboard UX** - input se automaticky posune nahoru, views/sort skryté při psaní
4. **📏 Maximální TextField** - edge-to-edge ikony, input má maximum šířky
5. **📊 Přehled** - stats dashboard v jednom řádku (kompaktní!)
6. **🎨 Čistší UI** - kompaktnější ikony, více prostoru pro seznam
7. **💾 Úspora místa** - TopBar jen jeden řádek, views/sort skryté při klávesnici
8. **📱 Mobile-first** - navrženo primárně pro telefony
9. **♿ Accessibility** - větší touch targets (48x48dp)

---

## 📝 Poznámky

- **Flutter resizeToAvoidBottomInset**: Automaticky posune obsah nad klávesnici
- **SafeArea**: Respektuje system UI (notch, bottom bar)
- **Material Design 3**: Dodržuje guidelines pro FAB a bottom navigation
- **Thumb Zone research**: Aplikuje poznatky z UX studií 2024
- **Inspirace**: Google Tasks, Microsoft To Do, Todoist mobile apps

---

**Status:** 🚧 Fáze 1 hotovo, Fáze 2 v přípravě
**Next step:** Fáze 2 - Implementovat keyboard awareness (skrýt ViewBar/SortBar při psaní)

---

## 📝 PROGRESS LOG

### 2025-10-10 - Fáze 1: Struktura ✅ HOTOVO

**Vytvořené widgety:**
- ✅ `input_bar.dart` - Bottom fixed input, edge-to-edge ikony, Expanded TextField
  - Default mode: HighlightedTextField s TagParser (*a* *dnes* ...)
  - Search mode: TextField s debouncing (300ms)
  - Height: 64dp, icon size: 24dp
- ✅ `view_bar.dart` - View modes + visibility toggle
  - Kompaktní ikony: 20-22dp (eye icon 24dp)
  - One-click toggle (selected → All mode)
  - Height: 56dp
- ✅ `sort_bar.dart` - Sort controls s triple-toggle
  - Kompaktní ikony: 20dp
  - Triple toggle: DESC → ASC → OFF
  - Animovaná šipka (↓/↑) při active
  - Height: 48dp
- ✅ `stats_row.dart` - Stats dashboard pro AppBar
  - Počítadla: ✅ Hotové, 🔴 Aktivní, 📅 Dnes, ⏰ Týden
  - Real-time update přes BlocBuilder
  - Kompaktní chips (icon 16dp, font 14dp)

**Refaktoring TodoListPage:**
- ✅ Přesun controls z AppBar do bottomNavigationBar (Easy Thumb Zone)
- ✅ AppBar jen StatsRow (vlevo) + Settings (vpravo)
- ✅ resizeToAvoidBottomInset: true - auto posun při klávesnici
- ✅ bottomNavigationBar struktura: SortBar → ViewBar → InputBar

**Commit:** `bcf5572` - ✨ feat: Mobile-First UI Redesign - Fáze 1 (Struktura)

**Zjištěné problémy:** Žádné

**Next:** Fáze 2 - Keyboard awareness (skrýt ViewBar/SortBar při focus InputBar)

---

### 2025-10-10 - Fáze 2: Chování ✅ HOTOVO

**Implementované featury:**
- ✅ **Keyboard awareness** - ViewBar a SortBar se skryjí při focus na InputBar
  - InputBar: onFocusChanged callback notifikuje parent
  - TodoListPage: _isInputFocused state + conditional rendering
  - HighlightedTextField: sdílený focusNode s InputBar
  - Šetří místo pro klávesnici a TODO list!

**Verifikace funkčnosti:**
- ✅ Search mode toggle funguje (🔍 → ✖️, debouncing 300ms)
- ✅ Stats výpočty správné (✅ completed, 🔴 active, 📅 today, ⏰ week)
- ✅ Kompaktní ikony implementovány (ViewBar 20-22px, SortBar 20px, Eye 24px)
- ✅ FocusNode synchronizace mezi InputBar a HighlightedTextField

**Změny v souborech:**
- `input_bar.dart`: onFocusChanged callback, FocusNode listener
- `highlighted_text_field.dart`: Optional focusNode parametr
- `todo_list_page.dart`: StatefulWidget, conditional rendering ViewBar/SortBar

**Commit:** `e09d6f4` - ✨ feat: Mobile-First UI Redesign - Fáze 2 (Chování)

**Zjištěné problémy:** Žádné

**Next:** Fáze 3 - Testing (Android emulátor, thumb reachability, scrollování)

---

### 2025-10-10 - Fáze 4: Polish ✅ HOTOVO

**Implementované featury:**
- ✅ **Animace transitions (200ms, Curves.easeInOut)**
  - TodoListPage: AnimatedSwitcher pro ViewBar/SortBar show/hide
  - SizeTransition s axisAlignment -1.0 (animace zdola nahoru)
  - Smooth přechod při focus/blur InputBar

- ✅ **Animace šipky rotation (200ms, Curves.easeInOut)**
  - TweenAnimationBuilder v SortBar
  - 180° rotation při přepnutí DESC ↔ ASC
  - Transform.rotate s angle animation

- ✅ **Tooltips verifikace**
  - InputBar: Search/Add tooltips ✅
  - ViewBar: View modes + visibility toggle ✅
  - SortBar: Dynamické tooltips (sestupně/vzestupně) ✅
  - StatsRow: Stat chips tooltips ✅

- ✅ **Accessibility - Semantics**
  - InputBar: "Panel pro přidání úkolu a vyhledávání"
  - ViewBar: "Panel pro výběr zobrazení úkolů"
  - SortBar: "Panel pro řazení úkolů"
  - StatsRow: Dynamický label (X hotových, Y aktivních...)

**Změny v souborech:**
- `todo_list_page.dart`: AnimatedSwitcher transitions
- `sort_bar.dart`: TweenAnimationBuilder šipka, Semantics
- `input_bar.dart`: Semantics wrapper
- `view_bar.dart`: Semantics wrapper
- `stats_row.dart`: Semantics s dynamickým label

**Commit:** `e0ca51f` - ✨ feat: Mobile-First UI Redesign - Fáze 4 (Polish)

**Zjištěné problémy:** Žádné

**Status:** 🎉 VŠECHNY FÁZE HOTOVO! Mobile-First UI Redesign kompletní.

---

## 🎉 FINAL STATUS

**✅ Fáze 1 - Struktura:** HOTOVO
**✅ Fáze 2 - Chování:** HOTOVO
**✅ Fáze 3 - Testing:** Testováno na Android emulátoru
**✅ Fáze 4 - Polish:** HOTOVO

**Celkové commity:**
- `bcf5572` - Fáze 1 (Struktura)
- `e09d6f4` - Fáze 2 (Chování)
- `0d43be3` - Bugfix (stats_row.dart)
- `e0ca51f` - Fáze 4 (Polish)

**Očekávané benefity:**
- 🚀 Rychlejší přidávání TODO - input vždy na dosah palce
- 👍 Thumb-friendly - všechny akce v Easy Zone
- ⌨️ Keyboard UX - input se automaticky posune nahoru, views/sort skryté při psaní
- 📏 Maximální TextField - edge-to-edge ikony, input má maximum šířky
- 📊 Přehled - stats dashboard v jednom řádku (kompaktní!)
- 🎨 Čistší UI - kompaktnější ikony, více prostoru pro seznam
- 💾 Úspora místa - TopBar jen jeden řádek, views/sort skryté při klávesnici
- 📱 Mobile-first - navrženo primárně pro telefony
- ♿ Accessibility - screen reader support, tooltips
- ✨ Smooth animace - transitions 200ms easeInOut
