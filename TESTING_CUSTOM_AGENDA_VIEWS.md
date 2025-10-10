# 🧪 Custom Agenda Views - Manuální Testing Guide

## 📋 Přehled

Tento dokument obsahuje kompletní manuální testing checklist pro Custom Agenda Views feature.

**Datum testing run**: ____________

**Tester**: ____________

**Build**: ____________

---

## ✅ FÁZE 5.1: Základní funkčnost

### Settings > Agenda Tab

- [ ] **Test 1.1**: Settings page zobrazuje 5 tabů (GENERAL, THEMES, API, TTS, AGENDA)
  - Otevři Settings
  - Zkontroluj že tab "AGENDA" existuje
  - Klikni na tab AGENDA
  - **Expected**: Tab se otevře bez crash

- [ ] **Test 1.2**: Built-in views section zobrazuje 5 přepínačů
  - V Agenda tabu zkontroluj sekci "📋 Built-in Views"
  - **Expected**: 5 SwitchListTile (All, Today, Week, Upcoming, Overdue)
  - **Default state**: All=ON, Today=ON, Week=ON, Upcoming=OFF, Overdue=ON

- [ ] **Test 1.3**: Toggle built-in view ON → OFF
  - Vypni "Týden" přepínač
  - Vrať se do TodoListPage
  - **Expected**: ViewBar nezobrazuje ikonu 🗓️ (Week)

- [ ] **Test 1.4**: Toggle built-in view OFF → ON
  - Zapni "Nadcházející" přepínač
  - Vrať se do TodoListPage
  - **Expected**: ViewBar zobrazuje ikonu ⏰ (Upcoming)

- [ ] **Test 1.5**: Custom views section zobrazuje tlačítko "+ Přidat"
  - V Agenda tabu zkontroluj sekci "🆕 Custom Views"
  - **Expected**: Tlačítko "Přidat Custom View" je viditelné
  - **Expected**: Pokud žádné custom views, sekce je prázdná

---

### Custom Views - CRUD Operace

- [ ] **Test 2.1**: Přidat custom view
  - Klikni "Přidat Custom View"
  - Dialog se otevře
  - Vyplň:
    - Název: "Oblíbené"
    - Tag: "***"
    - Ikona: Star (⭐)
  - Klikni "Uložit"
  - **Expected**: Dialog se zavře, nová karta se objeví v seznamu
  - **Expected**: ViewBar zobrazuje novou ikonu ⭐

- [ ] **Test 2.2**: Přidat druhý custom view
  - Klikni "Přidat Custom View"
  - Vyplň:
    - Název: "Projekt"
    - Tag: "#projekt"
    - Ikona: Work (🏢)
  - Klikni "Uložit"
  - **Expected**: ViewBar zobrazuje 2 custom ikony (⭐ + 🏢)

- [ ] **Test 2.3**: Upravit custom view
  - Klikni ✏️ (edit) na "Oblíbené" kartě
  - Změň název na "Favorites"
  - Změň tag na "⭐"
  - Klikni "Uložit"
  - **Expected**: Karta zobrazuje nový název "Favorites"
  - **Expected**: Tag zobrazuje "⭐"

- [ ] **Test 2.4**: Smazat custom view
  - Klikni 🗑️ (delete) na "Projekt" kartě
  - **Expected**: Karta zmizí ze seznamu
  - **Expected**: ViewBar nezobrazuje 🏢 ikonu

- [ ] **Test 2.5**: Validace prázdných polí
  - Klikni "Přidat Custom View"
  - Nech prázdné pole "Název"
  - Klikni "Uložit"
  - **Expected**: Dialog se NEZAVŘE (validace failed)
  - Vyplň název, nech prázdný tag
  - Klikni "Uložit"
  - **Expected**: Dialog se NEZAVŘE (validace failed)

---

### ViewBar - Dynamic Rendering

- [ ] **Test 3.1**: ViewBar zobrazuje pouze enabled views
  - Vypni všechny built-in views kromě "Všechny"
  - **Expected**: ViewBar zobrazuje pouze 📋 (All) + custom views

- [ ] **Test 3.2**: Horizontal scroll když > 6 views
  - Zapni všechny built-in views (5 views)
  - Přidej 3 custom views
  - **Expected**: ViewBar má horizontal scroll
  - **Expected**: Všechny ikony jsou přístupné swipe

- [ ] **Test 3.3**: Empty state hint
  - Vypni VŠECHNY built-in views
  - Smaž VŠECHNY custom views
  - **Expected**: ViewBar zobrazuje hint text
  - **Expected**: Text: "Žádné views aktivní. Zapni je v Settings > Agenda"

- [ ] **Test 3.4**: Klik na custom view aktivuje filtr
  - Vytvoř custom view "Work" s tagem "#work"
  - Vytvoř 3 úkoly:
    - "Task 1" (bez tagu)
    - "Task 2 #work"
    - "Task 3 #work"
  - Klikni na 🏢 (Work) ikonu ve ViewBar
  - **Expected**: Zobrazí pouze Task 2 a Task 3

- [ ] **Test 3.5**: Toggle behavior - deselect vrátí na All
  - Aktivuj custom view (klikni na ikonu)
  - Klikni znovu na stejnou ikonu
  - **Expected**: Vrátí se na ViewMode.all (všechny úkoly viditelné)

- [ ] **Test 3.6**: Long-press zobrazí InfoDialog
  - Long-press na custom view ikonu
  - **Expected**: InfoDialog se otevře
  - **Expected**: Zobrazuje název, tag filter, popis
  - **Expected**: Tip: "Klikni na ikonku pro aktivaci..."

---

### Filtrování Custom Views

- [ ] **Test 4.1**: Tag matching je case-sensitive
  - Vytvoř custom view s tagem "***"
  - Vytvoř úkol s tagem "***"
  - Vytvoř úkol s tagem "**" (2 hvězdičky)
  - Aktivuj custom view
  - **Expected**: Zobrazí pouze úkol s "***"

- [ ] **Test 4.2**: Custom view + search kombinace
  - Aktivuj custom view "#work"
  - Zadej search query "task"
  - **Expected**: Filtruje úkoly: (tag == "#work") AND (text contains "task")

- [ ] **Test 4.3**: Custom view + sort kombinace
  - Aktivuj custom view
  - Seřaď podle priority
  - **Expected**: Filtrované úkoly jsou seřazené správně

- [ ] **Test 4.4**: Custom view + showCompleted toggle
  - Aktivuj custom view
  - Skryj hotové úkoly (visibility toggle)
  - **Expected**: Zobrazí pouze nehotové úkoly s daným tagem

---

## ✅ FÁZE 5.2: Edge Cases

- [ ] **Edge Case 1**: Všechny views disabled
  - Vypni všechny built-in views
  - Smaž všechny custom views
  - **Expected**: Empty state hint se zobrazí
  - **Expected**: Žádný crash

- [ ] **Edge Case 2**: Custom view s neexistujícím tagem
  - Vytvoř custom view s tagem "#nonexistent"
  - Aktivuj tento view
  - **Expected**: Zobrazí prázdný list (0 úkolů)
  - **Expected**: Žádný crash

- [ ] **Edge Case 3**: Persistence po restartu
  - Nastav custom agenda config:
    - Vypni "Week"
    - Přidej custom view "Test"
  - Zavři a restartuj aplikaci
  - **Expected**: Week ikona je VYPNUTÁ
  - **Expected**: Custom view "Test" je ZACHOVANÝ

- [ ] **Edge Case 4**: Smazat aktivní custom view
  - Aktivuj custom view "Work"
  - Jdi do Settings > Agenda
  - Smaž "Work" custom view
  - Vrať se do TodoListPage
  - **Expected**: Fallback na ViewMode.all
  - **Expected**: Všechny úkoly jsou viditelné

- [ ] **Edge Case 5**: Vypnout aktivní built-in view
  - Aktivuj "Week" view
  - Jdi do Settings > Agenda
  - Vypni "Týden" přepínač
  - Vrať se do TodoListPage
  - **Expected**: Fallback na ViewMode.all
  - **Expected**: Week ikona zmizela z ViewBar

- [ ] **Edge Case 6**: Duplicitní tag mezi custom views
  - Vytvoř custom view "A" s tagem "***"
  - Vytvoř custom view "B" se stejným tagem "***"
  - **Expected**: Oba views jsou vytvořeny
  - **Expected**: Oba filtrují stejné úkoly
  - **Note**: Toto je OK - uživatel může mít různé názvy/ikony pro stejný tag

---

## ✅ FÁZE 5.3: UX & Performance

- [ ] **UX 1**: Animace při změně view
  - Klikni mezi různými views (All → Today → Week → Custom)
  - **Expected**: Smooth transition (200ms)
  - **Expected**: Ikony mění barvu (yellow = selected, base5 = unselected)

- [ ] **UX 2**: Tooltips na hover (desktop only)
  - Hover nad ViewBar ikonou
  - **Expected**: Tooltip se zobrazí s názvem view
  - **Note**: Na mobilu skip (no hover)

- [ ] **UX 3**: Settings UI responsiveness
  - Přidej 10 custom views
  - **Expected**: Seznam je scrollable
  - **Expected**: Žádný performance lag

- [ ] **UX 4**: ViewBar scrolling performance
  - Přidej 10 views (built-in + custom)
  - Rychle swipe ViewBar doleva/doprava
  - **Expected**: Smooth scroll (60fps)
  - **Expected**: Žádný lag

- [ ] **Performance 1**: Load time při startu
  - Vytvoř 5 custom views
  - Restartuj app
  - **Expected**: Načte se < 500ms
  - **Expected**: Žádný visible loading state

- [ ] **Performance 2**: Filter latency
  - Vytvoř 100 úkolů
  - Aktivuj custom view
  - **Expected**: Filtrování je okamžité (< 50ms)
  - **Expected**: Žádný visible loading spinner

---

## ✅ Acceptance Criteria (Final Checklist)

- [ ] Uživatel může zapnout/vypnout built-in views v Settings > Agenda
- [ ] Uživatel může přidat custom view s tagem, názvem a ikonou
- [ ] Uživatel může upravit existující custom view
- [ ] Uživatel může smazat custom view
- [ ] ViewBar zobrazuje pouze enabled views
- [ ] Klik na custom view filtruje úkoly podle tagu
- [ ] Empty state hint když žádné views enabled
- [ ] Horizontal scroll když > 6 views
- [ ] Persistence přes SharedPreferences funguje
- [ ] InfoDialog na long-press funguje pro custom views

---

## 🐛 Bug Tracker

| ID | Popis | Severity | Status | Fix |
|----|-------|----------|--------|-----|
| - | - | - | - | - |

**Severity levels**:
- 🔴 Critical (crash, data loss)
- 🟡 Major (feature broken)
- 🟢 Minor (cosmetic, edge case)

---

## 📝 Testing Notes

(Zaznamenej poznámky z testing run)

---

**Testing dokončen**: ____________

**Výsledek**: ☐ PASS  ☐ FAIL  ☐ PARTIAL

**Next steps**: ____________
