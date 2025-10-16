# Notes - Poznámky pro další session

## 🚨 DŮLEŽITÉ: Swipe gesto pro Notes feature

### ✅ Co jsme zjistili a implementovali:

#### 1. **Swipe nahoru na celém display**
- Použit `GestureDetector` obalující `PageView` v `main_page.dart`
- Detekce: `onVerticalDragEnd` s `primaryVelocity < -500`
- Funguje na celém display (ne jen spodní indikátor)
- Otevře `NotesPage` jako Modal Bottom Sheet

```dart
GestureDetector(
  onVerticalDragEnd: (details) {
    if (details.primaryVelocity != null && details.primaryVelocity! < -500) {
      _openNotesPage();
    }
  },
  child: PageView(...),
)
```

#### 2. **❌ NESMÍ BÝT SafeArea kolem InputBaru!**
- **KRITICKÉ**: SafeArea vytváří ~1cm offset od spodního okraje (Android navigation bar padding)
- InputBar MUSÍ být přímo v `Column` (BEZ SafeArea wrapper)
- Stejně jako v `AiChatPage` - tam je ChatInput také bez SafeArea

**Špatně (vytváří offset):**
```dart
Container(
  child: SafeArea(  // ❌ ŠPATNĚ - vytváří padding dole
    child: Column(
      children: [InputBar()],
    ),
  ),
)
```

**Správně (úplně dole):**
```dart
Container(
  child: Column(  // ✅ SPRÁVNĚ - bez SafeArea
    children: [InputBar()],
  ),
)
```

### 📋 Implementované změny v této session:

1. **Notes swipe gesto** (`main_page.dart`)
   - Odstraněn 40px spodní indikátor
   - GestureDetector na celém PageView
   - Commit: `3ef3724`

2. **InputBar úplně dole** (`todo_list_page.dart`)
   - Odstraněn SafeArea wrapper
   - InputBar nyní stejně jako AI Chat
   - Commit: `6160018`

3. **Minimalistický action bar** (`todo_list_page.dart`)
   - V klidovém stavu pouze 🔍 + ➕
   - InputBar se zobrazí až po kliknutí
   - Commit: `e354556`, `552a43b`

### 🔄 Pro příští session:

- Vrátili jsme se na commit `03c06a6` (před Notes experimenty)
- Můžeme implementovat znovu s těmito poznatky:
  - ✅ Swipe na celém display (GestureDetector)
  - ✅ BEZ SafeArea kolem InputBaru
  - ✅ Minimalistický action bar (volitelné)

---

**Datum**: 2025-10-13
**Branch**: bloc
**Původní commit před experimenty**: `03c06a6`
