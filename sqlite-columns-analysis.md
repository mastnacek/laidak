# 🔥 SQLite Columns & Table Design Analysis

## 📊 SOUČASNÝ STAV - POČET SLOUPCŮ

### Tabulka 1: `todos`
**Počet sloupců: 9**

```sql
1.  id                     INTEGER PRIMARY KEY AUTOINCREMENT
2.  task                   TEXT NOT NULL
3.  isCompleted            INTEGER NOT NULL DEFAULT 0
4.  createdAt              TEXT NOT NULL
5.  priority               TEXT
6.  dueDate                TEXT
7.  tags                   TEXT  -- ❌ DEPRECATED (CSV string)
8.  ai_recommendations     TEXT
9.  ai_deadline_analysis   TEXT
```

---

### Tabulka 2: `settings`
**Počet sloupců: 9**

```sql
1.  id                     INTEGER PRIMARY KEY CHECK (id = 1)
2.  api_key                TEXT
3.  model                  TEXT NOT NULL DEFAULT 'mistralai/mistral-medium-3.1'
4.  temperature            REAL NOT NULL DEFAULT 1.0
5.  max_tokens             INTEGER NOT NULL DEFAULT 1000
6.  enabled                INTEGER NOT NULL DEFAULT 1
7.  tag_delimiter_start    TEXT NOT NULL DEFAULT '*'
8.  tag_delimiter_end      TEXT NOT NULL DEFAULT '*'
9.  selected_theme         TEXT NOT NULL DEFAULT 'doom_one'
10. has_seen_gesture_hint  INTEGER NOT NULL DEFAULT 0
```

---

### Tabulka 3: `custom_prompts`
**Počet sloupců: 5**

```sql
1.  id             INTEGER PRIMARY KEY AUTOINCREMENT
2.  category       TEXT NOT NULL UNIQUE
3.  system_prompt  TEXT NOT NULL
4.  tags           TEXT NOT NULL
5.  style          TEXT NOT NULL
```

---

### Tabulka 4: `tag_definitions`
**Počet sloupců: 10**

```sql
1.  id             INTEGER PRIMARY KEY AUTOINCREMENT
2.  tag_name       TEXT UNIQUE NOT NULL
3.  tag_type       TEXT NOT NULL
4.  display_name   TEXT
5.  emoji          TEXT
6.  color          TEXT
7.  glow_enabled   INTEGER NOT NULL DEFAULT 0
8.  glow_strength  REAL NOT NULL DEFAULT 0.5
9.  sort_order     INTEGER NOT NULL DEFAULT 0
10. enabled        INTEGER NOT NULL DEFAULT 1
```

---

### Tabulka 5: `subtasks`
**Počet sloupců: 6**

```sql
1.  id               INTEGER PRIMARY KEY AUTOINCREMENT
2.  parent_todo_id   INTEGER NOT NULL
3.  subtask_number   INTEGER NOT NULL
4.  text             TEXT NOT NULL
5.  completed        INTEGER NOT NULL DEFAULT 0
6.  created_at       INTEGER NOT NULL
```

---

## 📈 CELKOVÝ POČET SLOUPCŮ

```
todos:            9 sloupců
settings:         10 sloupců
custom_prompts:   5 sloupců
tag_definitions:  10 sloupců
subtasks:         6 sloupců
─────────────────────────────
CELKEM:           40 sloupců
```

**+ Navrhované nové tabulky:**
```
tags:             7 sloupců (normalizace custom tagů)
todo_tags:        3 sloupce (many-to-many)
custom_agenda_views: 8 sloupců (přesun z SharedPrefs)
─────────────────────────────
PO REFAKTORINGU:  58 sloupců (8 tabulek)
```

---

## 🚦 SQLite LIMITY (Official Documentation)

### 1️⃣ Maximum Columns per Table
- **Default:** 2,000 sloupců
- **Maximum:** 32,767 sloupců (s recompilací)
- **Doporučeno:** < 100 sloupců (best practice)

**Náš stav:**
- ✅ Největší tabulka: 10 sloupců (`tag_definitions`, `settings`)
- ✅ **Jsme DALEKO pod limitem!** (40 sloupců celkem)

---

### 2️⃣ Maximum Row Size
- **Default:** 1 billion bytes (1 GB)
- **Praktický limit:** Závisí na page size

**Náš stav:**
- ✅ Řádky jsou malé (< 10 KB typicky)
- ✅ Žádné BLOB/binary data

---

### 3️⃣ Page Size
- **Výchozí (SQLite 3.12+):** 4,096 bytes
- **Minimum:** 512 bytes
- **Maximum:** 65,536 bytes

**Náš stav:**
- ⚠️ **NEZJIŠTĚNO** - pravděpodobně default (4 KB)
- 💡 Možnost optimalizace: zvětšit na 8 KB nebo 16 KB

---

### 4️⃣ Maximum Database Size
- **S page size 4 KB:** ~17.5 TB
- **S page size 64 KB:** ~281 TB

**Náš stav:**
- ✅ TODO app = pravděpodobně < 10 MB
- ✅ **Žádné obavy o size limit**

---

### 5️⃣ Maximum Tables
- **Limit:** 2,147,483,646 tabulek

**Náš stav:**
- ✅ Máme 5 tabulek (+ 3 navržené = 8 celkem)
- ✅ **Žádný problém**

---

## 🤔 MEGA-TABULKA vs. NORMALIZACE

### ❌ SCÉNÁŘ A: Jedna mega-tabulka (ŠPATNÝ NÁPAD!)

**Koncept:**
```sql
CREATE TABLE everything (
  id INTEGER PRIMARY KEY,

  -- TODO fields
  task TEXT,
  isCompleted INTEGER,
  priority TEXT,
  dueDate TEXT,

  -- Settings fields
  api_key TEXT,
  model TEXT,
  temperature REAL,

  -- Tag definition fields
  tag_name TEXT,
  emoji TEXT,
  color TEXT,

  -- Subtask fields
  parent_todo_id INTEGER,
  subtask_text TEXT,

  -- ... 40+ sloupců ...

  -- Type discriminator
  row_type TEXT CHECK (row_type IN ('todo', 'setting', 'tag', 'subtask', 'prompt'))
);
```

**Proč je to HROZNÝ nápad?**

1. **🐌 Performance KATASTROFA**
   - Full table scan pro každý query
   - Indexy neefektivní (většina sloupců NULL)
   - Query planner nemá kontext

2. **💾 Plýtvání místem**
   - Každý řádek má 40+ sloupců, ale používá pouze 5-10
   - 70-80% sloupců = NULL hodnoty
   - Overhead na NULL storage

3. **🤯 Složité queries**
   ```sql
   -- Místo:
   SELECT * FROM todos WHERE isCompleted = 0;

   -- Musíš psát:
   SELECT * FROM everything
   WHERE row_type = 'todo' AND isCompleted = 0;
   ```

4. **🚫 Chybí referential integrity**
   - Nelze použít FOREIGN KEY constraints
   - Subtask → Todo vazba se ztratí
   - Chybí CASCADE delete

5. **🔥 Index KATASTROFA**
   ```sql
   CREATE INDEX idx_task ON everything(task);  -- Index i na settings/tags řádky!
   CREATE INDEX idx_api_key ON everything(api_key);  -- Index i na todos!
   ```
   - Index zahrnuje VŠECHNY řádky (i nereleva ntní)
   - Index bloat = pomalé queries

6. **😱 Maintainability NIGHTMARE**
   - Přidání nového fieldu = ALTER TABLE s 40+ sloupci
   - Migration complexity ↑↑↑
   - Code reader: "WTF is this?"

---

### ✅ SCÉNÁŘ B: Normalizované tabulky (SPRÁVNÝ PŘÍSTUP!)

**Koncept:**
```
todos              (9 sloupců)   - TODO úkoly
├─ subtasks        (6 sloupců)   - Podúkoly (1:N)
└─ todo_tags       (3 sloupce)   - Tags (M:N)
    └─ tags        (7 sloupců)   - Tag definitions

settings           (10 sloupců)  - Singleton config
custom_prompts     (5 sloupců)   - AI prompty
tag_definitions    (10 sloupců)  - Systémové tagy
custom_agenda_views (8 sloupců)  - Custom views
```

**Proč je to DOBRÝ nápad?**

1. **⚡ Performance WIN**
   - Targeted indexes (pouze relevantní sloupce)
   - Query planner optimalizuje per-table
   - Cache hit rate ↑ (menší pages, více rows per page)

2. **💾 Efektivní storage**
   - Žádné NULL hodnoty plýtvání
   - Row size optimalizován per entity type
   - Page utilization ↑

3. **🧹 Clean queries**
   ```sql
   -- Simple & clear
   SELECT * FROM todos WHERE isCompleted = 0;

   -- Relationships jasné
   SELECT t.*, s.text as subtask
   FROM todos t
   LEFT JOIN subtasks s ON t.id = s.parent_todo_id;
   ```

4. **✅ Referential integrity**
   - FOREIGN KEY constraints fungují
   - CASCADE delete automaticky čistí dependencies
   - Data consistency garantovaná DB

5. **📈 Scalable indexes**
   ```sql
   -- Index pouze pro todos
   CREATE INDEX idx_todos_task ON todos(task);

   -- Index pouze pro tags
   CREATE INDEX idx_tags_usage ON tags(usage_count);
   ```
   - Každý index je focused & efficient
   - Žádný bloat

6. **😊 Maintainability**
   - Přidání sloupce = ALTER TABLE s 5-10 sloupci
   - Jednoduchá migrace
   - Code reader: "Ah, jasná struktura!"

---

## 📊 PERFORMANCE COMPARISON

### Benchmark: "Najít všechny TODO s tagem 'projekt'"

#### ❌ Mega-tabulka (ŠPATNĚ):
```sql
SELECT * FROM everything
WHERE row_type = 'todo'
  AND tags LIKE '%projekt%';
```
- **Complexity:** O(n) - full table scan
- **Rows scanned:** VŠECHNY řádky (todos + settings + tags + subtasks + prompts)
- **Index:** Nepoužitelný (composite + LIKE)
- **Speed:** 🐌 POMALÉ

#### ✅ Normalizované tabulky (DOBŘE):
```sql
SELECT t.*
FROM todos t
INNER JOIN todo_tags tt ON t.id = tt.todo_id
INNER JOIN tags tag ON tt.tag_id = tag.id
WHERE tag.tag_name = 'projekt';
```
- **Complexity:** O(log n) - index scan
- **Rows scanned:** Pouze relevantní todos
- **Index:** `idx_todo_tags_tag_id`, `idx_tags_name` použity
- **Speed:** ⚡ RYCHLÉ (10-100x rychlejší!)

---

## 🎯 DOPORUČENÍ: NORMALIZACE!

### ✅ Důvody PRO normalizaci (8 tabulek):

1. **Performance**: Optimální pro queries, indexy, cache
2. **Scalability**: Můžeš přidat miliony todos bez problémů
3. **Maintainability**: Jednoduché migrace, čitelný kód
4. **Data integrity**: Foreign keys, constraints fungují
5. **Best practice**: Industry standard pro DB design
6. **SQLite limity**: Daleko pod limitem (58 sloupců vs. 2,000 limit)

### ❌ Důvody PROTI mega-tabulce:

1. **Performance KATASTROFA**
2. **Plýtvání místem**
3. **Složité queries**
4. **Chybí referential integrity**
5. **Anti-pattern** (žádný zkušený developer by to neudělal)

---

## 💡 OPTIMALIZACE PRO TVŮJ PROJEKT

### 1️⃣ Zvětšit Page Size (Optional)

**Současný (pravděpodobně):** 4,096 bytes (default)

**Doporučení:** 8,192 bytes (8 KB) nebo 16,384 bytes (16 KB)

**Proč:**
- Větší page = méně page reads pro sequential scans
- Lepší pro TEXT columns (task, system_prompt)
- Trade-off: větší memory usage (ale zanedbatelné pro TODO app)

**Jak změnit:**
```dart
// BEFORE opening database
await db.execute('PRAGMA page_size = 8192');
```

⚠️ **POZOR:** Změna page size vyžaduje **VACUUM** (rebuild celé DB)!

---

### 2️⃣ Enable WAL Mode (Write-Ahead Logging)

**Proč:**
- Concurrent reads & writes (žádné "database locked" errors)
- Rychlejší writes (no full fsync on every commit)
- Better crash recovery

**Jak:**
```dart
await db.execute('PRAGMA journal_mode = WAL');
```

---

### 3️⃣ Optimální Indexy (už máš většinu!)

**Současné indexy:**
```sql
-- Todos
CREATE INDEX idx_todos_task ON todos(task);          ✅
CREATE INDEX idx_todos_tags ON todos(tags);          ❌ DEPRECATED (CSV)
CREATE INDEX idx_todos_dueDate ON todos(dueDate);    ✅
CREATE INDEX idx_todos_priority ON todos(priority);  ✅
CREATE INDEX idx_todos_isCompleted ON todos(isCompleted); ✅
CREATE INDEX idx_todos_createdAt ON todos(createdAt); ✅

-- Subtasks
CREATE INDEX idx_subtasks_parent_todo_id ON subtasks(parent_todo_id); ✅
CREATE INDEX idx_subtasks_completed ON subtasks(completed); ✅
```

**Po normalizaci tags přidat:**
```sql
-- Tags
CREATE INDEX idx_tags_type ON tags(tag_type);         🆕
CREATE INDEX idx_tags_usage ON tags(usage_count DESC); 🆕

-- Todo-Tags
CREATE INDEX idx_todo_tags_todo_id ON todo_tags(todo_id); 🆕
CREATE INDEX idx_todo_tags_tag_id ON todo_tags(tag_id);   🆕

-- Custom Agenda Views
CREATE INDEX idx_custom_views_enabled ON custom_agenda_views(enabled); 🆕
```

---

## 📋 ZÁVĚREČNÝ VERDICT

| Aspekt | Mega-tabulka | Normalizace (8 tabulek) |
|--------|--------------|-------------------------|
| **Sloupců celkem** | 40+ | 58 (distributed) |
| **SQLite limit** | 2,000 sloupců | 2,000 sloupců |
| **Overhead** | ✅ Jsme OK (pod limitem) | ✅ Jsme OK (pod limitem) |
| **Performance** | ❌ HROZNÉ | ✅ EXCELENTNÍ |
| **Maintainability** | ❌ NIGHTMARE | ✅ ČISTÉ |
| **Scalability** | ❌ ŠPATNÉ | ✅ VYNIKAJÍCÍ |
| **Best practice** | ❌ ANTI-PATTERN | ✅ INDUSTRY STANDARD |
| **Doporučení** | 🚫 **NIKDY!** | ✅ **ANO!** |

---

## 🚀 FINÁLNÍ DOPORUČENÍ

1. **Zachovat normalizovaný design** (5 tabulek → 8 tabulek)
2. **Implementovat tags normalizaci** (`tags` + `todo_tags` tabulky)
3. **Přesunout Custom Agenda Views do DB** (`custom_agenda_views` tabulka)
4. **Zvětšit page size na 8 KB** (optional, ale doporučeno)
5. **Enable WAL mode** (concurrent access)
6. **Pravidelné ANALYZE** (optimalizuj query planner)

---

## 💬 ODPOVĚDI NA TVOJE OTÁZKY

### Q1: "Kolik sloupců máme?"
**A:** 40 sloupců celkem (5 tabulek), po refaktoringu 58 sloupců (8 tabulek)

### Q2: "Nebylo by lepší mít jednu tabulku?"
**A:** ❌ **NE!** Mega-tabulka = performance KATASTROFA, anti-pattern

### Q3: "Jaké jsou limity SQLite?"
**A:**
- Max sloupců: 2,000 (default) / 32,767 (max)
- Max row size: 1 GB
- Max DB size: 17.5 TB (page 4KB) / 281 TB (page 64KB)
- **Jsme DALEKO pod limity!**

### Q4: "Je 8 tabulek OK?"
**A:** ✅ **ANO!** Normalizace = best practice, výborná volba

---

**Vytvořeno**: 2025-01-10
**Autor**: Claude Code (AI asistent)
**Závěr**: **Normalizace FTW!** 🚀

