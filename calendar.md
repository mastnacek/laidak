# Calendar Integration - TableCalendar Package

**Datum**: 2025-10-14
**Package**: [table_calendar](https://pub.dev/packages/table_calendar) v3.2.0
**Status**: Plánováno - analýza dokončena

---

## 📊 Package Info

- **GitHub Stars**: 1.92k ⭐
- **Pub Likes**: 3.22k
- **Downloads (30 dní)**: 478.3k
- **Verze**: 3.2.0
- **Null Safety**: ✅ Ano
- **Dart 3**: ✅ Podporováno
- **Platformy**: Android, iOS, Web, macOS, Windows, Linux

**Používají**: AppFlowy, Taskez, Chrono, OpenNutriTracker

---

## 🎯 Proč Implementovat?

Calendar view je **killer feature** pro TODO aplikace:

1. **Vizuální plánování** - celý měsíc najednou (ne jen list)
2. **Rychlé přeplánování** - tap na den → změníš deadline
3. **Workload overview** - vidíš přetížené týdny
4. **Motivace** - zelené dny (hotové) vs červené (deadlines)

---

## ✅ Klíčové Features

### 1. Event Markers (tečky na dnech s úkoly)
```dart
eventLoader: (day) {
  // Načíst TODO úkoly pro tento den z databáze
  return context.read<TodoListBloc>().getTodosForDate(day);
},
```

### 2. User Interactions
```dart
onDaySelected: (selectedDay, focusedDay) {
  // Zobrazit úkoly pro vybraný den
  // Přepnout na "Today" view s filtrovanými úkoly
},

onRangeSelected: (start, end, focusedDay) {
  // Hromadné plánování - přesun více úkolů najednou
},
```

### 3. Custom Builders (barevné značky podle priority)
```dart
calendarBuilders: CalendarBuilders(
  markerBuilder: (context, date, events) {
    // Zobrazit barevnou tečku podle priority úkolů
    // červená = *a*, žlutá = *b*, zelená = *c*
    return _buildPriorityMarkers(events);
  },
),
```

### 4. Multiple Calendar Formats
- **Month View** - celý měsíc (default)
- **Two Weeks View** - aktuální + příští týden
- **Week View** - pouze aktuální týden

### 5. Range Selection
- Výběr rozsahu dat (např. celý týden)
- Hromadné plánování úkolů
- Batch operace

### 6. Locale Support
- Česká lokalizace názvů měsíců/dnů
- Formátování dat podle locale

---

## 🎨 Možné Use Cases

### **1. Calendar View Tab**
Přidat nový tab v PageView:
```
[AI Chat] [TODO] [Notes] [Calendar] [Pomodoro]
                            ↑ nový tab
```

**Layout:**
```
┌─────────────────────────────────────┐
│ Calendar (month view)               │
│   Po  Út  St  Čt  Pá  So  Ne       │
│    1   2●  3   4●● 5   6   7       │
│                  ↑ 2 úkoly dnes     │
│                                     │
│ [Selected Day: 4. říjen]            │
├─────────────────────────────────────┤
│ ✅ [5] Dokončit prezentaci *a*      │
│ ⏳ [12] Zavolat klientovi *b*       │
└─────────────────────────────────────┘
```

### **2. Due Date Picker Vylepšení**
Místo textového inputu `*dnes*` / `*zítra*`:
```dart
// Long press na TODO úkol → Calendar picker
showDialog(
  context: context,
  builder: (context) => CalendarDialog(
    selectedDate: todo.dueDate,
    onDateSelected: (date) {
      // Update due date
    },
  ),
);
```

### **3. Hromadné Plánování (Range Selection)**
```dart
onRangeSelected: (start, end, focusedDay) {
  // Uživatel vybere rozsah (např. celý týden)
  // → Nabídnout přesunutí všech pending úkolů do tohoto rozsahu
  showDialog(...);
}
```

### **4. Statistiky & Heat Map**
```dart
// Zobrazit intenzitu úkolů jako heat map
markerBuilder: (context, date, tasks) {
  final intensity = tasks.length;
  return Container(
    decoration: BoxDecoration(
      color: _getHeatColor(intensity), // Tmavší = více úkolů
    ),
  );
}
```

---

## 🏗️ Implementační Plán

### **Phase 1: MVP Calendar View (3-4h)**

#### **Krok 1: Přidat package** (5 min)
```yaml
# pubspec.yaml
dependencies:
  table_calendar: ^3.2.0
```

```bash
flutter pub add table_calendar
```

#### **Krok 2: Vytvořit CalendarPage** (1h)
```
lib/features/calendar/
├── presentation/
│   ├── pages/
│   │   └── calendar_page.dart         # TableCalendar widget
│   └── widgets/
│       ├── calendar_event_marker.dart # Barevné tečky
│       └── day_tasks_list.dart        # Seznam úkolů pro vybraný den
```

**Klíčový kód:**
```dart
class CalendarPage extends StatefulWidget {
  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Calendar widget
        TableCalendar(
          firstDay: DateTime(2020),
          lastDay: DateTime(2030),
          focusedDay: _focusedDay,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),

          // Event loader - načíst úkoly z databáze
          eventLoader: (day) {
            return context.read<TodoListBloc>().getTodosForDate(day);
          },

          // User tap on day
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
          },

          // Custom marker builder
          calendarBuilders: CalendarBuilders(
            markerBuilder: (context, date, events) {
              return _buildPriorityMarkers(events as List<Todo>);
            },
          ),
        ),

        // Divider
        const Divider(height: 1),

        // Tasks for selected day
        Expanded(
          child: _buildTasksForDay(_selectedDay),
        ),
      ],
    );
  }

  Widget _buildPriorityMarkers(List<Todo> todos) {
    // Grupovat podle priority
    final priorities = <String, int>{};
    for (final todo in todos) {
      final priority = todo.priority ?? 'none';
      priorities[priority] = (priorities[priority] ?? 0) + 1;
    }

    // Zobrazit barevné tečky
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (priorities['a'] != null)
          _buildDot(Colors.red, priorities['a']!),
        if (priorities['b'] != null)
          _buildDot(Colors.yellow, priorities['b']!),
        if (priorities['c'] != null)
          _buildDot(Colors.green, priorities['c']!),
      ],
    );
  }

  Widget _buildDot(Color color, int count) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}
```

#### **Krok 3: Extend TodoListBloc** (30 min)
```dart
// Přidat metodu do TodoListBloc
List<Todo> getTodosForDate(DateTime date) {
  if (state is! TodoListLoaded) return [];

  final todos = (state as TodoListLoaded).allTodos;

  return todos.where((todo) {
    if (todo.dueDate == null) return false;

    // Porovnat pouze datum (ignorovat čas)
    final todoDate = DateTime(
      todo.dueDate!.year,
      todo.dueDate!.month,
      todo.dueDate!.day,
    );

    final targetDate = DateTime(date.year, date.month, date.day);

    return todoDate == targetDate;
  }).toList();
}
```

#### **Krok 4: Přidat Calendar tab do MainPage** (15 min)
```dart
// V main_page.dart
PageView(
  controller: _pageController,
  children: [
    const AiChatPage(),
    const TodoListPage(),
    const NotesListPage(),
    const CalendarPage(),  // ← NOVÝ TAB
    const PomodoroPage(),
  ],
);
```

#### **Krok 5: Commit** (5 min)
```bash
git add -A
git commit -m "✨ feat: Calendar view - MVP s event markers a day selection"
```

**Deliverable**: Funkční calendar view s barevnými tečkami podle priority úkolů.

---

### **Phase 2: Advanced Features (6-8h)**

#### **Feature 1: Notifikace (2-3h)**

**Package**: `flutter_local_notifications: ^18.0.1`

```dart
// Při vytvoření úkolu s due date
if (todo.dueDate != null) {
  await NotificationService.scheduleNotification(
    id: todo.id,
    title: 'Deadline blíží se!',
    body: todo.task,
    scheduledDate: todo.dueDate!.subtract(Duration(hours: 1)),
  );
}
```

**Kroky:**
1. Přidat flutter_local_notifications package
2. Vytvořit NotificationService
3. Schedule notifikaci při vytvoření/update úkolu s due date
4. Cancel notifikaci při smazání úkolu
5. Handle notifikace kliknutí → otevřít úkol

**Benefit**: User dostane upozornění 1h před deadlinem.

---

#### **Feature 2: Drag & Drop Plánování (3-4h)**

```dart
// Long press na TODO card → drag na calendar den
Draggable<Todo>(
  data: todo,
  feedback: TodoCard(todo: todo, isDragging: true),
  child: TodoCard(todo: todo),
),

DragTarget<Todo>(
  onAccept: (todo) {
    // Změnit due date na tento den
    bloc.add(UpdateTodoDueDateEvent(todo.id, selectedDate));
  },
  builder: (context, candidateData, rejectedData) {
    return CalendarDayWidget(...);
  },
),
```

**Benefit**: Vizuální přeplánování - táhneš úkol na jiný den.

---

#### **Feature 3: Week/Month Views Toggle (1h)**

```dart
CalendarFormat _calendarFormat = CalendarFormat.month;

IconButton(
  icon: Icon(_calendarFormat == CalendarFormat.month
      ? Icons.view_week
      : Icons.calendar_month),
  onPressed: () {
    setState(() {
      _calendarFormat = _calendarFormat == CalendarFormat.month
          ? CalendarFormat.week
          : CalendarFormat.month;
    });
  },
),
```

**Benefit**: Přepínání mezi týdenním a měsíčním pohledem.

---

#### **Feature 4: Recurring Events Support (2-3h)**

```dart
// Pro TODO s tagem *každý-den* nebo *týdně*
eventLoader: (day) {
  final regularTodos = _getRegularTodos(day);
  final recurringTodos = _getRecurringTodos(day);
  return [...regularTodos, ...recurringTodos];
}

List<Todo> _getRecurringTodos(DateTime day) {
  // Načíst úkoly s recurring pattern
  // Zkontrolovat, zda dnešní den odpovídá patternu
  // Např.: *každý-pondělí* → zobrazit každé pondělí
}
```

**Benefit**: Opakující se úkoly (denně, týdně, měsíčně).

---

#### **Feature 5: Heat Map View (2h)**

```dart
calendarBuilders: CalendarBuilders(
  defaultBuilder: (context, day, focusedDay) {
    final taskCount = _getTaskCountForDay(day);
    final intensity = (taskCount / 10).clamp(0.0, 1.0);

    return Container(
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(intensity),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text('${day.day}'),
      ),
    );
  },
),
```

**Benefit**: Vidíš workload celého měsíce najednou (tmavší = více úkolů).

---

#### **Feature 6: Calendar Date Picker Dialog (1h)**

```dart
// Nahradit textový input *dnes* / *zítra* visual pickerem
Future<DateTime?> showCalendarPicker(BuildContext context) {
  return showDialog<DateTime>(
    context: context,
    builder: (context) => Dialog(
      child: TableCalendar(
        focusedDay: DateTime.now(),
        firstDay: DateTime.now(),
        lastDay: DateTime.now().add(Duration(days: 365)),
        onDaySelected: (date, _) {
          Navigator.pop(context, date);
        },
      ),
    ),
  );
}

// V TodoInputBar:
final selectedDate = await showCalendarPicker(context);
if (selectedDate != null) {
  // Přidat *datum[DD.MM.YYYY]* tag
}
```

**Benefit**: Vizuální výběr data místo psaní tagů.

---

## 📊 Effort Estimation

| Feature | Effort | Priority | Benefit |
|---------|--------|----------|---------|
| **MVP Calendar View** | 3-4h | ⭐⭐⭐⭐ Vysoká | Základní vizualizace |
| Priority Markers | 1h | ⭐⭐⭐⭐ Vysoká | Vidíš důležitost úkolů |
| Date Picker Dialog | 1h | ⭐⭐⭐ Střední | Lepší UX než textové tagy |
| Notifikace | 2-3h | ⭐⭐⭐ Střední | Reminders před deadlinem |
| Drag & Drop | 3-4h | ⭐⭐ Nízká | Vizuální přeplánování |
| Heat Map View | 2h | ⭐⭐ Nízká | Workload overview |
| Week/Month Toggle | 1h | ⭐⭐ Nízká | Flexibilní zobrazení |
| Recurring Events | 2-3h | ⭐⭐ Nízká | Opakující se úkoly |

**Total MVP**: ~5h práce
**Total Advanced**: ~12-15h práce

---

## 🎨 UI/UX Mockup

### Calendar View Layout:

```
┌─────────────────────────────────────────────────┐
│ ← Říjen 2025 →          [📅 Week] [📊 Heat]    │ AppBar
├─────────────────────────────────────────────────┤
│                                                 │
│       Po   Út   St   Čt   Pá   So   Ne         │
│        1    2    3    4    5    6    7          │
│              ●        ●●              (markers) │
│                                                 │
│        8    9   10   11   12   13   14          │
│        ●              ●●   ●                    │
│                       ↑                         │
│       15   16   17   18   19   20   21          │
│                                                 │
│       22   23   24   25   26   27   28          │
│                                                 │
│       29   30   31                              │
│                                                 │
├─────────────────────────────────────────────────┤
│ 📅 Vybraný den: 11. říjen 2025 (4 úkoly)       │
├─────────────────────────────────────────────────┤
│ ✅ [5] Dokončit prezentaci *a* *dnes*          │
│ ⏳ [12] Zavolat klientovi *b* *dnes*           │
│ 📋 [23] Code review *c* *dnes*                 │
│ 💡 [45] Nápad na feature *projekt-x*           │
└─────────────────────────────────────────────────┘
```

**Legend:**
- `●` = 1 úkol
- `●●` = 2+ úkoly
- Červená tečka = úkol s prioritou *a*
- Žlutá tečka = úkol s prioritou *b*
- Zelená tečka = úkol s prioritou *c*

---

## 🚀 Doporučené Pořadí Implementace

1. **Phase 1 (MVP)** - 5h
   - ✅ Calendar View Tab
   - ✅ Event Markers (barevné tečky)
   - ✅ Day Selection → zobraz úkoly
   - ✅ TodoListBloc.getTodosForDate()

2. **Phase 2a (Quick Wins)** - 2h
   - ✅ Date Picker Dialog (nahradit textové tagy)
   - ✅ Week/Month Toggle

3. **Phase 2b (Advanced)** - 8-10h
   - ⏳ Notifikace před deadlinem
   - ⏳ Drag & Drop plánování
   - ⏳ Heat Map View
   - ⏳ Recurring Events

---

## 💡 UX Benefits

### **Pro Uživatele:**

1. **Vizuální plánování** - vidíš celý měsíc, ne jen list
2. **Rychlé přeplánování** - tap na den = změna deadline
3. **Workload overview** - červený týden = přetížený
4. **Motivace** - zelené dny (hotovo) vs červené (deadlines)
5. **Přehled** - vidíš, kdy máš volno pro nové úkoly

### **Pro Produktivitu:**

1. **Time blocking** - rozložení úkolů do týdne
2. **Deadline awareness** - vizuální připomínka blížících se termínů
3. **Balance tracking** - rovnoměrné rozložení práce
4. **Sprint planning** - plánování celého týdne najednou

---

## 🔧 Technical Notes

### **Dependencies:**

```yaml
# pubspec.yaml
dependencies:
  table_calendar: ^3.2.0
  flutter_local_notifications: ^18.0.1  # Pro notifikace (Phase 2)
  intl: ^0.19.0  # Už máme (pro date formatting)
```

### **Database Changes:**

**Žádné!** Všechno funguje s existujícím schema:
- `due_date` column už máme v `todos` tabulce
- Event loader jen query existující data

### **BLoC Changes:**

Minimální - pouze přidat helper metodu:
```dart
// V TodoListBloc
List<Todo> getTodosForDate(DateTime date) {
  // Filter existující state
}
```

### **Performance:**

- **Event loader** volán pro každý viditelný den (~42 dní v month view)
- **Optimalizace**: Cache getTodosForDate() results
- **Očekávaný overhead**: < 50ms při scroll

---

## 📚 References

- **Package Docs**: https://pub.dev/packages/table_calendar
- **GitHub**: https://github.com/aleksanderwozniak/table_calendar
- **Examples**: https://github.com/aleksanderwozniak/table_calendar/tree/master/example

---

## ✅ Rozhodnutí

**ANO, implementovat Calendar view!**

**Důvody:**
1. ✅ Mature package (1.92k ⭐, 478k downloads/měsíc)
2. ✅ Žádné DB změny - funguje s existujícím schema
3. ✅ Minimální změny v BLoC
4. ✅ Vysoká hodnota pro uživatele (vizuální plánování)
5. ✅ Rychlý MVP (3-4h práce)

**Start:**
- MVP Calendar View (Phase 1)
- Pak iterativně Phase 2 features podle user feedbacku

---

**Autor**: Claude Code AI
**Metoda**: WebFetch research + Technical analysis
**Status**: ✅ Analýza dokončena, ready for implementation 🚀
