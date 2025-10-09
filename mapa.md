# 🗺️ VSA NAVIGATION MAP - Decision Tree pro AI Agenty

> **Účel**: Navigační mapa pro AI agenty při práci s VSA architekturou.
> **Kdy použít**: Vždy když dostaneš úkol - **ZAČNI TADY**, najdi svůj scénář v Quick Reference.

---

## ⚡ QUICK REFERENCE - Najdi svůj úkol a klikni

| 🎯 Typ úkolu | 📖 Kam jít | ⏱️ Čas |
|--------------|------------|--------|
| **➕ Přidat novou funkci** | [SCÉNÁŘ 1](#-scénář-1-přidej-novou-funkci--feature) | 2 min čtení |
| **🔧 Upravit existující feature** | [SCÉNÁŘ 2](#-scénář-2-uprav--refaktoruj-existující-feature) | 1 min čtení |
| **🐛 Opravit bug** | [SCÉNÁŘ 2: Bug fix](#-oprava-bugu) | 30 sec čtení |
| **♻️ Refaktorovat kód** | [SCÉNÁŘ 2: Refaktoring](#️-refaktoring--optimalizace) | 1 min čtení |
| **📣 Features potřebují komunikovat** | [SCÉNÁŘ 3](#-scénář-3-komunikace-mezi-features) | 1 min čtení |
| **🎨 Přidat shared utility** | [SCÉNÁŘ 4](#-scénář-4-přidej-shared-utility--infrastructure) | 1 min čtení |
| **⚙️ Feature flags / deployment** | [SCÉNÁŘ 5](#-scénář-5-feature-flags--deployment-strategy) | 30 sec čtení |
| **🏛️ DDD / bounded contexts** | [SCÉNÁŘ 6](#-scénář-6-ddd-integration---bounded-contexts) | 1 min čtení |

### 🚨 CRITICAL RULES - Přečti si VŽDY před začátkem:

| ❌ ZAKÁZÁNO | ✅ MÍSTO TOHO |
|-------------|--------------|
| `from features.other_feature import ...` | Použij Domain Events ([SCÉNÁŘ 3](#-scénář-3-komunikace-mezi-features)) |
| Business logika v `core/` | Dej do `features/` |
| Duplicita → okamžitě abstrahi | Rule of Three: abstrahi až na 3. použití ([vsa.md#duplicita](vsa.md#-duplicita-vs-abstrakce)) |
| "Možná budeme potřebovat..." | YAGNI: implementuj až když skutečně potřebuješ ([vsa.md#yagni](vsa.md#-yagni---you-arent-gonna-need-it)) |
| Kódovat bez čtení vsa.md | Najdi sekci v této mapě → klikni → čti → aplikuj |

### 📋 Quick Checklist - Před začátkem práce:

```
[ ] Našel jsem svůj scénář v Quick Reference výše
[ ] Klikl jsem na odkaz a přečetl relevantní sekci
[ ] Snapshot commit: git commit -m "🔖 snapshot: Před {co děláš}"
[ ] Použil jsem ultrathink pro critical changes (přidání/odstranění funkce)
[ ] Vytvořil jsem TODO list (TodoWrite) pokud 3+ kroky
```

### 🎯 Zlaté pravidlo:

> **"Quick Reference → Najdi scénář → Klikni → Čti → Aplikuj"**

---

## 🎯 JAK TENTO DOKUMENT POUŽÍVAT

**Pro AI agenty (Claude Code, Cursor, atd.):**

1. **⚡ Začni Quick Reference** - najdi typ úkolu (výše ↑)
2. **🔍 Klikni na scénář** - přejdi na detailní decision tree
3. **📚 Klikni na odkaz do vsa.md** - prostuduj best practices
4. **✅ Aplikuj postup** - dodržuj principy
5. **🔄 Commit změny** - atomické commity (CLAUDE.md)

**Důležité:**
- ❌ **NIKDY nezačínej kódovat bez čtení relevantní sekce**
- ✅ **VŽDY použij ultrathink pro critical changes**
- ✅ **VŽDY dodržuj principy: SOLID, YAGNI, DRY, Fail Fast**

---

## 🚦 DECISION TREE - Jaký je můj úkol?

### 📌 SCÉNÁŘ 1: "Přidej novou funkci / feature"

**Otázka:** Jde o NOVÝ business proces nebo ROZŠÍŘENÍ existujícího?

#### ✅ **NOVÝ business proces** → Vytvoř nový slice

**Kdy?**
- ✅ Jiný typ dokumentu (Method A vs Method B vs Method C)
- ✅ Jiná business funkce (Invoice processing vs Payment processing)
- ✅ Dá se vypnout samostatně (feature flag)
- ✅ Má vlastní validační pravidla
- ✅ Má vlastní lifecycle

**Co prostudovat:**
1. 📖 **[🔧 Jak přidávat features](vsa.md#-jak-správně-přidávat-features)** - proces přidání nové feature
2. 📖 **[🏗️ Struktura jednoho slice](vsa.md#️-struktura-jednoho-feature-slice)** - co všechno slice obsahuje
3. 📖 **[💡 Myšlení v business logice](vsa.md#-myšlení-v-business-logice)** - framework pro rozhodování
4. 📖 **[🚫 YAGNI](vsa.md#-yagni---you-arent-gonna-need-it)** - nepřidávej "pro budoucnost"
5. 📖 **[🧱 SOLID Principles](vsa.md#-solid-principles-v-vsa)** - SRP: 1 slice = 1 business funkce

**Checklist před začátkem:**
- [ ] Prostudoval jsem sekci "Jak přidávat features"
- [ ] Identifikoval jsem business funkci (ne technické řešení)
- [ ] Zkontroloval jsem že feature už neexistuje
- [ ] Vytvořil jsem TODO list s kroky (použij TodoWrite)
- [ ] Připravil jsem commit message (emoji + popis)

**Postup:**
```bash
# 1. Vytvoř složku
mkdir -p features/{nazev_business_funkce}

# 2. Vytvoř handler.py (viz vsa.md struktura slice)
# 3. Implementuj can_handle() a handle() (viz vsa.md IHandler interface)
# 4. Registruj v orchestration layer (pipeline)
# 5. Přidej testy
# 6. Commit: git commit -m "✨ feat: Přidání {nazev_business_funkce}"
```

---

#### ⚠️ **ROZŠÍŘENÍ existujícího** → Extension existujícího slice

**Kdy?**
- ✅ Stejný business proces, nová implementace (LibraryA vs LibraryB)
- ✅ Stejná funkce, nový parametr/konfigurace
- ✅ Alternative approach pro stejný problém

**Co prostudovat:**
1. 📖 **[🤔 Nový slice vs Extension](vsa.md#-jak-rozhodnout-nový-slice-vs-rozšíření-existujícího)** - rozhodovací framework
2. 📖 **[🔄 Duplicita vs Abstrakce](vsa.md#-duplicita-vs-abstrakce)** - kdy je duplicita OK
3. 📖 **[⚖️ High Cohesion, Low Coupling](vsa.md#️-high-cohesion-low-coupling)** - minimalizuj coupling mezi slices

**Postup:**
```python
# Uprav existující handler
features/{existujici_feature}/handler.py
  - Přidej novou logiku
  - Zachovej SRP (Single Responsibility)
  - Commit: git commit -m "✨ feat: Rozšíření {feature} o {co}"
```

---

### 📌 SCÉNÁŘ 2: "Uprav / refaktoruj existující feature"

**Otázka:** Co přesně měním?

#### 🔧 **Změna business logiky**

**Co prostudovat:**
1. 📖 **[⚡ Fail Fast](vsa.md#-fail-fast)** - validace na začátku, early returns
2. 📖 **[🧱 SOLID: OCP](vsa.md#-solid-principles-v-vsa)** - Open/Closed Principle
3. 📖 **[🔄 Duplicita vs Abstrakce](vsa.md#-duplicita-vs-abstrakce)** - AHA principle (Avoid Hasty Abstractions)

**Checklist:**
- [ ] 🔖 Snapshot commit PŘED změnou: `git commit -m "🔖 snapshot: Před refaktoringem {feature}"`
- [ ] 🧠 Použil jsem ultrathink pro analýzu dopadu?
- [ ] ✅ Testy prošly po změně
- [ ] 🔖 Commit po změně: `git commit -m "♻️ refactor: {popis změny}"`

---

#### 🐛 **Oprava bugu**

**Co prostudovat:**
1. 📖 **[⚡ Fail Fast](vsa.md#-fail-fast)** - reject bad inputs early
2. 📖 **[🛠️ Error handling](vsa.md#️-praktické-doplňky-pro-solo-developera)** - best practices

**Postup:**
```bash
# 1. Snapshot před opravou
git commit -m "🔖 snapshot: Před opravou bugu v {feature}"

# 2. Oprav bug
# 3. Přidej test který chrání před regresí
# 4. Commit
git commit -m "🐛 fix: {popis bugu} v {feature}"
```

---

#### ♻️ **Refaktoring / optimalizace**

**Co prostudovat:**
1. 📖 **[🔄 Duplicita vs Abstrakce](vsa.md#-duplicita-vs-abstrakce)** - kdy abstrahi, kdy ne
2. 📖 **[🚫 YAGNI](vsa.md#-yagni---you-arent-gonna-need-it)** - Rule of Three (abstrahi na 3. implementaci)
3. 📖 **[⚖️ High Cohesion, Low Coupling](vsa.md#️-high-cohesion-low-coupling)** - cíl refaktoringu

**Checklist:**
- [ ] 🔖 Snapshot commit před refaktoringem
- [ ] 🧠 Použil jsem ultrathink - je to skutečně potřeba?
- [ ] ✅ Refaktoring nezměnil chování (testy prošly)
- [ ] 📝 DRY: Je duplicita incidental nebo conceptual? (viz vsa.md)
- [ ] 🔖 Commit: `git commit -m "♻️ refactor: {důvod refaktoringu}"`

**Decision matrix:**
| Počet duplikací | Akce |
|-----------------|------|
| 1-2 | ❌ NIC - duplicita je levnější než špatná abstrakce |
| 3+ | ✅ ABSTRAHI - aplikuj Rule of Three |
| Business logika | ⚠️ ROZMYSLI - incidental vs conceptual duplication |

---

### 📌 SCÉNÁŘ 3: "Komunikace mezi features"

**Otázka:** Potřebují features A a B komunikovat?

#### ❌ **NIKDY nepřímé volání mezi features**

```python
# ❌ ŠPATNĚ - cross-feature import
from features.other_feature.handler import some_function  # ZAKÁZÁNO!
```

#### ✅ **Komunikace přes Domain Events**

**Co prostudovat:**
1. 📖 **[🏛️ DDD: Domain Events](vsa.md#️-ddd--vsa-compatibility)** - event-based komunikace
2. 📖 **[📣 Domain Events - Komunikace mezi slices](vsa.md#-domain-events---komunikace-mezi-slices)** - implementace event bus

**Postup:**
```python
# 1. Feature A emituje event
self.event_bus.publish(DocumentProcessedEvent(doc_id=doc.id))

# 2. Feature B subscribe na event
def on_document_processed(self, event: DocumentProcessedEvent):
    self._handle_external_event(event)
```

**Výhody:**
- ✅ Zero coupling mezi features
- ✅ Easy testing (mockni event bus)
- ✅ Scalability (později změníš na RabbitMQ/Kafka)

---

### 📌 SCÉNÁŘ 4: "Přidej shared utility / infrastructure"

**Otázka:** Patří to do `core/` nebo do feature?

#### 🎨 **Core Infrastructure** (technická záležitost)

**Kdy?**
- ✅ DB connector, HTTP client, email sender
- ✅ Používá 3+ features
- ✅ Žádná business logika (pure technical)

**Co prostudovat:**
1. 📖 **[🎨 Core Infrastructure](vsa.md#-core-infrastructure---co-tam-patří)** - co patří do core/
2. 📖 **[⚖️ High Cohesion, Low Coupling](vsa.md#️-high-cohesion-low-coupling)** - shared kernel vs duplicita

**Struktura:**
```python
core/
├── infrastructure/    # DB, HTTP, Email, FileStorage
│   ├── database.py
│   ├── http_client.py
│   └── email_sender.py
├── interfaces/        # Abstrakce (IRepository, IClient)
└── domain/            # Entities (pokud shared mezi features)
```

---

#### 🧮 **Core Utils** (pure functions)

**Kdy?**
- ✅ Pure function bez business kontextu
- ✅ Použitelné v JAKÉKOLIV aplikaci (string utils, date helpers)
- ✅ Nemá side effects

**Struktura:**
```python
core/
└── utils/
    ├── string_helpers.py   # capitalize_first, slugify
    ├── date_helpers.py     # parse_date, format_date
    └── file_helpers.py     # safe_filename, get_extension
```

**⚠️ POZOR:**
```python
# ❌ NENÍ pure util - patří do feature!
def validate_invoice_amount(amount: float) -> bool:
    return amount > 0  # Business pravidlo!

# ✅ Pure util - OK v core/utils/
def is_positive(value: float) -> bool:
    return value > 0  # Generic logic
```

---

### 📌 SCÉNÁŘ 5: "Feature flags / deployment strategy"

**Otázka:** Potřebuji dark deploy / progressive rollout?

**Co prostudovat:**
1. 📖 **[⚙️ Feature Flags - Feature Toggles](vsa.md#️-feature-flags---feature-toggles)** - kompletní guide
2. 📖 **[4 Deployment Strategies](vsa.md#️-feature-flags---feature-toggles)** - Dark Deploy, Progressive Rollout, Instant Rollback, Canary

**Implementace:**
```python
# 1. Config
class Settings(BaseSettings):
    new_feature_enabled: bool = False  # Dark deploy!

# 2. Handler
class NewFeatureHandler(IHandler):
    def can_handle(self, entity: Entity) -> bool:
        if not settings.new_feature_enabled:
            return False  # Feature disabled
        return True
```

**Deployment postup:**
1. **Dark Deploy** - deploy s flag OFF
2. **Test na prod** - zkontroluj že to nerozbilo systém
3. **Progressive Rollout** - 1% → 10% → 100%
4. **Monitor** - watch logs, metrics
5. **Instant Rollback** - pokud problém, změň flag (30 sekund)

---

### 📌 SCÉNÁŘ 6: "DDD integration - bounded contexts"

**Otázka:** Máme velký projekt s multiple bounded contexts?

**Kdy použít DDD s VSA:**
| Velikost projektu | Strategic DDD | Tactical DDD |
|-------------------|---------------|--------------|
| Malý (< 5 features) | ⚠️ MAYBE | ❌ NE (YAGNI) |
| Střední (5-20 features) | ✅ ANO | ⚠️ LITE |
| Velký (20+ features) | ✅ MUST | ✅ ANO |

**Co prostudovat:**
1. 📖 **[🏛️ DDD & VSA Compatibility](vsa.md#️-ddd--vsa-compatibility)** - kompletní guide
2. 📖 **[📦 Bounded Contexts v VSA](vsa.md#-bounded-contexts-v-vsa)** - jak mapovat context → feature folder
3. 📖 **[🗣️ Ubiquitous Language](vsa.md#️-ubiquitous-language---společný-jazyk)** - business terminology v kódu
4. 📖 **[🧩 DDD Lite v VSA](vsa.md#-ddd-lite-v-vsa---praktický-přístup)** - kdy použít které DDD patterns

**Struktura:**
```python
bounded_contexts/
├── OrderManagement/     # DDD Bounded Context
│   └── features/
│       ├── place_order/      # VSA slice
│       └── cancel_order/     # VSA slice
│
└── PaymentProcessing/   # DDD Bounded Context
    └── features/
        └── process_payment/  # VSA slice
```

---

## 🎯 RYCHLÉ REFERENCE - Nejčastější úkoly

### ➕ Přidání nové feature (step-by-step)

```bash
# 1. PROSTUDUJ
- 📖 vsa.md#jak-přidávat-features
- 📖 vsa.md#struktura-jednoho-slice
- 📖 vsa.md#solid-principles-v-vsa

# 2. SNAPSHOT
git commit -m "🔖 snapshot: Před přidáním {nova_feature}"

# 3. VYTVOŘ STRUKTURU
mkdir -p features/{nova_feature}
touch features/{nova_feature}/handler.py
touch features/{nova_feature}/__init__.py

# 4. IMPLEMENTUJ
# - Inherit z IHandler
# - Implementuj can_handle() a handle()
# - Přidej Fail Fast validace

# 5. REGISTRUJ
# - Přidej do orchestration layer (pipeline)

# 6. TESTY
# - Unit testy pro handler

# 7. COMMIT
git commit -m "✨ feat: Přidání {nova_feature}"
```

---

### 🔧 Úprava existující feature

```bash
# 1. PROSTUDUJ
- 📖 vsa.md#fail-fast (validace)
- 📖 vsa.md#solid-principles-v-vsa (OCP)
- 📖 vsa.md#duplicita-vs-abstrakce (AHA principle)

# 2. SNAPSHOT
git commit -m "🔖 snapshot: Před úpravou {existujici_feature}"

# 3. ULTRATHINK
# - Použij ultrathink pro critical changes
# - Analyzuj dopad změny

# 4. UPRAV
# - Zachovej SRP
# - Fail Fast na začátku
# - Early returns

# 5. TESTY
# - Ujisti se že testy prošly

# 6. COMMIT
git commit -m "♻️ refactor: {popis} v {existujici_feature}"
```

---

### 🐛 Oprava bugu

```bash
# 1. SNAPSHOT
git commit -m "🔖 snapshot: Před opravou bugu v {feature}"

# 2. IDENTIFIKUJ
# - Kde je problém?
# - Proč vznikl? (chybí Fail Fast validace?)

# 3. OPRAV
# - Přidej Fail Fast validaci pokud chyběla
# - Explicit exception místo silent fail

# 4. TEST
# - Přidej test který chrání před regresí

# 5. COMMIT
git commit -m "🐛 fix: {popis bugu} v {feature}"
```

---

### 🔄 Refaktoring - duplicitní kód

```bash
# 1. DECISION MATRIX
Počet duplikací?
- 1-2: ❌ NIC (duplicita je levnější)
- 3+: ✅ ABSTRAHI (Rule of Three)

# 2. PROSTUDUJ
- 📖 vsa.md#duplicita-vs-abstrakce
- 📖 vsa.md#yagni (Rule of Three)

# 3. SNAPSHOT
git commit -m "🔖 snapshot: Před refaktoringem duplicit"

# 4. ABSTRAHI (pouze pokud 3+ duplikace)
# - Vytvoř abstrakci v core/ nebo shared modul
# - Refaktoruj všechny 3+ místa

# 5. TESTY
# - Ujisti se že chování je stejné

# 6. COMMIT
git commit -m "♻️ refactor: Odstranění duplicit pomocí {abstrakce}"
```

---

## 🧭 NAVIGAČNÍ ZKRATKY - Kam jít pro konkrétní téma

### 🎯 Principy a Best Practices
| Téma | Odkaz na vsa.md |
|------|-----------------|
| SOLID v VSA | [🧱 SOLID Principles](vsa.md#-solid-principles-v-vsa) |
| High Cohesion, Low Coupling | [⚖️ High Cohesion](vsa.md#️-high-cohesion-low-coupling) |
| YAGNI (You Aren't Gonna Need It) | [🚫 YAGNI](vsa.md#-yagni---you-arent-gonna-need-it) |
| DRY vs Duplicita | [🔄 Duplicita vs Abstrakce](vsa.md#-duplicita-vs-abstrakce) |
| Fail Fast | [⚡ Fail Fast](vsa.md#-fail-fast) |

### 🏗️ Struktura a Implementace
| Téma | Odkaz na vsa.md |
|------|-----------------|
| Základní VSA struktura | [📁 Základní struktura složek](vsa.md#-základní-struktura-složek) |
| Struktura jednoho slice | [🏗️ Struktura slice](vsa.md#️-struktura-jednoho-feature-slice) |
| Jak přidávat features | [🔧 Jak přidávat features](vsa.md#-jak-správně-přidávat-features) |
| Core Infrastructure | [🎨 Core Infrastructure](vsa.md#-core-infrastructure---co-tam-patří) |
| Nový slice vs Extension | [🤔 Rozhodování](vsa.md#-jak-rozhodnout-nový-slice-vs-rozšíření-existujícího) |

### 🛠️ Praktické doplňky
| Téma | Odkaz na vsa.md |
|------|-----------------|
| Feature Flags | [⚙️ Feature Flags](vsa.md#️-feature-flags---feature-toggles) |
| DDD & VSA Compatibility | [🏛️ DDD & VSA](vsa.md#️-ddd--vsa-compatibility) |
| Domain Events | [📣 Domain Events](vsa.md#-domain-events---komunikace-mezi-slices) |
| Ubiquitous Language | [🗣️ Ubiquitous Language](vsa.md#️-ubiquitous-language---společný-jazyk) |
| Error Handling | [🛠️ Praktické doplňky](vsa.md#️-praktické-doplňky-pro-solo-developera) |

### ⚠️ Chyby a Checklist
| Téma | Odkaz na vsa.md |
|------|-----------------|
| Časté chyby | [⚠️ Časté chyby](vsa.md#️-časté-chyby-a-jak-se-jim-vyhnout) |
| Checklist správnosti | [🎯 Checklist](vsa.md#-checklist-jsem-na-správné-cestě) |

---

## 📋 CHECKLIST PRO AI AGENTY - Před začátkem kódování

### ✅ Před přidáním nové feature:
- [ ] Přečetl jsem **[vsa.md#jak-přidávat-features](vsa.md#-jak-správně-přidávat-features)**
- [ ] Identifikoval jsem business funkci (ne technické řešení)
- [ ] Zkontroloval jsem že feature už neexistuje
- [ ] Rozhodl jsem se: Nový slice vs Extension (viz **[decision tree](vsa.md#-jak-rozhodnout-nový-slice-vs-rozšíření-existujícího)**)
- [ ] Použil jsem **YAGNI** - feature je skutečně potřeba TEĎ?
- [ ] Vytvořil jsem TODO list (TodoWrite)
- [ ] Snapshot commit: `git commit -m "🔖 snapshot: Před přidáním {feature}"`

### ✅ Před refaktoringem:
- [ ] Přečetl jsem **[vsa.md#duplicita-vs-abstrakce](vsa.md#-duplicita-vs-abstrakce)**
- [ ] Použil jsem **ultrathink** - je to skutečně potřeba?
- [ ] Zkontroloval jsem **Rule of Three** - je to 3. duplikace?
- [ ] Incidental vs Conceptual duplication - která je to?
- [ ] Snapshot commit: `git commit -m "🔖 snapshot: Před refaktoringem {co}"`

### ✅ Před úpravou existující feature:
- [ ] Přečetl jsem **[vsa.md#fail-fast](vsa.md#-fail-fast)**
- [ ] Přečetl jsem **[vsa.md#solid-principles](vsa.md#-solid-principles-v-vsa)** (OCP)
- [ ] Použil jsem **ultrathink** pro critical changes
- [ ] Snapshot commit: `git commit -m "🔖 snapshot: Před úpravou {feature}"`
- [ ] Testy prošly po změně

### ✅ Po dokončení úkolu:
- [ ] Testy prošly
- [ ] Dodržel jsem principy z vsa.md (SOLID, YAGNI, DRY, Fail Fast)
- [ ] Vytvořil jsem commit s emoji + popis (viz CLAUDE.md)
- [ ] Zkontroloval jsem **[vsa.md#checklist](vsa.md#-checklist-jsem-na-správné-cestě)**

---

## 🚨 CRITICAL RULES - NIKDY NEPŘEKROČ

### ❌ ZAKÁZÁNO:

1. **Cross-feature imports**
   ```python
   # ❌ NIKDY!
   from features.other_feature.handler import something
   ```
   → Použij Domain Events místo toho

2. **Business logika v core/**
   ```python
   # ❌ NIKDY!
   # core/utils/invoice_validator.py
   def validate_invoice(invoice): ...  # Business logika!
   ```
   → Business logika patří do features/

3. **Shared mezi 2 features = automaticky do core/**
   ```python
   # ❌ ŠPATNĚ!
   # Použito ve 2 features → dej do core/
   ```
   → Použij **Rule of Three** - abstrahi až na 3. použití

4. **Spekulativní features (YAGNI violation)**
   ```python
   # ❌ NIKDY!
   features/blockchain_integration/  # "Možná budeme potřebovat"
   ```
   → Implementuj POUZE když skutečně potřebuješ TEĎ

5. **Kódování bez studia vsa.md**
   ```python
   # ❌ NIKDY!
   # Začít kódovat bez přečtení relevantní sekce
   ```
   → VŽDY nejprve prostuduj odpovídající sekci ve vsa.md

---

## 💡 PRO-TIPY pro AI agenty

### 🧠 Ultrathink Usage

**Kdy použít ultrathink:**
- ✅ **Odstranění funkce** - analýza dopadu, dependencies, rizika
- ✅ **Přidání komplexní funkce** - hodnocení nutnosti, alternativy
- ✅ **Refaktoring** - je to skutečně potřeba? YAGNI?
- ✅ **Architektonická rozhodnutí** - bounded contexts, abstractions

**Kdy NEPOUŽÍVAT ultrathink:**
- ❌ Rutinní bug fix
- ❌ Přidání jednoduchého parametru
- ❌ Update dokumentace

### 🔖 Git Commit Strategy

**VŽDY snapshot před risky operací:**
```bash
# Před refaktoringem
git commit -m "🔖 snapshot: Před refaktoringem {feature}"

# Před odstraněním funkce
git commit -m "🔖 snapshot: Před odstraněním {feature}"

# Před komplexní změnou
git commit -m "🔖 snapshot: Před {popis změny}"
```

**Atomické commity:**
- ✅ 1 commit = 1 logická změna
- ✅ Commit hned po dokončení úkolu (ne batch)
- ✅ Descriptive message (emoji + co + proč)

### 📝 TODO List Strategy

**VŽDY použij TodoWrite pro:**
- ✅ Přidání nové feature (3+ kroky)
- ✅ Refaktoring (komplexní změny)
- ✅ Bug fix s multiple soubory
- ✅ Vždy když uživatel poskytne seznam úkolů

**NEPOUŽÍVEJ TodoWrite pro:**
- ❌ Jednoduchá změna (1-2 kroky)
- ❌ Triviální update
- ❌ Čistě konverzační dotazy

---

## 🎓 ZÁVĚR - Key Takeaways

### Pro AI agenty pracující s VSA architekturou:

1. **📖 VŽDY začni studiem vsa.md** - najdi odpovídající sekci v tomto mapa.md
2. **🎯 Decision tree first** - identifikuj typ úkolu PŘED kódováním
3. **🧠 Ultrathink pro critical changes** - odstranění/přidání funkce, refaktoring
4. **🔖 Snapshot commits** - před risky operací VŽDY
5. **✅ Dodržuj principy** - SOLID, YAGNI, DRY, Fail Fast, High Cohesion/Low Coupling
6. **📝 TodoWrite pro komplexní úkoly** - organizuj práci systematicky
7. **❌ Cross-feature imports = ZAKÁZÁNO** - použij Domain Events
8. **🚫 YAGNI** - implementuj POUZE co je potřeba TEĎ
9. **🧪 Testy prošly** - před commitem VŽDY

### Zlaté pravidlo:

> **"Když nevíš co dělat, vrať se k mapa.md → najdi decision tree → prostuduj odpovídající sekci ve vsa.md → aplikuj."**

**Tato mapa je tvůj kompas. Použij ji.** 🧭

---

## 📚 META - O tomto dokumentu

**Verzování:**
- 📅 Vytvořeno: 2025-09-30
- 📝 Autor: Claude Code (AI assistant)
- 🎯 Účel: Navigační mapa pro AI agenty pracující s VSA

**Maintenance:**
- ✅ Aktualizuj když se mění vsa.md
- ✅ Přidávej nové workflows podle potřeby
- ✅ Udržuj odkazy na vsa.md funkční

**Feedback:**
- 💬 Pokud něco chybí, přidej nový scénář
- 💬 Pokud je něco nejasné, upřesni decision tree
- 💬 Tento dokument je **living document** - evolvuje s projektem