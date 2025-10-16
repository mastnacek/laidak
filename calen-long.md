# Calendar Long Press - Implementační plán

## 📋 Zadání

Při dlouhém podržení na dni v kalendáři:
1. Automaticky přepnout na hlavní TodoListPage (tab 0)
2. Aktivovat input pole pro zadání nového úkolu
3. Automaticky vložit tag s datem vybraného dne (např. `*dnes`, `*zitra`, `*2025-10-18`)
4. Použít správný oddělovač tagů z uživatelských nastavení

## 🎯 Technické řešení

### 1. Detekce dlouhého podržení v kalendáři

V `CalendarPage` přidat `onDayLongPressed` callback do `TableCalendar`:

```dart
// lib/features/calendar/presentation/pages/calendar_page.dart

TableCalendar(
  // ... existing props ...

  onDayLongPressed: (selectedDay, focusedDay) {
    _handleDayLongPress(context, selectedDay);
  },
)
```

### 2. Handler pro dlouhé podržení

```dart
void _handleDayLongPress(BuildContext context, DateTime selectedDay) {
  // 1. Získat nastavení oddělovačů tagů
  final settingsState = context.read<SettingsCubit>().state;

  if (settingsState is SettingsLoaded) {
    final startDelim = settingsState.tagDelimiterStart;
    final endDelim = settingsState.tagDelimiterEnd;

    // 2. Vytvořit tag pro datum
    final dateTag = _createDateTag(selectedDay, startDelim, endDelim);

    // 3. Přepnout na TodoListPage s předvyplněným textem
    _navigateToTodoListWithTag(context, dateTag);
  }
}
```

### 3. Vytvoření date tagu

```dart
String _createDateTag(DateTime date, String startDelim, String endDelim) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final tomorrow = today.add(const Duration(days: 1));
  final dayAfterTomorrow = today.add(const Duration(days: 2));
  final selectedDateOnly = DateTime(date.year, date.month, date.day);

  // Použít sémantické tagy kde to dává smysl
  if (selectedDateOnly == today) {
    return '${startDelim}dnes$endDelim ';
  } else if (selectedDateOnly == tomorrow) {
    return '${startDelim}zitra$endDelim ';
  } else if (selectedDateOnly == dayAfterTomorrow) {
    return '${startDelim}pozitri$endDelim ';
  } else {
    // Pro ostatní dny použít formát YYYY-MM-DD
    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return '$startDelim$dateStr$endDelim ';
  }
}
```

### 4. Navigace a komunikace mezi pages

Máme několik možností, jak předat informaci o předvyplněném textu:

#### Možnost A: Přes PageController (DOPORUČENO)

```dart
// V CalendarPage
void _navigateToTodoListWithTag(BuildContext context, String dateTag) {
  // 1. Přepnout na TodoListPage (index 0)
  final pageController = context.findAncestorStateOfType<MainPageState>()?.pageController;
  pageController?.animateToPage(
    0,
    duration: const Duration(milliseconds: 300),
    curve: Curves.easeInOut,
  );

  // 2. Vyslat event do TodoListBloc s předvyplněným textem
  context.read<TodoListBloc>().add(
    PrepopulateInputEvent(text: dateTag),
  );
}
```

#### Možnost B: Přes callback v MainPage

```dart
// V MainPage přidat callback
class MainPage extends StatefulWidget {
  final Function(String)? onNavigateToTodoWithText;
  // ...
}

// V CalendarPage zavolat callback
widget.onNavigateToTodoWithText?.call(dateTag);
```

### 5. TodoListBloc - přidat nový event

```dart
// lib/features/todo_list/presentation/bloc/todo_list_event.dart

/// Event pro předvyplnění input baru textem
final class PrepopulateInputEvent extends TodoListEvent {
  final String text;

  const PrepopulateInputEvent({required this.text});

  @override
  List<Object?> get props => [text];
}
```

### 6. TodoListBloc - handler pro nový event

```dart
// lib/features/todo_list/presentation/bloc/todo_list_bloc.dart

on<PrepopulateInputEvent>((event, emit) {
  emit(state.copyWith(
    prepopulatedText: event.text,
  ));
});
```

### 7. TodoListState - přidat pole pro předvyplněný text

```dart
// lib/features/todo_list/presentation/bloc/todo_list_state.dart

final class TodoListLoaded extends TodoListState {
  // ... existing fields ...

  /// Text k předvyplnění v input baru
  final String? prepopulatedText;

  const TodoListLoaded({
    // ... existing params ...
    this.prepopulatedText,
  });

  TodoListLoaded copyWith({
    // ... existing params ...
    String? prepopulatedText,
    bool clearPrepopulatedText = false,
  }) {
    return TodoListLoaded(
      // ... existing fields ...
      prepopulatedText: clearPrepopulatedText ? null : (prepopulatedText ?? this.prepopulatedText),
    );
  }
}
```

### 8. InputBar - reagovat na předvyplněný text

```dart
// lib/features/todo_list/presentation/widgets/input_bar.dart

@override
Widget build(BuildContext context) {
  return BlocListener<TodoListBloc, TodoListState>(
    listener: (context, state) {
      if (state is TodoListLoaded && state.prepopulatedText != null) {
        // Nastavit text a focus
        _controller.text = state.prepopulatedText!;
        _controller.selection = TextSelection.fromPosition(
          TextPosition(offset: _controller.text.length),
        );
        _focusNode.requestFocus();

        // Vyčistit prepopulated text ve state
        context.read<TodoListBloc>().add(
          const ClearPrepopulatedTextEvent(),
        );
      }
    },
    child: // ... existing widget tree ...
  );
}
```

### 9. Přidat ClearPrepopulatedTextEvent

```dart
// lib/features/todo_list/presentation/bloc/todo_list_event.dart

/// Event pro vyčištění předvyplněného textu
final class ClearPrepopulatedTextEvent extends TodoListEvent {
  const ClearPrepopulatedTextEvent();
}
```

```dart
// lib/features/todo_list/presentation/bloc/todo_list_bloc.dart

on<ClearPrepopulatedTextEvent>((event, emit) {
  if (state is TodoListLoaded) {
    emit(state.copyWith(clearPrepopulatedText: true));
  }
});
```

## 📦 Dependency injections

Potřebujeme zajistit, že `CalendarPage` má přístup k:
1. `SettingsCubit` - pro získání oddělovačů tagů
2. `TodoListBloc` - pro vyslání PrepopulateInputEvent
3. `PageController` z `MainPage` - pro přepnutí na TodoListPage

## 🧪 Testování

### Manuální test flow:

1. Otevřít kalendář (5. tab)
2. Dlouze podržet na dnešním dni
   - Očekávané: Přepne na TodoList, v input baru bude `*dnes `
3. Vrátit se do kalendáře
4. Dlouze podržet na zítřejším dni
   - Očekávané: Přepne na TodoList, v input baru bude `*zitra `
5. Dlouze podržet na jiném dni (např. 25.12.2025)
   - Očekávané: Přepne na TodoList, v input baru bude `*2025-12-25 `
6. Změnit oddělovač tagů v nastavení na `#`
7. Dlouze podržet na dni
   - Očekávané: Tag bude ve formátu `#dnes ` nebo `#2025-12-25 `

### Edge cases:

- Co když uživatel rychle přepíná mezi dny?
- Co když už je něco napsané v input baru?
- Co když je input bar ve search mode?

## 🚀 Implementační kroky

1. **Přidat PrepopulateInputEvent a handler** (15 min)
   - Nový event v `todo_list_event.dart`
   - Handler v `todo_list_bloc.dart`
   - Rozšířit `TodoListState` o `prepopulatedText`

2. **Implementovat long press v CalendarPage** (30 min)
   - Přidat `onDayLongPressed` callback
   - Implementovat `_handleDayLongPress`
   - Implementovat `_createDateTag`

3. **Navigace mezi pages** (20 min)
   - Získat PageController z MainPage
   - Implementovat `_navigateToTodoListWithTag`

4. **InputBar - reagovat na předvyplnění** (20 min)
   - Přidat BlocListener
   - Nastavit text a focus
   - Vyčistit state po použití

5. **Testing** (30 min)
   - Manuální testování všech scénářů
   - Oprava edge cases

## 📝 Poznámky

- Důležité je zachovat konzistenci s existujícím tag systémem
- Uživatel může text upravit nebo smazat před odesláním
- Focus na input bar by měl být automatický pro okamžité psaní
- Animace přechodu mezi pages by měla být plynulá

## ⚠️ Potenciální problémy

1. **Race condition** - pokud uživatel rychle přepíná, může se stát, že text se nastaví až po přepnutí
2. **Focus issues** - na některých zařízeních může být problém s automatickým focusem
3. **State management** - musíme správně vyčistit `prepopulatedText` po použití

## ✅ Definition of Done

- [ ] Long press na dni v kalendáři funguje
- [ ] Automaticky se přepne na TodoListPage
- [ ] Input bar má focus a obsahuje správný date tag
- [ ] Používá se správný oddělovač z nastavení
- [ ] Funguje pro dnes/zítra/pozítří i konkrétní data
- [ ] Edge cases jsou ošetřeny
- [ ] Kód je čistý a dodržuje BLoC pattern