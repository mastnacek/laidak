📘 VERTICAL SLICE ARCHITECTURE (VSA) - UNIVERZÁLNÍ NÁVOD PRO CLAUDE CODE

> **Účel**: Univerzální průvodce pro výstavbu JAKÉHOKOLIV systému s VSA architekturou.
> **Cílová skupina**: Claude Code AI asistent při vývoji nového systému.
> **Použití**: Aplikovatelné na web API, file processing, desktop apps, microservices, atd.

---

## 🗺️ NAVIGACE PRO AI AGENTY

**Pokud nevíš kde začít nebo jaký postup použít:**

👉 **[Otevři mapa.md](mapa.md)** - Navigační mapa s decision tree pro všechny typy úkolů

**mapa.md obsahuje:**
- ⚡ Quick Reference - najdi typ úkolu za 10 sekund
- 🚦 Decision Trees - 6 scénářů (přidat funkci, upravit, refaktorovat, komunikace, shared utils, feature flags, DDD)
- 📋 Step-by-step guides - konkrétní postupy
- 🚨 Critical Rules - co NIKDY nedělat
- 📊 Checklists - před/po každém úkolu

**Zlaté pravidlo:**
> Když dostaneš úkol → otevři [mapa.md](mapa.md) → najdi scénář → vrať se sem pro detaily

---

## 📚 OBSAH DOKUMENTU

### 🎯 Základy VSA
- [📋 Quick Reference Card](#-quick-reference-card) - Rychlý přehled základních konceptů
- [🎯 Co je VSA?](#-co-je-vertical-slice-architecture) - Základní princip a srovnání s tradičními přístupy
- [📁 Základní struktura složek](#-základní-struktura-složek) - Organizace projektu

### 🧱 Principy a Best Practices
- [🧱 SOLID Principles v VSA](#-solid-principles-v-vsa) - Aplikace SOLID v kontextu VSA
- [⚖️ High Cohesion, Low Coupling](#️-high-cohesion-low-coupling) - Klíčový princip od Jimmy Bogarda
- [🚫 YAGNI](#-yagni---you-arent-gonna-need-it) - Nepřidávej features "pro budoucnost"
- [🔄 Duplicita vs Abstrakce](#-duplicita-vs-abstrakce) - Kdy je duplicita OK a kdy ne
- [⚡ Fail Fast](#-fail-fast) - Validace na začátku, early returns
- [📁 Configuration Structure](#-configuration-structure---settingspy-vs-configpy) - settings.py vs config.py

### 🏗️ Struktura Features
- [🏗️ Struktura jednoho slice](#️-struktura-jednoho-feature-slice) - Minimální a rozšířená struktura
- [🤔 Rozhodování: Nový slice vs Extension](#-jak-rozhodnout-nový-slice-vs-rozšíření-existujícího) - Kdy vytvořit nový slice
- [💡 Myšlení v business logice](#-myšlení-v-business-logice) - Framework pro rozhodování

### 🔧 Implementace
- [🔧 Jak přidávat features](#-jak-správně-přidávat-features) - Proces přidání nové feature
- [🎨 Core Infrastructure](#-core-infrastructure---co-tam-patří) - Co patří do core/
- [🚀 Postup při výstavbě od nuly](#-postup-při-výstavbě-od-nuly) - Fáze 1-4

### 🛠️ Praktické doplňky
- [🛠️ Praktické doplňky pro solo developera](#️-praktické-doplňky-pro-solo-developera) - DI, error handling, DB, testing, logging
- [⚙️ Feature Flags](#️-feature-flags---feature-toggles) - Deployment strategy a best practices
- [🏗️ DDD & VSA Compatibility](#️-ddd--vsa-compatibility) - Integrace s Domain-Driven Design

### ⚠️ Chyby a Checklist
- [⚠️ Časté chyby](#️-časté-chyby-a-jak-se-jim-vyhnout) - Co nedělat
- [🎯 Checklist](#-checklist-jsem-na-správné-cestě) - Kontrola správnosti

### 📖 Reference
- [📚 Doporučená četba](#-doporučená-četba-pro-hlubší-pochopení) - Další zdroje
- [🎓 Závěrečné principy](#-závěrečné-principy) - Shrnutí klíčových myšlenek

---

## 📋 QUICK REFERENCE CARD

### 🏗️ Základní struktura
```
project_root/
├── core/              # Shared kernel (domain, interfaces, infrastructure)
├── features/          # Vertikální slices (business funkce)
├── pipeline/          # Orchestrace features
└── config/            # Konfigurace (settings, feature flags)
```

### ➕ Přidání nové feature (3 kroky)
```bash
1. mkdir -p features/{nova_feature}
2. Vytvoř handler.py (implement business interface)
3. Registruj v orchestration layer
```

### 🤔 Rozhodovací strom

**Nový slice?**
- ✅ Jiný business proces (Method A vs Method B vs Method C)
- ✅ Jiná technologie/metoda
- ✅ Dá se vypnout samostatně

**Extension existující?**
- ✅ Stejný proces, jiná implementace (Library A vs Library B)
- ✅ Stejná business funkce, nový parametr

**Core infrastructure?**
- ✅ Technická záležitost (DB, HTTP client, email)
- ✅ Používá 3+ features
- ✅ Žádná business logika

**Core utils?**
- ✅ Pure function bez business kontextu
- ✅ Použitelné v JAKÉKOLIV aplikaci

### 🧪 Testing pattern
```python
# Mock dependencies v konstruktoru
handler = FeatureHandler(db=mock_db, client=mock_client)
assert handler.can_handle(document) == expected
```

### 🛡️ Error handling pattern
```python
temp_files = []
try:
    # Zpracování + track temp files
finally:
    # Cleanup temp files
```

### ⚖️ Rule of Three
```
1. První impl → Piš do feature
2. Druhá impl → Zkopíruj (duplicita OK)
3. Třetí impl → STOP! Abstrahi do core
```

### 📏 Feature sizing
- **Příliš malá**: < 100 LOC, 1-2 soubory
- **Golden size**: 200-1000 LOC, 3-8 souborů
- **Příliš velká**: > 2000 LOC, 10+ souborů

---

## 🎯 CO JE VERTICAL SLICE ARCHITECTURE?
Základní princip
VSA organizuje kód podle BUSINESS FUNKCÍ, ne podle technických vrstev.

**Tradiční přístup (špatně):**
```
"Potřebuji implementovat [business feature]"
→ Otevři controllers/ + models/ + services/ + utils/
→ Změň 5+ souborů napříč celou aplikací
```

**VSA přístup (správně):**
```
"Potřebuji implementovat [business feature]"
→ Otevři features/{business_feature}/
→ Všechno je tam - handler, logika, validace, konverze
```

Klíčová myšlenka
"Co děláme" (business) > "Jak to děláme" (technika)
Každý vertikální slice = 1 kompletní business funkce od začátku do konce.
📁 ZÁKLADNÍ STRUKTURA SLOŽEK
project_root/
├── core/                    # Shared kernel (MINIMUM!)
│   ├── domain/             # Doménové entity (Document, Result)
│   ├── interfaces/         # Abstraktní třídy/protocols
│   └── infrastructure/     # Technická infrastruktura (DB, email)
│
├── features/               # VERTICAL SLICES
│   ├── feature_a/         # Jedna business funkce
│   ├── feature_b/         # Další business funkce
│   └── feature_c/         # Další business funkce
│
├── pipeline/              # Orchestrace features
│   └── processing_pipeline.py
│
├── config/                # Konfigurace
│   ├── settings.py       # Environment variables
│   └── feature_flags.py  # Feature toggles
│
└── app.py                 # Entry point
Pravidla pro organizaci
✅ DO core/ patří:
Domain entities - základní business objekty (Document, Invoice, Payment)
Interfaces - abstraktní kontrakty (IDocumentHandler, IRepository)
Infrastructure - technické záležitosti (database, email, file system, HTTP client)
Exceptions - doménové výjimky
Constants - skutečné konstanty (ne business rules!)
✅ DO features/ patří:
Kompletní business funkce - vše potřebné pro jeden use case
Feature-specific logika - parsování, validace, konverze
Feature-specific konfigurace - nastavení pro tuto konkrétní funkci
❌ NIKDY nevytvářej:
utils/ - vše má business kontext, patří do feature nebo core
helpers/ - stejný důvod
common/ - buď core, nebo feature
shared/ - buď core, nebo duplicity (duplicity jsou OK!)

---

## 🧱 SOLID PRINCIPLES v VSA

**VSA přirozeně aplikuje SOLID principy z objektově orientovaného programování.**

Tyto principy nejsou ve VSA "extra vrstva", ale jsou **inherentně zabudované** v samotné architektuře.

### **SRP - Single Responsibility Principle**

> "A class should have one, and only one, reason to change" - Robert C. Martin

**V kontextu VSA:**
- ✅ **1 slice = 1 business funkce = 1 důvod ke změně**
- Změna business požadavku ovlivní **pouze jeden slice**
- Ostatní slices zůstávají nedotčené

**Příklad:**
```
Změna: "Upravit validaci pro Method A"
→ Změníš pouze: features/method_a/validator.py
→ Nedotčeno: features/method_b/, features/method_c/
```

**Porušení SRP by bylo:**
```python
# ❌ ŠPATNĚ - God Handler s více zodpovědnostmi
class UniversalHandler:
    def handle_method_a(self): ...  # Responsibility 1
    def handle_method_b(self): ...  # Responsibility 2
    def handle_method_c(self): ...  # Responsibility 3
    # Změna method_a ovlivní celou třídu!
```

---

### **OCP - Open/Closed Principle**

> "Software entities should be open for extension, but closed for modification" - Bertrand Meyer

**V kontextu VSA:**
- ✅ **Přidání funkce = nový slice** (open for extension)
- ✅ **Existující slices se nemění** (closed for modification)

**Příklad:**
```
Nový požadavek: "Přidat Method D"

✅ SPRÁVNĚ (VSA approach):
1. mkdir features/method_d/
2. Implementuj handler
3. Registruj v pipeline
→ Žádná modifikace existujících features!

❌ ŠPATNĚ (porušení OCP):
1. Otevři features/existing_handler.py
2. Přidej if/else větev pro Method D
→ Modifikace existujícího kódu = riziko regrese!
```

**VSA garantuje OCP:**
- Pipeline se dynamicky rozšiřuje o nové handlery
- Existující handlery nejsou nikdy modifikovány

---

### **LSP - Liskov Substitution Principle**

> "Objects of a superclass should be replaceable with objects of its subclasses without breaking the application"

**V kontextu VSA:**
- ✅ **Všechny handlery jsou zaměnitelné přes společný interface**
- Pipeline neví o konkrétních implementacích
- Může používat jakýkoliv handler který implementuje `IHandler`

**Příklad:**
```python
# core/interfaces/i_handler.py
class IHandler(ABC):
    @abstractmethod
    def can_handle(self, entity: Entity) -> bool:
        pass

    @abstractmethod
    def handle(self, entity: Entity) -> Result:
        pass

# Pipeline očekává IHandler - nezajímá ji konkrétní typ
class Pipeline:
    def __init__(self, handlers: list[IHandler]):  # LSP!
        self.handlers = handlers

    def process(self, entity: Entity):
        for handler in self.handlers:
            if handler.can_handle(entity):  # Polymorfismus
                return handler.handle(entity)
```

**LSP zajišťuje:**
- Můžeš přidat/odebrat handler bez změny pipeline
- Všechny handlery musí respektovat kontrakt interface

---

### **ISP - Interface Segregation Principle**

> "Clients should not be forced to depend on methods they do not use"

**V kontextu VSA:**
- ✅ **Tenké, zaměřené interface** (can_handle + handle)
- ❌ Žádné "fat interfaces" s mnoha metodami

**Příklad:**
```python
# ✅ SPRÁVNĚ - tenký interface (ISP compliant)
class IDocumentHandler(ABC):
    @abstractmethod
    def can_handle(self, document: Document) -> bool:
        """Jen 2 metody - minimum nutné"""

    @abstractmethod
    def handle(self, document: Document) -> Result:
        pass

# ❌ ŠPATNĚ - fat interface (porušení ISP)
class IDocumentProcessor(ABC):
    @abstractmethod
    def validate(self): pass
    @abstractmethod
    def parse(self): pass
    @abstractmethod
    def transform(self): pass
    @abstractmethod
    def enrich(self): pass
    @abstractmethod
    def save(self): pass
    @abstractmethod
    def notify(self): pass
    # Handler musí implementovat VŠECHNY, i když některé nepotřebuje!
```

**ISP ve VSA znamená:**
- Každý handler implementuje jen minimum
- Žádné "dummy implementations"

---

### **DIP - Dependency Inversion Principle**

> "Depend upon abstractions, not concretions"

**V kontextu VSA:**
- ✅ **Features závisí na abstrakcích** (core/interfaces)
- ✅ **Pipeline závisí na abstrakcích**, ne konkrétních handlerech
- ❌ Features **nikdy** nezávisí na jiných konkrétních features

**Příklad:**
```python
# ✅ SPRÁVNĚ - závislost na abstrakci (DIP compliant)
# features/method_a/handler.py
from core.interfaces import IRepository, IExternalClient  # Abstrakce!

class MethodAHandler:
    def __init__(self, repo: IRepository, client: IExternalClient):
        self.repo = repo      # Abstrakce - ne konkrétní SQLiteRepo
        self.client = client  # Abstrakce - ne konkrétní HTTPClient

# ❌ ŠPATNĚ - závislost na konkrétní implementaci (porušení DIP)
from core.infrastructure.sqlite_repo import SQLiteRepository  # Konkrétní!
from features.method_b.parser import MethodBParser  # Konkrétní feature!

class MethodAHandler:
    def __init__(self):
        self.repo = SQLiteRepository()  # Tight coupling!
        self.parser = MethodBParser()   # Cross-feature dependency!
```

**DIP diagram:**
```
Pipeline (high-level)
    ↓ depends on
IHandler interface (abstraction)
    ↑ implements
Concrete Handlers (low-level)
```

---

### 🎯 SOLID v VSA - Shrnutí

| SOLID Princip | Jak VSA aplikuje | Výhoda |
|---------------|------------------|--------|
| **SRP** | 1 slice = 1 business funkce | Změny izolované do jednoho slice |
| **OCP** | Nový slice bez modifikace existujících | Žádné riziko regrese |
| **LSP** | Všechny handlery zaměnitelné přes interface | Flexibilní pipeline |
| **ISP** | Tenký interface (2 metody) | Žádné dummy implementations |
| **DIP** | Závislost na core/interfaces, ne konkrétních třídách | Loose coupling, testovatelnost |

**Klíčové poznání:**

VSA není "SOLID compliant protože se snažíme" - VSA **JE SOLID by design**.

Pokud správně dodržuješ VSA pravidla, automaticky aplikuješ SOLID principy.

---

## ⚖️ HIGH COHESION, LOW COUPLING

**Klíčový princip VSA od Jimmy Bogarda:**

> "Minimize coupling **between** slices, and maximize coupling **in** a slice"

Tento princip je **JÁDRO** Vertical Slice Architecture a odlišuje ji od tradičních layered architektur.

### 🔗 Co je Cohesion (Soudržnost)?

**Cohesion** = míra, jak moc spolu souvisí jednotlivé části modulu.

- **High Cohesion** = všechny části modulu spolupracují na jednom cíli
- **Low Cohesion** = části modulu dělají nesouvisející věci

**V tradičních layered architekturách:**
```
controllers/  (low cohesion - všechny controllery pohromadě)
├── user_controller.py
├── order_controller.py
└── payment_controller.py

services/     (low cohesion - všechny services pohromadě)
├── user_service.py
├── order_service.py
└── payment_service.py
```

**Ve VSA:**
```
features/
├── user_management/     (high cohesion - všechno pro users pohromadě)
│   ├── handler.py
│   ├── validator.py
│   └── repository.py
│
└── order_processing/    (high cohesion - všechno pro orders pohromadě)
    ├── handler.py
    ├── validator.py
    └── repository.py
```

### 🔓 Co je Coupling (Vazba)?

**Coupling** = míra závislosti mezi moduly.

- **Low Coupling** = moduly jsou na sobě nezávislé
- **High Coupling** = moduly závisí jeden na druhém

### ⚖️ VSA Princip: High Cohesion IN, Low Coupling BETWEEN

**High Cohesion UVNITŘ slice:**
```python
features/payment_processing/
├── handler.py           # ↕ High coupling (OK!)
├── validator.py         # ↕ Všechny součásti
├── payment_gateway.py   # ↕ úzce spolupracují
├── fraud_detector.py    # ↕ na JEDNOM cíli
└── config.py            # ↕ (payment processing)
```

✅ **Výhoda:** Vše co potřebuješ pro platby je na jednom místě
- Změna payment logiky = změna jedné složky
- Není třeba skákat mezi controllers/services/repositories

**Low Coupling MEZI slices:**
```python
features/
├── payment_processing/   # ↔ Low coupling (žádná závislost)
├── order_management/     # ↔ Nezávislé slices
└── user_authentication/  # ↔ Komunikace jen přes core/interfaces
```

✅ **Výhoda:** Můžeš smazat/upravit jeden slice bez dopadu na ostatní
- Payment se může vyvíjet nezávisle na Order
- Žádné "ripple effects" napříč systémem

### 📊 Srovnání: Layered vs VSA

**Layered Architecture (Low Cohesion, High Coupling):**
```
Změna "Add VAT calculation to payments"

→ Otevři: controllers/payment_controller.py
→ Otevři: services/payment_service.py
→ Otevři: models/payment_model.py
→ Otevři: repositories/payment_repository.py

Coupling MEZI layers: HIGH (controller závisí na service závisí na repo)
Cohesion V layer: LOW (payment mezi 10+ jinými věcmi v každé vrstvě)
```

**VSA (High Cohesion, Low Coupling):**
```
Změna "Add VAT calculation to payments"

→ Otevři: features/payment_processing/

Coupling MEZI slices: LOW (payment je nezávislý)
Cohesion V slice: HIGH (všechno payment pohromadě)
```

### 🎯 Praktické důsledky

**Groupování kódu:**
```python
# ✅ SPRÁVNĚ - related code pohromadě (high cohesion)
features/invoice_processing/
├── handler.py
├── pdf_parser.py
├── validator.py
└── isdoc_generator.py
# Všechno souvisí s invoices → high cohesion

# ❌ ŠPATNĚ - related code rozházený (low cohesion)
parsers/pdf_parser.py        # Technická vrstva
validators/invoice_validator.py  # Jiná technická vrstva
generators/isdoc_generator.py     # Další technická vrstva
# Invoice logika roztříštěná → low cohesion
```

**Minimalizace dependencies:**
```python
# ✅ SPRÁVNĚ - low coupling mezi slices
# features/payment/handler.py
from core.interfaces import INotificationService  # Abstrakce!

# ❌ ŠPATNĚ - high coupling mezi slices
from features.notification.email_sender import EmailSender  # Konkrétní!
```

### 📐 Metriky

**Jak změřit:**

**Cohesion metrika:**
- Počet souborů které musíš otevřít pro změnu jedné feature?
- ✅ VSA: 1-3 soubory (high cohesion)
- ❌ Layered: 5-10 souborů (low cohesion)

**Coupling metrika:**
- Kolik features ovlivníš když změníš jeden slice?
- ✅ VSA: 0 features (low coupling)
- ❌ Layered: 3-5 features (high coupling)

### 🎓 Závěr

> "Things that change together should be near each other" - Jimmy Bogard

VSA zajišťuje že:
- **Cohesion** je maximalizována uvnitř slice (všechno pohromadě)
- **Coupling** je minimalizován mezi slices (nezávislé)

Tento balance vytváří systém který je:
- ✅ **Snadný na údržbu** (změny jsou lokalizované)
- ✅ **Snadný na rozšíření** (přidej slice, neměň existující)
- ✅ **Snadný na testování** (slice je izolovaná jednotka)

---

## 🚫 YAGNI - You Aren't Gonna Need It

> "Always implement things when you actually need them, never when you just foresee that you need them" - Ron Jeffries (XP co-founder)

**YAGNI** je princip z Extreme Programming který říká: **Nepřidávej funkcionalitu dokud ji skutečně nepotřebuješ.**

### 🎯 Co je YAGNI?

YAGNI znamená aktivně **ODMÍTAT** implementaci features které:
- "Možná budeme potřebovat"
- "To se může hodit"
- "Pro případ že..."

**Důvod:**
1. **Většinou se mýlíš** - 70% "budoucích" features nikdy nepotřebuješ
2. **Lepší pochopení později** - až ji budeš potřebovat, budeš víc vědět jak ji udělat správně
3. **Šetří čas** - neimplementuješ zbytečné věci
4. **Jednodušší systém** - méně kódu = méně bugů

### ⚠️ V kontextu VSA

**❌ ŠPATNĚ (porušení YAGNI):**
```python
# "Možná budeme potřebovat XML export, tak to rovnou přidám"
class InvoiceHandler:
    def handle(self, invoice):
        result = self._process(invoice)

        # JSON export (používáme)
        self._export_json(result)

        # XML export (NIKDO NEPOŽADOVAL!)
        self._export_xml(result)  # YAGNI violation!

        # CSV export (NIKDO NEPOŽADOVAL!)
        self._export_csv(result)  # YAGNI violation!
```

**✅ SPRÁVNĚ (YAGNI compliant):**
```python
# Implementuj JEN co je požadováno
class InvoiceHandler:
    def handle(self, invoice):
        result = self._process(invoice)
        self._export_json(result)  # Jen JSON, protože TO potřebujeme
        return result

# Až bude potřeba XML → přidej nový slice nebo rozšiř existující
```

**❌ ŠPATNĚ (spekulativní slices):**
```
features/
├── invoice_processing/      # ✅ Potřebujeme
├── payment_processing/      # ✅ Potřebujeme
├── blockchain_integration/  # ❌ "Možná budeme potřebovat" - YAGNI!
├── ai_prediction/           # ❌ "To se může hodit" - YAGNI!
└── quantum_optimizer/       # ❌ Seriously? - YAGNI!
```

**✅ SPRÁVNĚ:**
```
features/
├── invoice_processing/   # ✅ Reálný business požadavek
└── payment_processing/   # ✅ Reálný business požadavek

# Ostatní features přidáš AŽ když budou skutečně potřeba
```

### 🔄 YAGNI + Rule of Three

YAGNI perfektně doplňuje Rule of Three:

```
1. První požadavek → Implementuj přímo do feature (YAGNI)
2. Druhý požadavek → Zkopíruj (YAGNI - ještě neabstrahuj)
3. Třetí požadavek → TEĎ abstrahi (už víš pattern)

❌ ŠPATNĚ: Po první implementaci vytvoř abstrakci "pro budoucnost"
```

### 📋 YAGNI Checklist

Před přidáním feature/abstrakce se zeptej:

- ❓ **Je to REÁLNÝ business požadavek?** (ne "možná budeme")
- ❓ **Potřebujeme to TEĎ?** (ne "v budoucnu")
- ❓ **Existuje konkrétní use case?** (ne "mohlo by se hodit")
- ❓ **Platí někdo za tuto funkcionalitu?** (prioritizace)

Pokud je odpověď "NE" → **YAGNI = neimplementuj!**

### ⚖️ Výjimky z YAGNI

YAGNI **NEPLATÍ** pro:

1. **Infrastructure Decisions**
   ```python
   # ✅ OK implementovat od začátku (i když zatím nepotřebuješ)
   - Logging framework
   - Database connection pooling
   - Security (authentication, authorization)
   - Error handling infrastructure
   ```

2. **Industry Standards**
   ```python
   # ✅ OK implementovat od začátku
   - GDPR compliance
   - Accessibility (WCAG)
   - Security standards (OWASP)
   ```

3. **Internal Quality**
   ```python
   # ✅ OK implementovat od začátku
   - Unit tests
   - Code documentation
   - Type hints (Python)
   ```

**Proč výjimky?** Tyto věci jsou **drahé přidat později**, ale **levné přidat hned**.

### 🎯 YAGNI v Praxi

**Real-world příklad:**

```
Product Manager: "Přidejme export do PDF, XML, CSV, JSON, YAML a Excel"

❌ ŠPATNĚ: Implementuješ všech 6 formátů

✅ SPRÁVNĚ (YAGNI):
Developer: "Které formáty SKUTEČNĚ potřebují uživatelé TEĎ?"
PM: "Vlastně... jen PDF a JSON"
Developer: "OK, implementuji PDF a JSON. Ostatní přidáme až budou potřeba."

Výsledek:
- 4 formáty NIKDY nebyly potřeba
- Ušetřeno 2 týdny práce
- Jednodušší kód
```

### 🧠 YAGNI Mindset

**Změň myšlení z:**
- ❌ "Co všechno MŮŽE uživatel chtít?"

**Na:**
- ✅ "Co uživatel SKUTEČNĚ potřebuje TEĎ?"

**Pamatuj:**
> "You aren't gonna need it" neznamená "nikdy to nebudeme potřebovat"

Znamená to: **"Neimplementuj to dokud není jasné že to potřebuješ"**

### 🎓 Závěr

YAGNI v VSA kontextu znamená:
- ✅ Vytváře slices pro **reálné** business požadavky
- ✅ Nepřidávej "možná užitečné" features
- ✅ Počkej na Rule of Three před abstrakcí
- ✅ Jednodušší systém = méně bugů

> "The best code is no code at all" - Jeff Atwood

Každý řádek kódu je **liability** (závazek), ne asset.

YAGNI zajišťuje že píšeš jen kód který **skutečně přináší value**.

---

## 📁 CONFIGURATION STRUCTURE - settings.py vs config.py

### Dvouúrovňová struktura konfigurace

**Principy:**
1. **Centrální infrastruktura** → `config/settings.py`
2. **Feature-specific konstanty** → `features/{feature}/config.py`
3. **Smazání feature = smazání jeho config** (žádné osiřelé soubory!)

### Struktura

```
project_root/
├── config/
│   └── settings.py           # ✅ SDÍLENÁ infrastruktura
│
└── features/
    ├── feature_a/
    │   ├── handler.py
    │   └── config.py         # ✅ Feature-specific konstanty
    │
    └── feature_b/
        ├── handler.py
        └── config.py         # ✅ Feature-specific konstanty
```

### ✅ DO config/settings.py PATŘÍ:

**Sdílená infrastruktura** (paths, credentials, feature flags):

```python
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    """Centrální konfigurace sdílené infrastruktury."""

    # Cesty k souborovému systému
    input_folder: str = "./data/input"
    output_folder: str = "./data/output"
    temp_folder: str = "./tmp"

    # Databáze
    db_path: str = "./data/app.db"
    db_pool_size: int = 5

    # API credentials
    external_api_key: str = ""
    external_api_url: str = "https://api.example.com"
    api_timeout: int = 30

    # Email/SMTP
    smtp_server: str = "smtp.example.com"
    smtp_port: int = 587
    smtp_username: str = ""
    smtp_password: str = ""
    notification_email: str = "admin@example.com"

    # Monitoring
    log_level: str = "INFO"
    enable_performance_tracking: bool = False

    # Feature flags
    feature_a_enabled: bool = True
    feature_b_enabled: bool = True
    feature_c_enabled: bool = False

    class Config:
        env_file = ".env"
        env_prefix = "APP_"

settings = Settings()
```

**Pravidlo:** Pokud se konfigurace týká **více než jednoho feature** nebo **infrastruktury** → patří do `settings.py`

### ✅ DO features/{feature}/config.py PATŘÍ:

**Feature-specific konstanty** (business rules, timeouts, limits):

```python
# features/document_processing/config.py
"""Konfigurace pro document_processing feature."""

from dataclasses import dataclass

@dataclass(frozen=True)
class DocumentProcessingConfig:
    """Konstanty pro zpracování dokumentů."""

    # Business rules
    MAX_FILE_SIZE_MB: int = 50
    SUPPORTED_FORMATS: tuple[str, ...] = ('.pdf', '.docx', '.txt')
    MIN_CONFIDENCE_SCORE: float = 0.85

    # Processing timeouts
    EXTRACTION_TIMEOUT_SECONDS: int = 30
    VALIDATION_TIMEOUT_SECONDS: int = 10

    # Retry logic
    MAX_RETRY_ATTEMPTS: int = 3
    RETRY_DELAY_SECONDS: int = 5

    # Feature-specific paths (relative to settings.output_folder)
    OUTPUT_SUBFOLDER: str = "processed_documents"
    ERROR_SUBFOLDER: str = "failed_documents"

CONFIG = DocumentProcessingConfig()
```

**Pravidlo:** Pokud se konfigurace týká **pouze tohoto feature** → patří do `features/{feature}/config.py`

### 🎯 JAK ROZHODNOUT: settings.py vs config.py?

**Zeptej se: "Co se stane, když tento feature smažu?"**

| Konfigurace | Příklad | Umístění |
|-------------|---------|----------|
| **Používá se jinde?** | `db_path`, `smtp_server` | `config/settings.py` |
| **Jen pro tento feature?** | `MAX_FILE_SIZE_MB` | `features/{feature}/config.py` |
| **Credentials/paths?** | API keys, folder paths | `config/settings.py` |
| **Business rules?** | Validation limits, formats | `features/{feature}/config.py` |
| **Feature flag?** | `feature_x_enabled` | `config/settings.py` |
| **Timeouts/limity?** | Feature-specific timeout | `features/{feature}/config.py` |

### 💡 Proč toto rozdělení?

#### Výhody pro VSA:
1. **Smazání feature = smazání config** - žádné osiřelé konfigurační soubory
2. **Izolace** - změna feature neovlivní ostatní
3. **Přehlednost** - jasné oddělení infrastruktury od business logiky
4. **Testovatelnost** - snadno mockuješ feature-specific konstanty

#### Python best practices:
- **`settings.py`** je standardní název pro centrální konfiguraci (Django, FastAPI, Pydantic)
- **`config.py`** v feature má namespace (`features.feature_a.config`) → není potřeba suffix

### 📖 Příklad použití

```python
# features/document_processing/handler.py
from config import settings  # Centrální infrastruktura
from .config import CONFIG   # Feature-specific konstanty

class DocumentProcessingHandler:
    def __init__(self):
        # Infrastruktura z settings
        self.input_folder = settings.input_folder
        self.output_folder = settings.output_folder

        # Feature-specific z local config
        self.max_file_size = CONFIG.MAX_FILE_SIZE_MB
        self.supported_formats = CONFIG.SUPPORTED_FORMATS

    def validate_file(self, file_path: str) -> bool:
        # Používá feature-specific konstanty
        if file_size_mb > CONFIG.MAX_FILE_SIZE_MB:
            raise ValueError(f"File too large: {file_size_mb}MB > {CONFIG.MAX_FILE_SIZE_MB}MB")

        if not file_ext in CONFIG.SUPPORTED_FORMATS:
            raise ValueError(f"Unsupported format: {file_ext}")

        return True
```

### ⚠️ Časté chyby

❌ **ŠPATNĚ:** Business rules v `settings.py`
```python
# config/settings.py
class Settings(BaseSettings):
    feature_a_max_size: int = 50     # ❌ Patří do feature!
    feature_b_timeout: int = 10      # ❌ Patří do feature!
```

✅ **SPRÁVNĚ:** Business rules v feature config
```python
# features/feature_a/config.py
@dataclass(frozen=True)
class FeatureAConfig:
    MAX_SIZE_MB: int = 50  # ✅ Zde patří

# features/feature_b/config.py
@dataclass(frozen=True)
class FeatureBConfig:
    TIMEOUT_SECONDS: int = 10  # ✅ Zde patří
```

❌ **ŠPATNĚ:** Centralizované feature configs mimo slices
```python
config/
├── settings.py
├── feature_a_config.py      # ❌ Config oddělen od feature!
└── feature_b_config.py      # ❌ Při smazání feature zůstane!
```

✅ **SPRÁVNĚ:** Config uvnitř feature slice
```python
features/
├── feature_a/
│   ├── handler.py
│   └── config.py           # ✅ Config součástí slice
└── feature_b/
    ├── handler.py
    └── config.py           # ✅ Smaž feature → smaž i config
```

🏗️ STRUKTURA JEDNOHO FEATURE SLICE

**Minimální struktura:**
```
features/{business_feature}/
├── __init__.py           # Public API tohoto slice
├── handler.py            # Hlavní vstupní bod (business interface)
├── config.py             # Feature-specific konfigurace
└── README.md             # Co tento slice dělá
```

**Rozšířená struktura (komplexnější feature):**
```
features/{business_feature}/
├── __init__.py
├── handler.py            # Orchestrace celého procesu
├── config.py
│
├── {subdomain_a}/        # Sub-doména: část A business logiky
│   ├── processor_a.py
│   ├── processor_b.py
│   └── base_processor.py
│
├── {subdomain_b}/        # Sub-doména: část B business logiky
│   ├── parser_a.py
│   ├── parser_b.py
│   └── validator.py
│
├── {subdomain_c}/        # Sub-doména: konverze/transformace
│   ├── converter.py
│   └── mapper.py
│
└── {subdomain_d}/        # Sub-doména: obohacení/integrace
    ├── external_client.py
    └── enricher.py
```

Každý slice musí mít:
**Handler (handler.py)** - implementuje business interface:
```python
# VZOR - Obecný handler pattern
class {YourFeature}Handler({IBusinessInterface}):
    def can_handle(self, entity: {Entity}) -> bool:
        """Umím zpracovat tuto entitu?"""

    def handle(self, entity: {Entity}) -> {Result}:
        """Zpracuj entitu kompletně"""
```
Jasná zodpovědnost - 1 slice = 1 business funkce
Žádné závislosti na jiných features - jen na core/
README - vysvětli, co slice dělá a kdy se použije
🤔 JAK ROZHODNOUT: NOVÝ SLICE vs. ROZŠÍŘENÍ EXISTUJÍCÍHO?

**Proces rozhodování:**

Zeptej se: "Je to JINÁ business funkce nebo VARIANTA stávající?"

**✅ NOVÝ SLICE, když:**
- **Jiný vstup**: "Zpracuj data z API" vs. "Zpracuj data z DB"
- **Jiný proces**: "Extrahuj metodou A" vs. "Extrahuj metodou B"
- **Jiné pravidla**: "Validuj pro typ X" vs. "Validuj pro typ Y"
- **Jiná technologie**: "Technologie A" vs. "Technologie B"
- **Dá se vypnout samostatně**: "Můžeme vypnout feature A, aniž to ovlivní feature B?"

**✅ ROZŠÍŘENÍ STÁVAJÍCÍHO, když:**
- **Stejný proces, jiná implementace**: Library A vs. Library B pro stejný účel
- **Stejná business funkce, nový parametr**: "Podpor nový formát (stále stejná funkce)"
- **Optimalizace**: "Rychlejší algoritmus pro stejnou funkci"
- **Bug fix**: "Oprav parsování edge case"
**Praktické příklady:**

**Příklad 1: Přidání nové metody zpracování**
```
Otázka: Nová technologie pro zpracování - nový slice?
Odpověď: ✅ ANO - nový slice features/{new_method}/

Proč?
- Jiná technologie (Method A vs. Method B vs. Method C)
- Jiný proces (různé kroky zpracování)
- Dá se vypnout samostatně
- Má vlastní konfiguraci (parametry, timeouty, limity)
```

**Příklad 2: Podpora nového formátu**
```
Otázka: Přidání podpory formátu 2.0 - nový slice?
Odpověď: ❌ NE - rozšíření features/{existing_feature}/parsers/

Proč?
- Stejná business funkce (stále stejná feature)
- Stejný proces (detekce + parsování)
- Jen nový parser: format_v2_parser.py
- Nelze vypnout samostatně (součást funkce)
```

**Příklad 3: Více implementací stejné funkce**
```
Otázka: Podpora Provider A + Provider B + Provider C - tři slices?
Odpověď: ❌ NE - jeden slice features/{business_function}/

Proč?
- Stejná business funkce
- Stejný proces (input → API → output)
- Jen jiné implementace klienta

Struktura:
features/{business_function}/
├── handler.py
├── providers/
│   ├── provider_a.py
│   ├── provider_b.py
│   └── provider_c.py
```
💡 MYŠLENÍ V BUSINESS LOGICE

**❌ Špatné (technické) myšlení:**
```
"Potřebuji zpracovat [technical thing]"
→ Vytvořím {Technical}Processor třídu
→ Přidám metody: process_a(), process_b(), process_c()
→ Všechny features to budou používat
```
**Problém:** Technické řešení bez business kontextu.

**✅ Správné (business) myšlení:**
```
"Co chci dosáhnout?" (Business cíl)
→ "Získat [business result] z [business input]"

"Jakými způsoby to můžu udělat?" (Strategie)
→ 1. Metoda A (nejrychlejší, nejpřesnější)
→ 2. Metoda B (rychlé, spolehlivé)
→ 3. Metoda C (pomalé, univerzální fallback)

"Jak to organizovat?" (Architektura)
→ 3 nezávislé slices s prioritou
→ Orchestration layer je prožene v pořadí
```
**Framework pro business myšlení:**

Vždy odpověz na tyto otázky:

1. **Co je business cíl?** (ne "zpracovat X", ale "dosáhnout Y")
2. **Kdo to používá?** (uživatel, systém, jiný proces?)
3. **Kdy se to spustí?** (event, schedule, API call?)
4. **Jaké jsou vstupy?** (soubor, data z DB, API payload?)
5. **Jaké jsou výstupy?** (soubor, notifikace, záznam v DB?)
6. **Jaké jsou varianty?** (priority, fallbacky, alternativy?)

**VZOR - Obecný příklad aplikace VSA:**
```
Business cíl: Automaticky zpracovat [entity] do [desired_format]

Uživatel: [System/User] poskytuje [input]
Trigger: [Event] (např. new file, API call, schedule)
Vstupy: [Input type] + volitelně [metadata]

Výstupy:
- [Primary output] (vždy)
- [Secondary output] (volitelně)
- [Notification] (při dokončení/chybě)

Varianty zpracování (priority):
1. Metoda A existuje → použij (nejrychlejší)
2. Metoda B dostupná → použij (rychlé, spolehlivé)
3. Metoda C možná → použij (střední rychlost)
4. Fallback metoda → použij (pomalé, univerzální)

VSA řešení:
features/
├── {method_a_feature}/     # Priorita 1
├── {method_b_feature}/     # Priorita 2
├── {method_c_feature}/     # Priorita 3
└── {fallback_feature}/     # Priorita 4 (fallback)

orchestration/
└── {business}_pipeline.py  # Orchestruje podle priority
```
🔧 JAK SPRÁVNĚ PŘIDÁVAT FEATURES
Proces přidání nové feature
Krok 1: Business analýza
Odpověz na otázky:
Co tato feature DĚLÁ? (business popis)
Kdy se SPUSTÍ? (trigger, podmínka)
Co VRACÍ? (výstup, side effects)
Dá se VYPNOUT? (feature toggle)
Krok 2: Závislosti
Identifikuj:
Závisí na jiné feature? → Pokud ano, možná to není samostatná feature
Sdílí logiku s jinou feature? → Pokud > 80%, je to rozšíření, ne nová feature
Používá jen core/? → Správně! Features nesmí záviset na sobě navzájem
Krok 3: Vytvoření struktury
mkdir -p features/nova_feature
cd features/nova_feature

# Minimální soubory
touch __init__.py
touch handler.py
touch config.py
touch README.md
Krok 4: Implementace handleru
# features/nova_feature/handler.py
from core.interfaces import IDocumentHandler
from core.domain import Document, ProcessingResult

class NovaFeatureHandler(IDocumentHandler):
    """
    Business popis: Co tato feature dělá?
    Trigger: Kdy se spustí?
    Výstup: Co vrací?
    """
    
    def can_handle(self, document: Document) -> bool:
        """
        Rozhodovací logika: Umím zpracovat tento dokument?
        
        Returns:
            True pokud tato feature dokáže zpracovat dokument
        """
        # TODO: Implementuj podmínku
        pass
    
    def handle(self, document: Document) -> ProcessingResult:
        """
        Hlavní business logika - kompletní zpracování.
        
        Args:
            document: Dokument k zpracování
            
        Returns:
            ProcessingResult s výsledkem
        """
        # TODO: Implementuj zpracování
        pass
Krok 5: Registrace v pipeline
# pipeline/processing_pipeline.py
from features.nova_feature.handler import NovaFeatureHandler

class ProcessingPipeline:
    def __init__(self):
        self.handlers = [
            ExistingHandler1(),
            NovaFeatureHandler(),  # Přidej podle priority!
            ExistingHandler2(),
        ]
Krok 6: Feature flag
# config/feature_flags.py
FEATURES = {
    "existing_feature": True,
    "nova_feature": True,  # Lze vypnout bez dopadu na ostatní
}
Pravidla přidávání
✅ SPRÁVNĚ:
Izolovaná implementace - vše v jedné složce
Žádné cross-feature importy - jen core/
README.md - vysvětli business funkci
Feature flag - lze vypnout
Testy izolované - testuj jen tento slice
❌ ŠPATNĚ:
# ❌ Import z jiné feature
from features.other_feature.parser import parse_data

# ❌ Sdílení stavu mezi features
from features.other_feature.cache import shared_cache

# ❌ Technické názvy
class PDFProcessor:  # Co to DĚLÁ?

# ❌ God class
class UniversalDocumentProcessor:  # Dělá všechno = porušení SRP
🎨 CORE INFRASTRUCTURE - CO TAM PATŘÍ?
Pravidlo: "Shared Kernel is Sacred"
Core obsahuje MINIMUM - jen to, co opravdu MUSÍ být sdílené.
✅ DO CORE patří:
1. Domain Entities
# core/domain/document.py
@dataclass
class Document:
    """Základní reprezentace dokumentu - business entity."""
    pdf_path: str
    timestamp: datetime
    document_type: DocumentType
    metadata: Dict[str, Any]
Proč? Všechny features pracují s dokumentem - společná řeč.
2. Interfaces (Abstraktní kontrakty)
# core/interfaces/i_handler.py
from abc import ABC, abstractmethod

class IDocumentHandler(ABC):
    """Kontrakt pro všechny processing handlery."""
    
    @abstractmethod
    def can_handle(self, document: Document) -> bool:
        """Umí tento handler zpracovat dokument?"""
        pass
    
    @abstractmethod
    def handle(self, document: Document) -> ProcessingResult:
        """Zpracuj dokument."""
        pass
Proč? Pipeline potřebuje jednotný interface - polymorfismus.
3. Infrastructure (technické záležitosti)
# core/infrastructure/database.py
class Database:
    """SQLite database connection wrapper."""
    
# core/infrastructure/file_system.py
class FileSystem:
    """Low-level file operations."""
    
# core/infrastructure/email_sender.py
class EmailSender:
    """SMTP client pro notifikace."""
Proč? Technická infrastruktura není business logika - sdílená utility.
❌ DO CORE NEPATŘÍ:
Business logika → patří do features
Parsování specific formátů → patří do features
Validace business pravidel → patří do features
Konverze mezi formáty → patří do features (nebo je duplicitní)
**Příklad rozhodování: "Kam s External API klientem?"**

```
Otázka: External API client - core/ nebo features/?

Analýza:
- Používají ho 3+ features
- Je to technická infrastruktura (HTTP client)
- Není to business logika

Odpověď: ✅ core/infrastructure/{external_api}_client.py

ALE: Každá feature má vlastní enricher.py - business logika jak API data použít!

core/infrastructure/
└── {external_api}_client.py    # Technické: HTTP volání, retry, timeout

features/{feature_a}/
└── {business}_enricher.py      # Business: Jak obohacím data z API pro feature A

features/{feature_b}/
└── {business}_enricher.py      # Business: Jak obohacím data z API pro feature B
```

**Proč duplicita?** Business logika pro feature A může být jiná než pro feature B - není to duplicita, je to jiný use case!

---

## ⚡ FAIL FAST

> "Reject bad inputs early before any damage is done"

**Fail Fast** je princip který říká: **Pokud něco nejde, selž OKAMŽITĚ, hlasitě a viditelně.**

Opak "fail silently" - kde chyby jsou skryté a problém se objeví až později (když je drahé to opravit).

### 🎯 Co je Fail Fast?

**Fail Fast znamená:**
1. **Validuj na začátku** - před jakoukoli business logikou
2. **Early returns** - ukonči zpracování při první chybě
3. **Explicit výjimky** - ne None/null returns
4. **Fail loudly** - loguj co se stalo

**Proč?**
- ⚡ **Rychlejší debugging** - chyba je lokalizovaná na zdroj
- 💰 **Levnější oprava** - zachytíš problém brzy
- 🛡️ **Prevence korupce** - zastavíš zpracování před poškozením dat
- 📍 **Jasný error** - víš přesně co selhalo

### 🏗️ Fail Fast v VSA Handleru

**VSA Handler má 2 Fail Fast pointy:**

1. **`can_handle()` - Quick rejection**
2. **`handle()` - Input validation**

**Příklad:**
```python
class PaymentHandler(IHandler):
    def can_handle(self, payment: Payment) -> bool:
        """FAIL FAST Point #1 - Quick rejection"""

        # Fail fast - feature vypnuta
        if not self.enabled:
            return False  # Ukonči RYCHLE

        # Fail fast - základní validace
        if not payment or not payment.amount:
            return False  # Nedojde k handle()

        # Fail fast - business podmínka
        if payment.amount <= 0:
            return False

        # Teprve pak složitější checks
        return self._complex_validation(payment)

    def handle(self, payment: Payment) -> Result:
        """FAIL FAST Point #2 - Input validation"""

        # Fail fast - explicit validation na začátku
        if not payment.account_number:
            raise ValueError("Missing account_number")  # Fail LOUDLY!

        if not self._is_valid_iban(payment.account_number):
            raise ValueError(f"Invalid IBAN: {payment.account_number}")

        # Early return pro chybové stavy
        if payment.amount > self.MAX_AMOUNT:
            return Result(
                success=False,
                error=f"Amount {payment.amount} exceeds limit {self.MAX_AMOUNT}"
            )

        # Fail fast - external dependency check
        if not self.payment_gateway.is_available():
            raise ServiceUnavailableError("Payment gateway offline")

        # ✅ Teprve TEĎ business logika
        # Víme že všechny vstupy jsou validní
        return self._process_payment(payment)
```

### ❌ ŠPATNĚ - Fail Silently

```python
# ❌ ANTI-PATTERN - fail silently
class BadHandler:
    def handle(self, payment: Payment) -> Result:
        # Žádná validace - zpracováváme cokoliv

        try:
            # Zpracování může selhat kdekoli
            account = payment.account_number  # Může být None!
            amount = payment.amount  # Může být 0 nebo záporné!

            # Provádíme operace na špatných datech
            result = self.gateway.process(account, amount)

            # Swallow exception - chyba zmizí!
            return Result(success=True)  # Lžeme že to funguje
        except Exception:
            return None  # Vraťíme None - kdo ví že to selhalo?
```

**Problémy:**
- 🐛 Bug se objeví až později (v DB, nebo u uživatele)
- 🔍 Těžké debugování - nevíš KDE to selhalo
- 💣 Možná data corruption - operace na polovinu proběhly

### ✅ SPRÁVNĚ - Fail Fast

```python
# ✅ FAIL FAST pattern
class GoodHandler:
    def handle(self, payment: Payment) -> Result:
        # Validace HNED na začátku
        self._validate_payment(payment)  # Raise exception pokud invalid

        # Všechny další operace víme že pracují s validními daty
        result = self._process_payment(payment)
        return result

    def _validate_payment(self, payment: Payment):
        """Centralizovaná validace - fail fast"""
        if not payment:
            raise ValueError("Payment is None")

        if not payment.account_number:
            raise ValueError("Missing account_number")

        if payment.amount <= 0:
            raise ValueError(f"Invalid amount: {payment.amount}")

        # Všechny checks prošly - víme že payment je OK
```

### 🏭 Fail Fast na Application Startup

**Fail fast při inicializaci:**
```python
# app.py - fail fast při startu
def main():
    """Application entry point - fail fast na missing config"""

    # Fail fast - load all config at once
    try:
        settings = Settings()  # Pydantic validates ALL fields
    except ValidationError as e:
        logger.error(f"Invalid configuration: {e}")
        sys.exit(1)  # Fail fast - nespouštěj app s bad config!

    # Fail fast - check required dependencies
    if not Path(settings.db_path).parent.exists():
        logger.error(f"Database directory missing: {settings.db_path}")
        sys.exit(1)

    # Fail fast - test DB connection
    try:
        db = Database(settings.db_path)
        db.test_connection()
    except DatabaseError as e:
        logger.error(f"Cannot connect to database: {e}")
        sys.exit(1)  # Fail fast - nespouštěj app bez DB!

    # ✅ Všechny checks prošly - app může běžet
    logger.info("Application started successfully")
    run_application(settings, db)
```

### 🎯 Fail Fast Best Practices

**1. Validuj vstupy na začátku funkce:**
```python
def process_invoice(invoice_data: dict) -> Invoice:
    # ✅ Fail fast - validuj HNED
    if not invoice_data:
        raise ValueError("invoice_data is empty")

    required_fields = ['number', 'date', 'amount']
    for field in required_fields:
        if field not in invoice_data:
            raise ValueError(f"Missing required field: {field}")

    # Teprve pak zpracování
    return Invoice(**invoice_data)
```

**2. Use early returns:**
```python
def can_process(document: Document) -> bool:
    # ✅ Early return - fail fast
    if not document:
        return False

    if not document.is_valid():
        return False

    if document.is_processed:
        return False  # Už je zpracovaný

    # Došli jsme sem = document je OK
    return True
```

**3. Explicit exceptions, ne None returns:**
```python
# ❌ ŠPATNĚ
def get_user(user_id: int) -> Optional[User]:
    if not user_id:
        return None  # Silent failure
    # ...

# ✅ SPRÁVNĚ
def get_user(user_id: int) -> User:
    if not user_id:
        raise ValueError("user_id is required")  # Fail fast!
    # ...
```

**4. Fail fast v tests:**
```python
def test_payment_handler():
    handler = PaymentHandler()

    # ✅ Test fail fast behavior
    with pytest.raises(ValueError, match="Missing account_number"):
        handler.handle(Payment(account_number=None))

    # Validates že handler fails fast na bad input
```

### 📊 Fail Fast vs Fail Safe

| Aspect | Fail Fast | Fail Safe |
|--------|-----------|-----------|
| **Kdy použít** | Development, input validation | Production, user-facing |
| **Chování** | Crash loudly | Graceful degradation |
| **Příklad** | `raise ValueError(...)` | `return Result(success=False)` |
| **Debugging** | Snadné (stack trace) | Těžší (musíš logovat) |

**V VSA kombinuješ OBA:**
- **can_handle()** → Fail safe (return False)
- **handle()** → Fail fast (raise exception) pokud input validation selže

### 🎓 Závěr

Fail Fast v VSA znamená:
- ✅ **Validuj v `can_handle()`** - quick rejection
- ✅ **Validuj v `handle()`** - input validation na začátku
- ✅ **Raise exceptions** pro invalid input (ne None returns)
- ✅ **Early returns** pro chybové stavy
- ✅ **Fail at startup** pokud config/dependencies chybí

> "Fail fast, fail loudly, fail early" - odhalíš problém než způsobí škodu

Fail Fast **šetří čas** tím že lokalizuje chyby tam kde vznikly, ne až tam kde se projevily.

---

## 🔄 DUPLICITA VS. ABSTRAKCE

### 🎯 DRY Principle - Don't Repeat Yourself

> "Every piece of knowledge must have a single, unambiguous, authoritative representation within a system"

**DRY** je základní princip software engineeringu který říká: **Neopakuj znalosti/logiku.**

**ALE:** VSA má **speciální vztah k DRY** - aplikuje ho selektivně.

---

### ⚖️ DRY v VSA: Kdy ANO, kdy NE?

**✅ DRY pro Technical Infrastructure (core/):**
```python
# ✅ SPRÁVNĚ - DRY pro technickou infrastrukturu
core/infrastructure/
└── database.py          # Jeden DB connector pro všechny

features/feature_a/      # Používá shared connector
features/feature_b/      # Používá shared connector
```

**❌ WET pro Business Logic (features/):**
```python
# ✅ SPRÁVNĚ - WET (Write Everything Twice) pro business logiku
features/feature_a/
└── validator.py         # Feature A validace

features/feature_b/
└── validator.py         # Feature B validace (může vypadat stejně!)
```

---

### 🔍 Incidental vs Conceptual Duplication

**Klíčové rozlišení z research:**

#### **Incidental Duplication** (OK!)
Kód vypadá stejně **NÁHODOU**, ale reprezentuje **různé koncepty**.

```python
# features/payment/validator.py
def validate_amount(amount: float) -> bool:
    return amount > 0 and amount < 1000000

# features/invoice/validator.py
def validate_amount(amount: float) -> bool:
    return amount > 0 and amount < 1000000

# Vypadá STEJNĚ, ale:
# - Payment má limit kvůli fraud detection
# - Invoice má limit kvůli business rules
# → RŮZNÉ důvody, RŮZNÉ koncepty → nech duplicitní!
```

**Za rok:**
```python
# Payment zvýší limit (nová fraud pravidla)
def validate_amount(amount: float) -> bool:
    return amount > 0 and amount < 5000000

# Invoice zůstane stejný (business omezení)
def validate_amount(amount: float) -> bool:
    return amount > 0 and amount < 1000000

# Kdyby byly shared → změna payment zlomí invoice!
```

#### **Conceptual Duplication** (BAD!)
Kód reprezentuje **STEJNÝ koncept** ve více místech.

```python
# ❌ ŠPATNĚ - conceptual duplication
# features/feature_a/database.py
class DatabaseConnection:
    def connect(self): ...

# features/feature_b/database.py
class DatabaseConnection:
    def connect(self): ...

# Reprezentuje STEJNÝ koncept (DB připojení)
# → Přesuň do core/infrastructure/database.py
```

---

### 🚫 AHA Principle - Avoid Hasty Abstractions

> "Prefer duplication over the wrong abstraction" - Sandi Metz

**AHA** = **Avoid Hasty Abstractions**

**Problém předčasné abstrakce:**
```python
# ❌ ŠPATNĚ - premature abstraction po 1. implementaci
# Po první feature řekneš: "To můžeme zobecnit!"

class GenericDataProcessor:  # Premature!
    def process(self, data, format, validation_rules, output_type):
        # 20 parametrů, 50 if/else větví
        # Trying to handle VŠECHNY možné případy
        pass

# Za měsíc: Nikdo nechápe jak to používat
# Za rok: Strach to měnit (zlomí všechno)
```

**✅ AHA approach - čekej na pattern:**
```python
# 1. Implementace - přímo v feature
features/feature_a/processor.py

# 2. Implementace - zkopíruj (duplicita OK!)
features/feature_b/processor.py

# 3. Implementace - TEĎ abstrahi (vidíš pattern!)
core/processors/base_processor.py
```

---

### 🎯 VSA Přístup: "Duplication is far cheaper than wrong abstraction"

**Klíčová citace Sandi Metz:**

```
Prefer duplication over the wrong abstraction.

Duplication is far cheaper than the wrong abstraction.

The wrong abstraction is harder to remove than duplication.
```

**V VSA kontextu:**

**✅ Kdy POVOLIT duplicitu:**

1. **Business kontext je jiný**
```python
# features/method_a/data_generator.py
def generate_output_from_method_a(data_a): ...

# features/method_b/data_generator.py
def generate_output_from_method_b(data_b): ...
```
**Proč?** Method A → Output je jiný business proces než Method B → Output.

2. **Pravděpodobnost divergence**
```python
# Dnes: Stejné
# Za měsíc: Method A potřebuje extra validaci
# Za rok: Method B potřebuje confidence scoring
```
**Proč?** Features evolvují nezávisle - shared abstrakce by je spojila.

3. **Izolace features**
- Můžeš smazat celou feature bez dopadu
- Můžeš změnit feature bez ovlivnění jiných

---

### ❌ Kdy duplicita JE PROBLÉM:

1. **Technická infrastruktura**
```python
# ❌ Každá feature má vlastní DB connector
features/feature_a/database.py
features/feature_b/database.py

# ✅ Shared v core
core/infrastructure/database.py
```

2. **Bug ve více verzích**
```
Objevíš security bug v parsování XML
→ Musíš opravit ve 3 features
→ Řešení: Pokud kritické + opravdu stejné → přesuň do core
```

3. **After Rule of Three**
```
3 features mají >80% stejný kód
→ TEĎ je čas abstrahi do core/
```

---

### 🔧 Framework pro rozhodování

```python
def should_deduplicate(code_a, code_b):
    """Rozhodovací strom pro deduplication."""

    # 1. Je to technická infrastruktura?
    if is_technical_infrastructure(code_a, code_b):
        return True  # → core/infrastructure/ (DRY!)

    # 2. Je to stejný business kontext?
    if has_same_business_context(code_a, code_b):
        # 3. Budou evolvovat společně?
        if will_evolve_together(code_a, code_b):
            return True  # → možná shared (po Rule of Three)
        else:
            return False  # → nech duplicitní (AHA!)

    # Default: nech duplicitní
    return False  # → incidental duplication
```

---

### 📋 DRY vs WET Decision Matrix

| Typ kódu | DRY nebo WET? | Umístění | Důvod |
|----------|---------------|----------|-------|
| **DB connector** | DRY ✅ | `core/infrastructure/` | Technická infrastruktura |
| **HTTP client** | DRY ✅ | `core/infrastructure/` | Technická infrastruktura |
| **Business validation** | WET ✅ | `features/{x}/` | Incidental duplication |
| **Data transformation** | WET ✅ | `features/{x}/` | Business context differs |
| **Domain entities** | DRY ✅ | `core/domain/` | Shared knowledge |
| **Feature logic** | WET ✅ | `features/{x}/` | Feature isolation |

---

### 🎓 Závěr: DRY v VSA

**3 pravidla pro VSA:**

1. **DRY pro infrastructure** (core/) - technical concerns
2. **WET pro business logic** (features/) - business concerns
3. **AHA pro abstrakce** - čekej na Rule of Three

> "Don't abstract until you feel the pain of duplication three times"

**Pamatuj:**
- Duplicita je **levná** (Ctrl+C, Ctrl+V)
- Špatná abstrakce je **drahá** (coupling, rigidita, složitost)
- Features musí být **izolované** > než DRY

---

📝 PRAKTICKÉ ŠABLONY
# features/method_a/data_generator.py
def generate_output_from_method_a(data_a): ...

# features/method_b/data_generator.py
def generate_output_from_method_b(data_b): ...
Proč? Method A → Output je jiný business proces než Method B → Output.
Pravděpodobnost divergence
# Dnes: Stejné
# Za měsíc: Method A potřebuje extra validaci
# Za rok: Method B potřebuje confidence scoring
Proč? Features evolvují nezávisle - shared abstrakce by je spojila.
Izolace features
Můžeš smazat celou feature bez dopadu
Můžeš změnit feature bez ovlivnění jiných
❌ Duplicita je PROBLÉM když:
Technická infrastruktura
# ❌ Každá feature má vlastní DB connector
features/feature_a/database.py
features/feature_b/database.py

# ✅ Shared v core
core/infrastructure/database.py
Bug ve více verzích
Objevíš security bug v parsování XML
Musíš opravit ve 3 features
Řešení: Pokud je to kritické + opravdu stejné → přesuň do core
Framework pro rozhodování
def should_deduplicate(code_a, code_b):
    """Rozhodovací strom pro deduplication."""
    
    if is_technical_infrastructure(code_a, code_b):
        return True  # → core/infrastructure/
    
    if has_same_business_context(code_a, code_b):
        if will_evolve_together(code_a, code_b):
            return True  # → možná shared
        else:
            return False  # → nech duplicitní
    
    return False  # → default: nech duplicitní
📝 PRAKTICKÉ ŠABLONY
Šablona: Nová feature
# features/nova_feature/__init__.py
"""
BUSINESS FUNKCE: [Krátký popis co feature dělá]

Trigger: [Kdy se spustí?]
Input: [Co přijímá?]
Output: [Co vrací?]
Dependencies: [Jen core/ - žádné jiné features!]

Example:
    handler = NovaFeatureHandler()
    if handler.can_handle(document):
        result = handler.handle(document)
"""

from .handler import NovaFeatureHandler
from .config import NOVA_FEATURE_CONFIG

__all__ = ['NovaFeatureHandler', 'NOVA_FEATURE_CONFIG']
# features/nova_feature/handler.py
from core.interfaces import IDocumentHandler
from core.domain import Document, ProcessingResult
from .config import NOVA_FEATURE_CONFIG
import logging

logger = logging.getLogger(__name__)

class NovaFeatureHandler(IDocumentHandler):
    """
    Handler pro [business funkci].
    
    Business logika:
    1. [Krok 1]
    2. [Krok 2]
    3. [Krok 3]
    """
    
    def __init__(self):
        self.enabled = NOVA_FEATURE_CONFIG.enabled
        # Inicializuj dependencies zde
    
    def can_handle(self, document: Document) -> bool:
        """
        Rozhodovací logika: Umíme zpracovat tento dokument?
        
        Returns:
            True pokud:
            - Feature je enabled
            - Dokument splňuje podmínky
        """
        if not self.enabled:
            return False
        
        # TODO: Business podmínka
        return False
    
    def handle(self, document: Document) -> ProcessingResult:
        """
        Hlavní business logika.
        
        Process:
        1. Validace vstupu
        2. Business operace
        3. Vytvoření výstupu
        
        Raises:
            ProcessingError: Pokud zpracování selže
        """
        logger.info(f"Processing document: {document.pdf_path}")
        
        try:
            # TODO: Implementuj business logiku
            
            return ProcessingResult(
                success=True,
                method="NOVA_FEATURE",
                metadata={}
            )
        except Exception as e:
            logger.error(f"Processing failed: {e}")
            raise
# features/nova_feature/config.py
from dataclasses import dataclass
from typing import Optional

@dataclass
class NovaFeatureConfig:
    """Konfigurace pro nova_feature."""
    enabled: bool = True
    # Feature-specific nastavení
    timeout_seconds: int = 30
    retry_count: int = 3

# Singleton instance
NOVA_FEATURE_CONFIG = NovaFeatureConfig()
# features/nova_feature/README.md

# Nova Feature

## Business funkce

[Vysvětli CO tato feature dělá z business pohledu]

## Kdy se používá

- Podmínka 1
- Podmínka 2

## Konfigurace

Viz `config.py`:
- `enabled` - feature toggle
- `timeout_seconds` - timeout pro operaci

## Závislosti

- `core/domain` - Document entity
- `core/interfaces` - IDocumentHandler
- Žádné jiné features!

## Příklady použití

```python
handler = NovaFeatureHandler()
if handler.can_handle(document):
    result = handler.handle(document)

---

## 🚀 POSTUP PŘI VÝSTAVBĚ OD NULY

### Fáze 1: Core Foundation (Den 1)

1. **Vytvoř strukturu**
   ```bash
   mkdir -p core/{domain,interfaces,infrastructure}
   mkdir -p features
   mkdir -p pipeline
   mkdir -p config
   mkdir -p tests/{core,features}
Definuj domain entities
# core/domain/document.py
# core/domain/processing_result.py
# core/domain/exceptions.py
Definuj interfaces
# core/interfaces/i_handler.py
# core/interfaces/i_repository.py
Setup infrastructure
# core/infrastructure/database.py (SQLite)
# core/infrastructure/file_system.py
# core/infrastructure/logger.py
Fáze 2: První Feature (Den 2)
Identifikuj nejjednodušší feature (nejrychlejší/nejbezpečnější metoda)
Vytvoř strukturu
Implementuj handler
Testuj izolovaně
Vytvoř základní orchestration layer
Fáze 3: Přidávání Features (Den 3-N)
Pro každou další feature:
Business analýza (co dělá?)
Rozhodnutí (nový slice vs. extension?)
Implementace (izolovaně)
Registrace v pipeline
Feature flag
Testy
Fáze 4: Integration & Orchestration
Pipeline orchestrace - chain of handlers
Error handling - graceful degradation
Monitoring - logging, metrics
Configuration - feature flags, settings
⚠️ ČASTÉ CHYBY A JAK SE JIM VYHNOUT
Chyba 1: "Vše je feature"
❌ Špatně:
features/
├── database_connection/    # TO NENÍ FEATURE!
├── email_sending/          # TO NENÍ FEATURE!
└── file_operations/        # TO NENÍ FEATURE!
✅ Správně: Technická infrastruktura → core/infrastructure/
Chyba 2: "Features na sobě závisí"
❌ Špatně:
# features/feature_a/handler.py
from features.feature_b.parser import parse_data  # CROSS-FEATURE IMPORT!
✅ Správně: Buď duplicita, nebo přesuň do core/ (pokud opravdu shared).
Chyba 3: "God handler"
❌ Špatně:
class UniversalHandler:
    def handle_method_a(self): ...
    def handle_method_b(self): ...
    def handle_method_c(self): ...
    def handle_method_d(self): ...
✅ Správně: 4 samostatné handlery v 4 features.
Chyba 4: "Předčasná abstrakce"
❌ Špatně:
# Máš 2 features a už vytváříš abstrakci
class AbstractDataExtractor(ABC):
    @abstractmethod
    def extract(self): ...
    @abstractmethod
    def validate(self): ...
✅ Správně: Počkej na Rule of Three - až 3 features sdílí logiku, pak abstrahi.
Chyba 5: "Technické názvy"
❌ Špatně:
features/
├── pdf_processor/
├── image_handler/
└── xml_parser/
✅ Správně:
features/
├── data_extraction/          # Business: "Extrahuj data"
├── payment_processing/       # Business: "Zpracuj platbu"
└── data_enrichment/          # Business: "Obohat o external data"
🎯 CHECKLIST: "Jsem na správné cestě?"
Při každém commitu zkontroluj:
✅ Core checklist:
 core/ obsahuje jen domain entities, interfaces, infrastructure
 Žádná business logika v core/
 Infrastructure je skutečně technická (DB, HTTP, File I/O)
✅ Feature checklist:
 Feature má jasný business účel (ne "PDF processor", ale "Invoice extraction")
 Feature je izolovaná (žádné importy z jiných features)
 Feature má README s business popisem
 Feature má vlastní config
 Feature lze vypnout feature flagem
✅ Architecture checklist:
 Žádné složky utils/, helpers/, common/
 Duplicita je OK (pokud jiný business kontext)
 Naming podle business funkcí, ne technologií
 Každá feature implementuje stejný interface
## 🛠️ PRAKTICKÉ DOPLŇKY PRO SOLO DEVELOPERA

### 1. Shared Utilities - Kdy je `core/utils/` OK

**Problém**: Některé funkce prostě MUSÍ být sdílené (sanitize_filename, format_date).

**Řešení**: `core/utils/` je OK pro **pure functions bez business logiky**.

```python
# ✅ core/utils/string_helpers.py - DOBRÝ příklad
def sanitize_filename(name: str) -> str:
    """Pure utility - žádný business kontext."""
    return re.sub(r'[^\w\-_.]', '_', name)

def format_czech_date(date: datetime) -> str:
    """Pure formatting - žádná business logika."""
    return date.strftime('%d.%m.%Y')
```

```python
# ❌ ŠPATNĚ - tohle patří do feature!
def validate_invoice_number(num: str) -> bool:
    """Business logika - patří do features/invoice_validation/"""
    return len(num) == 10 and num.isdigit()
```

**Pravidlo**: Ptej se "Může toto použít JAKÁKOLIV aplikace?". Pokud ano → `core/utils/`.

---

### 2. Dependency Injection - Jednoduše

**Pro solo dev + AI: KISS approach - konstruktor dependency injection.**

```python
# VZOR - Constructor injection (žádné fancy DI containery!)
class YourFeatureHandler(IDocumentHandler):
    def __init__(self, dependency1: Type1, dependency2: Type2):
        """Inject všechny dependencies přes konstruktor."""
        self.dependency1 = dependency1
        self.dependency2 = dependency2

    def handle(self, document: Document):
        # Mockable v testech, čitelné v production
        result = self.dependency1.do_something()
        self.dependency2.save(result)
```

```python
# VZOR - Setup dependencies v pipeline
from core.infrastructure.database import Database
from core.infrastructure.external_client import ExternalClient

# Vytvoř shared dependencies
db = Database(settings.db_path)
client = ExternalClient(settings.api_key)

# Inject do handlerů
pipeline = ProcessingPipeline(handlers=[
    FeatureHandler1(db=db, client=client),
    FeatureHandler2(db=db, client=client),
])
```

**Proč?** Jednoduché, testovatelné, žádné magické frameworky.

---

### 3. Error Handling - Try/Cleanup Pattern

**Problém**: Handler vytvoří temp soubory, pak selže. Co s temp soubory?

**Řešení**: Jednoduchý try/finally cleanup.

```python
# VZOR - Try/finally cleanup pattern
class YourFeatureHandler(IDocumentHandler):
    def handle(self, document: Document) -> ProcessingResult:
        temp_files = []  # Track co vytvoříš během zpracování

        try:
            # Krok 1: Vytvoř dočasné soubory
            temp_data = self._create_temp_files(document)
            temp_files.extend(temp_data)

            # Krok 2: Zpracuj business logiku
            result = self._process_business_logic(temp_data)

            # Krok 3: Ulož finální výstup
            output_path = self._save_final_result(result)

            # ✅ Success - vrať výsledek
            return ProcessingResult(success=True, output_path=output_path)

        except Exception as e:
            logger.error(f"Processing failed: {e}")
            raise ProcessingError(f"Handler failed: {e}")

        finally:
            # 🧹 VŽDY vyčisti temp soubory (success i failure)
            self._cleanup_temp_files(temp_files)
```

**Pipeline graceful degradation:**

```python
class ProcessingPipeline:
    def process(self, document: Document) -> ProcessingResult:
        errors = []

        for handler in self.handlers:
            try:
                if handler.can_handle(document):
                    return handler.handle(document)  # ✅ Success!
            except ProcessingError as e:
                # Log a zkus další handler
                logger.warning(f"{handler.__class__.__name__} failed: {e}")
                errors.append((handler.__class__.__name__, str(e)))
                continue

        # Žádný handler neuspěl
        raise AllHandlersFailed(f"All handlers failed: {errors}")
```

---

### 4. Database - Jednoduchý Repository Pattern

**Pro solo dev: Jednoduchý SQLite + základní repository.**

```python
# core/infrastructure/database.py
import sqlite3
from typing import Optional

class Database:
    """Jednoduchý SQLite wrapper - žádný ORM pro začátek."""

    def __init__(self, db_path: str):
        self.db_path = db_path
        self._init_schema()

    def _init_schema(self):
        """Vytvoř tabulky pokud neexistují."""
        with sqlite3.connect(self.db_path) as conn:
            conn.execute("""
                CREATE TABLE IF NOT EXISTS documents (
                    id INTEGER PRIMARY KEY,
                    pdf_path TEXT,
                    timestamp TEXT,
                    status TEXT,
                    processed_by TEXT,
                    created_at TEXT
                )
            """)
            conn.execute("""
                CREATE TABLE IF NOT EXISTS processing_results (
                    id INTEGER PRIMARY KEY,
                    document_id INTEGER,
                    method TEXT,
                    output_path TEXT,
                    metadata TEXT,
                    FOREIGN KEY(document_id) REFERENCES documents(id)
                )
            """)

    def save_document(self, pdf_path: str, timestamp: str) -> int:
        """Ulož dokument, vrať ID."""
        with sqlite3.connect(self.db_path) as conn:
            cursor = conn.execute(
                "INSERT INTO documents (pdf_path, timestamp, status) VALUES (?, ?, ?)",
                (pdf_path, timestamp, "pending")
            )
            return cursor.lastrowid

    def update_status(self, doc_id: int, status: str, processed_by: str):
        """Update status dokumentu."""
        with sqlite3.connect(self.db_path) as conn:
            conn.execute(
                "UPDATE documents SET status=?, processed_by=? WHERE id=?",
                (status, processed_by, doc_id)
            )
```

**Feature-specific repository:**

```python
# features/{your_feature}/feature_repository.py
class FeatureRepository:
    """Feature-specific data - cache výsledků."""

    def __init__(self, db: Database):
        self.db = db
        self._init_tables()

    def _init_tables(self):
        """Feature-specific tabulka."""
        with sqlite3.connect(self.db.db_path) as conn:
            conn.execute("""
                CREATE TABLE IF NOT EXISTS feature_cache (
                    entity_key TEXT PRIMARY KEY,
                    cached_data TEXT,
                    cached_at TEXT
                )
            """)
```

**Proč?** Začni jednoduše, později můžeš přejít na ORM.

---

### 5. Testování - Minimalistický Přístup

**Pro solo dev: Pytest + základní testy handlerů.**

```python
# VZOR - Test handler s mocked dependencies
# features/your_feature/test_handler.py
import pytest
from unittest.mock import Mock
from core.domain import Document
from .handler import YourFeatureHandler

def test_handler_can_handle_positive_case():
    """Test že handler umí zpracovat správný dokument."""
    # Arrange - Mock dependencies
    mock_dependency1 = Mock()
    mock_dependency2 = Mock()
    handler = YourFeatureHandler(
        dependency1=mock_dependency1,
        dependency2=mock_dependency2
    )

    document = Document(pdf_path="test_valid.pdf")

    # Act
    result = handler.can_handle(document)

    # Assert
    assert result is True

def test_handler_rejects_invalid_document():
    """Test že handler odmítne nevalidní dokument."""
    mock_dependency1 = Mock()
    mock_dependency2 = Mock()
    handler = YourFeatureHandler(
        dependency1=mock_dependency1,
        dependency2=mock_dependency2
    )

    document = Document(pdf_path="test_invalid.pdf")

    result = handler.can_handle(document)

    assert result is False
```

**Spuštění testů:**
```bash
# Test jen jednu feature
pytest features/{your_feature}/

# Test všechno
pytest
```

---

### 6. Konfigurace - Pydantic Settings (bez singleton anti-patternu)

**Problém**: Singleton config nelze testovat.

**Řešení**: Pydantic BaseSettings s .env support.

```python
# config/settings.py
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    """Centrální konfigurace - načte z .env automaticky."""

    # Paths
    input_folder: str = "./input"
    output_folder: str = "./output"
    db_path: str = "./data/app.db"

    # Features
    feature_a_enabled: bool = True
    feature_a_timeout: int = 30

    feature_b_enabled: bool = True
    feature_b_model: str = "model-name"
    feature_b_api_key: str = ""

    # External API
    external_api_timeout: int = 10

    class Config:
        env_file = ".env"
        env_prefix = "APP_"

# Singleton instance (ale mockable!)
settings = Settings()
```

**.env soubor:**
```bash
APP_INPUT_FOLDER=/mnt/network/input
APP_AI_API_KEY=sk-xxx
APP_AI_ENABLED=true
```

**V kódu:**
```python
# VZOR - Použití settings v handleru
# features/your_feature/handler.py
from config.settings import settings

class YourFeatureHandler:
    def __init__(self, dependency1, dependency2):
        # Načti feature-specific config ze settings
        self.enabled = settings.your_feature_enabled
        self.timeout = settings.your_feature_timeout
        self.retry_count = settings.your_feature_retry_count
```

---

### 7. Logging - Jednoduchý Structured Logging

**Pro solo dev: Základní logging + JSON pro debug.**

```python
# core/infrastructure/logger.py
import logging
import json
from datetime import datetime

class StructuredLogger:
    """Jednoduchý structured logger - JSON output."""

    def __init__(self, name: str):
        self.logger = logging.getLogger(name)

    def info(self, message: str, **kwargs):
        """Log s kontextem."""
        log_entry = {
            "timestamp": datetime.now().isoformat(),
            "level": "INFO",
            "message": message,
            **kwargs
        }
        self.logger.info(json.dumps(log_entry, ensure_ascii=False))

# VZOR - Použití v handlerech
logger = StructuredLogger(__name__)

class YourFeatureHandler:
    def handle(self, document):
        """Log s business kontextem."""
        logger.info(
            "processing_started",
            handler=self.__class__.__name__,
            document_id=document.id,
            document_path=document.pdf_path
        )

        # ... zpracování ...

        logger.info(
            "processing_completed",
            handler=self.__class__.__name__,
            duration_ms=elapsed_time
        )
```

---

### 8. Rule of Three pro Duplicitu

**Problém**: Kdy duplicitu tolerovat, kdy abstrahi?

**Řešení: Rule of Three**

```
1. První implementace → Piš přímo do feature
   features/feature_a/data_processor.py

2. Druhá implementace → Zkopíruj (duplicita OK)
   features/feature_b/data_processor.py  (95% stejné jako A)

3. Třetí implementace → STOP! Abstrahi!
   → Přesuň do core/domain/data_processor.py (shared)
```

**Signály pro abstrakci:**
- ✅ 3+ features mají skoro stejný kód (>80%)
- ✅ Objevil jsi bug a musíš ho opravit ve 3 místech
- ✅ Features evolvují STEJNĚ (ne nezávisle)

**Signály pro duplicitu:**
- ✅ Features evolvují nezávisle
- ✅ Business kontext je jiný
- ✅ Teprve 2. implementace

---

### 9. Kdy je Feature Příliš Malá/Velká?

**Feature je příliš malá (slouči!):**
- < 100 řádků kódu celkem
- Jen 1-2 soubory
- Vždycky běží s jinou feature
- Žádná samostatná business funkce

**Feature je příliš velká (rozděl!):**
- > 2000 řádků kódu
- 10+ souborů v kořeni
- Dělá více než 1 business funkci
- Handler má > 5 metod

**Golden size:**
- 200-1000 řádků
- 3-8 souborů
- 1 jasná business funkce
- Lze vypnout samostatně

---

### 10. Feature Flags - Feature Toggles

**Pro solo dev: Essential pro production VSA systémy.**

Feature flags jsou **klíčový pattern** pro VSA - umožňují decouple deploy from release.

---

## ⚙️ FEATURE FLAGS - FEATURE TOGGLES

> "Feature flags change the traditional deployment workflow by decoupling deploy and release" - Martin Fowler

**Feature Flags** (aka Feature Toggles) = mechanismus pro zapnutí/vypnutí features **bez redeploye**.

### 🎯 Proč Feature Flags v VSA?

VSA je **perfektní** pro feature flags protože:
- ✅ Každý slice je izolovaná jednotka
- ✅ Lze vypnout slice bez dopadu na ostatní
- ✅ Features jsou nezávislé → snadné toggleování

**Výhody:**
- 🚀 **Decouple deploy from release** - deploy code teď, release později
- 🔄 **Instant rollback** - vypni feature okamžitě když selže
- 🧪 **Testing in production** - testuj na reálných datech
- 📊 **Progressive rollouts** - 1% → 10% → 100% uživatelů
- 🎚️ **A/B testing** - různé features pro různé skupiny

---

### 🏗️ Implementace v VSA

**1. Feature Flag v Config:**
```python
# config/settings.py
class Settings(BaseSettings):
    # Feature flags pro každý slice
    feature_a_enabled: bool = True
    feature_b_enabled: bool = True
    feature_c_enabled: bool = False  # Dark deploy!

    class Config:
        env_file = ".env"

settings = Settings()
```

**2. Handler respektuje flag:**
```python
# features/feature_a/handler.py
from config.settings import settings

class FeatureAHandler(IHandler):
    def can_handle(self, entity: Entity) -> bool:
        # Fail fast - feature vypnuta
        if not settings.feature_a_enabled:
            logger.info("Feature A is disabled by flag")
            return False

        # Business validace...
        return True
```

**3. Runtime toggle (advanced):**
```python
# core/infrastructure/feature_flags.py
class FeatureFlagService:
    """Centralized feature flag management."""

    def __init__(self, db: Database):
        self.db = db
        self._cache = {}  # Local cache

    def is_enabled(self, feature_name: str, user_id: Optional[str] = None) -> bool:
        """Check if feature enabled (with user targeting)."""

        # Check cache first
        if feature_name in self._cache:
            return self._cache[feature_name]

        # Load from DB
        flag = self.db.get_feature_flag(feature_name)

        # User-specific override
        if user_id and flag.has_user_override(user_id):
            return flag.get_user_override(user_id)

        # Progressive rollout (percentage)
        if flag.rollout_percentage < 100:
            return self._is_user_in_rollout(user_id, flag.rollout_percentage)

        return flag.enabled
```

---

### 🚀 Deployment Strategies

#### 1. **Dark Deploy**
```python
# Deploy novou feature s flaggem OFF
settings.new_feature_enabled = False  # Deployed but not released!

# Code je v produkci, ale nikdo ho nevidí
# → Žádné riziko, můžeš testovat interně
```

#### 2. **Progressive Rollout**
```python
class FeatureFlag:
    rollout_percentage: int = 0  # Start at 0%

# Den 1: 1% uživatelů
flag.rollout_percentage = 1

# Den 2: Žádné problémy → 10%
flag.rollout_percentage = 10

# Den 3: Žádné problémy → 50%
flag.rollout_percentage = 50

# Den 4: All good → 100%
flag.rollout_percentage = 100
```

#### 3. **Instant Rollback**
```python
# Production incident!
# ❌ Bez feature flags: Musíš revert commit + redeploy (30 min)
# ✅ S feature flags: Změň flag (30 sekund)

settings.problematic_feature_enabled = False  # Instant!

# Feature okamžitě vypnuta, máš čas debugovat offline
```

#### 4. **Canary Release**
```python
def can_handle(self, entity: Entity) -> bool:
    # Canary - jen pro internal users
    if settings.feature_x_canary_mode:
        if not entity.user.is_internal():
            return False  # External users don't see it yet

    # Production - pro všechny
    if not settings.feature_x_enabled:
        return False

    return True
```

---

### 🎯 Best Practices

**1. Independent Flags**
```python
# ✅ SPRÁVNĚ - nezávislé flags
feature_a_enabled: bool = True
feature_b_enabled: bool = True

# ❌ ŠPATNĚ - nested flags
if feature_a_enabled and feature_b_enabled:
    # Coupling mezi features!
```

**2. Unique Naming**
```python
# ✅ SPRÁVNĚ - jasné názvy
payment_processing_enabled: bool
invoice_export_enabled: bool

# ❌ ŠPATNĚ - generické názvy
feature_1_enabled: bool
new_feature_enabled: bool
```

**3. Flag Lifecycle**
```python
# Feature flag není věčná!
# 1. Create: Deploy s flaggem OFF
# 2. Enable: Postupně zapni (rollout)
# 3. Stabilize: Feature běží 100%
# 4. Remove: Odstraň flag + kód (už není potřeba)

# ❌ Neudržuj flag 6+ měsíců - code bloat!
```

**4. Monitoring**
```python
def handle(self, entity: Entity) -> Result:
    # Log když je feature disabled
    if not settings.feature_x_enabled:
        metrics.increment("feature_x.disabled")
        return None

    # Log usage
    metrics.increment("feature_x.used")
    return self._process(entity)
```

---

### 📊 Feature Flag Categories

**Martin Fowler categories:**

| Type | Longevity | Purpose | Example |
|------|-----------|---------|---------|
| **Release Toggles** | Krátká (týdny) | Dark deploy, progressive rollout | `new_payment_flow_enabled` |
| **Experiment Toggles** | Krátká (měsíce) | A/B testing | `checkout_variant_a_enabled` |
| **Ops Toggles** | Dlouhá (roky) | Circuit breaker, graceful degradation | `external_api_enabled` |
| **Permission Toggles** | Dlouhá (roky) | Access control | `admin_features_enabled` |

**V VSA používáš primárně:**
- ✅ **Release Toggles** - pro deployment strategies
- ✅ **Ops Toggles** - pro system resilience

---

### 🔧 Simple Implementation

**Minimalistický přístup pro solo dev:**

```python
# config/settings.py
class Settings(BaseSettings):
    # Release toggles
    feature_a: bool = True
    feature_b: bool = False  # Dark deploy

    # Ops toggles
    external_api_timeout: int = 30
    external_api_enabled: bool = True  # Circuit breaker

settings = Settings()

# .env soubor
# FEATURE_A=true
# FEATURE_B=false
# EXTERNAL_API_ENABLED=true

# Hot reload: Změň .env → restart app (nebo watch .env file)
```

---

### 🎓 Závěr

Feature Flags v VSA znamená:
- ✅ **Každý slice má flag** - lze vypnout nezávisle
- ✅ **Decouple deploy/release** - deploy kdykoliv, release kdy chceš
- ✅ **Instant rollback** - vypni problematický slice okamžitě
- ✅ **Progressive rollouts** - testuj na malé skupině první
- ✅ **Remove old flags** - flag není věčná, odstraň po stabilizaci

> "Feature flags are not a replacement for good engineering, but they are a powerful tool for risk mitigation" - Martin Fowler

**V production VSA systému jsou feature flags MUST-HAVE**, ne nice-to-have.

---

## 🏛️ DDD & VSA COMPATIBILITY

> "Domain-Driven Design emphasizes modeling software based on the core business domain and its logic" - Eric Evans

### 🤝 Proč DDD + VSA fungují perfektně dohromady?

**Domain-Driven Design (DDD)** a **Vertical Slice Architecture (VSA)** jsou **komplementární přístupy**:

| DDD | VSA |
|-----|-----|
| **Strategic design** - co stavíme | **Tactical pattern** - jak to stavíme |
| Bounded contexts = logické hranice | Vertical slices = praktická implementace |
| Ubiquitous language = terminologie | Feature folders = business procesy |
| Domain events = komunikace mezi kontexty | Event bus = komunikace mezi slices |

**Klíčová kompatibilita:**
```python
# DDD Bounded Context = VSA Feature Folder
bounded_contexts/
├── OrderManagement/     # DDD bounded context
│   ├── PlaceOrder/      # VSA slice
│   ├── CancelOrder/     # VSA slice
│   └── UpdateOrder/     # VSA slice
│
├── PaymentProcessing/   # DDD bounded context
│   ├── ProcessPayment/  # VSA slice
│   └── RefundPayment/   # VSA slice
```

> "Bounded contexts provide logical domain boundaries, while vertical slice architecture provides a practical implementation pattern" - DDD Practitioners Guide (2024)

---

### 📦 BOUNDED CONTEXTS v VSA

**Bounded Context** = hranice, ve které má terminologie jednoznačný význam.

#### **❌ Bez Bounded Contexts:**
```python
# 💥 "Customer" znamená RŮZNÉ věci!
features/
├── billing/customer.py          # Customer = plátce s fakturačními údaji
├── shipping/customer.py         # Customer = adresát s doručovací adresou
└── analytics/customer.py        # Customer = anonymizovaná statistika
```

#### **✅ S Bounded Contexts:**
```python
# ✅ Jednoznačná terminologie v každém kontextu
bounded_contexts/
├── BillingContext/
│   └── features/
│       └── invoice_processing/
│           └── billing_party.py     # Jasné: plátce faktury
│
├── ShippingContext/
│   └── features/
│       └── delivery_management/
│           └── recipient.py         # Jasné: příjemce zásilky
│
└── AnalyticsContext/
    └── features/
        └── customer_insights/
            └── customer_stats.py    # Jasné: agregovaná data
```

**Pravidlo:** Jeden bounded context = jeden `core/domain/` s vlastními entitami.

```python
# BillingContext/core/domain/entities.py
@dataclass
class BillingParty:
    """Plátce faktury - terminologie z Billing bounded context"""
    ico: str
    dic: str
    company_name: str
    bank_account: str  # ✅ Billing-specific atribut

# ShippingContext/core/domain/entities.py
@dataclass
class Recipient:
    """Příjemce zásilky - terminologie z Shipping bounded context"""
    name: str
    address: str
    phone: str
    delivery_instructions: str  # ✅ Shipping-specific atribut
```

**Výhoda:** Každý kontext může nezávisle evolvovat své entity bez konfliktů.

---

### 📣 DOMAIN EVENTS - Komunikace mezi slices

**Domain Event** = něco důležitého se stalo v doméně, na co by mohly jiné části systému chtít reagovat.

#### **🔹 Typy Events:**

| Typ | Scope | Příklady | Latence |
|-----|-------|----------|---------|
| **Domain Event** | In-process | `OrderPlaced`, `PaymentProcessed` | Okamžitá |
| **Integration Event** | Cross-service | `OrderCompletedEvent` (do jiného systému) | Asynchronní |

#### **📝 Implementace Domain Events v VSA:**

**1. Event definition:**
```python
# core/domain/events.py
from dataclasses import dataclass
from datetime import datetime

@dataclass
class DomainEvent:
    """Base class pro všechny domain events"""
    event_id: str
    timestamp: datetime
    event_type: str

@dataclass
class OrderPlacedEvent(DomainEvent):
    """Event: Objednávka byla vytvořena"""
    order_id: str
    customer_id: str
    total_amount: float

    def __post_init__(self):
        self.event_type = "OrderPlaced"

@dataclass
class PaymentProcessedEvent(DomainEvent):
    """Event: Platba byla zpracována"""
    payment_id: str
    order_id: str
    amount: float

    def __post_init__(self):
        self.event_type = "PaymentProcessed"
```

**2. Event bus (simple in-process):**
```python
# core/infrastructure/event_bus.py
from typing import Dict, List, Callable
from core.domain.events import DomainEvent

class InMemoryEventBus:
    """Simple event bus pro domain events"""

    def __init__(self):
        self._subscribers: Dict[str, List[Callable]] = {}

    def subscribe(self, event_type: str, handler: Callable) -> None:
        """Subscribe handler na konkrétní typ eventu"""
        if event_type not in self._subscribers:
            self._subscribers[event_type] = []
        self._subscribers[event_type].append(handler)

    def publish(self, event: DomainEvent) -> None:
        """Publish event všem subscriberům"""
        if event.event_type in self._subscribers:
            for handler in self._subscribers[event.event_type]:
                handler(event)  # Synchronní volání
```

**3. Feature A emituje event:**
```python
# features/order_management/handler.py
class PlaceOrderHandler(IHandler):
    def __init__(self, event_bus: InMemoryEventBus):
        self.event_bus = event_bus

    def handle(self, order: Order) -> Result:
        # Business logika
        order_id = self._save_order(order)

        # ✅ Emit domain event
        event = OrderPlacedEvent(
            event_id=str(uuid.uuid4()),
            timestamp=datetime.now(),
            order_id=order_id,
            customer_id=order.customer_id,
            total_amount=order.total
        )
        self.event_bus.publish(event)

        return Result(success=True, data={"order_id": order_id})
```

**4. Feature B reaguje na event:**
```python
# features/statistics/event_handlers.py
class OrderStatisticsEventHandler:
    """React na OrderPlaced events"""

    def __init__(self, event_bus: InMemoryEventBus):
        # Subscribe na event při inicializaci
        event_bus.subscribe("OrderPlaced", self.on_order_placed)

    def on_order_placed(self, event: OrderPlacedEvent) -> None:
        """Handler pro OrderPlaced event"""
        logger.info(f"📊 Statistics: Processing order {event.order_id}")

        # Update statistiky
        self._update_daily_revenue(event.total_amount)
        self._update_customer_order_count(event.customer_id)
```

**Výhody tohoto přístupu:**
- ✅ **Zero coupling** mezi features - nezávislé na sobě
- ✅ **Single Responsibility** - každá feature dělá POUZE svou práci
- ✅ **Easy testing** - můžeš testovat každou feature izolovaně
- ✅ **Scalability** - snadno přejdeš na external event bus (RabbitMQ, Kafka) později

---

### 🗣️ UBIQUITOUS LANGUAGE - Společný jazyk

> "Use the model as the backbone of a language... Commit the team to exercising that language relentlessly in all communication within the team and in the code" - Eric Evans

**Ubiquitous Language** = společný jazyk mezi **developery** a **business stakeholdery**.

#### **🎯 Co to znamená v praxi?**

| Business říká | Code by měl obsahovat |
|---------------|----------------------|
| "Faktura" | `class Invoice`, `InvoiceHandler` |
| "Zaúčtovat fakturu" | `def account_invoice()` |
| "Dodavatel" | `class Supplier` |
| "IČO dodavatele" | `supplier.ico` |

**❌ ŠPATNĚ - technický žargon:**
```python
# ❌ Business neřekne "data processor"
class DataProcessor:
    def process(self, data):
        result = self.transform(data)
        return self.save(result)
```

**✅ SPRÁVNĚ - ubiquitous language:**
```python
# ✅ Business řekne "zaúčtovat fakturu"
class AccountInvoiceHandler:
    def account_invoice(self, invoice: Invoice) -> AccountingResult:
        """Zaúčtování faktury do účetního systému"""
        entry = self.create_accounting_entry(invoice)
        return self.post_to_ledger(entry)
```

#### **📁 Ubiquitous Language v VSA struktuře:**

```python
# ✅ Názvy features = business terminologie
features/
├── invoice_accounting/        # Business: "zaúčtování faktury"
│   ├── account_invoice.py     # Business: "zaúčtovat fakturu"
│   └── reverse_entry.py       # Business: "storno záznamu"
│
├── supplier_management/       # Business: "správa dodavatelů"
│   ├── register_supplier.py  # Business: "registrovat dodavatele"
│   └── update_contact.py     # Business: "aktualizovat kontakt"
│
└── payment_processing/        # Business: "zpracování plateb"
    ├── process_payment.py    # Business: "zpracovat platbu"
    └── refund_payment.py     # Business: "vrátit platbu"
```

**Výhoda:** Business stakeholder se může podívat do `features/` a **okamžitě rozumí** struktuře.

---

### 🧩 DDD LITE v VSA - Praktický přístup

**DDD má 2 úrovně:**
1. **Strategic DDD** - bounded contexts, ubiquitous language, domain events (✅ vysoce užitečné)
2. **Tactical DDD** - aggregates, value objects, repositories, domain services (⚠️ může být overkill)

**Pro VSA doporučuji "DDD Lite":**

| DDD Pattern | VSA Usage | Kdy použít |
|-------------|-----------|------------|
| **Bounded Context** | ✅ MUST | Vždy - logické hranice domén |
| **Ubiquitous Language** | ✅ MUST | Vždy - názvy = business terminologie |
| **Domain Events** | ✅ HIGHLY RECOMMENDED | Pro komunikaci mezi features |
| **Entities** | ✅ YES | Pro core domain objekty |
| **Value Objects** | ⚠️ MAYBE | Pokud má business význam (e.g. Money, Address) |
| **Aggregates** | ⚠️ MAYBE | Pokud máš komplexní invarianty |
| **Domain Services** | ⚠️ MAYBE | Pokud logika nepatří do entity |
| **Repositories** | ✅ YES | Abstrakce nad data access |

**Příklad DDD Lite v VSA:**

```python
# core/domain/entities.py - Strategic DDD ✅
@dataclass
class Invoice:
    """Invoice = core domain entity (ubiquitous language)"""
    invoice_id: str
    supplier_ico: str
    amount: Money         # Value object - business význam
    issue_date: date
    due_date: date
    status: InvoiceStatus

# core/domain/value_objects.py - Tactical DDD (pouze pokud má význam)
@dataclass(frozen=True)  # Immutable
class Money:
    """Value object pro peníze - business pravidla"""
    amount: Decimal
    currency: str = "CZK"

    def __post_init__(self):
        if self.amount < 0:
            raise ValueError("Amount cannot be negative")

    def __add__(self, other: 'Money') -> 'Money':
        if self.currency != other.currency:
            raise ValueError("Cannot add different currencies")
        return Money(self.amount + other.amount, self.currency)

# features/invoice_accounting/handler.py - VSA slice
class AccountInvoiceHandler(IHandler):
    def handle(self, invoice: Invoice) -> Result:
        # ✅ Používáme domain entities a value objects
        total = invoice.amount + self._calculate_tax(invoice.amount)

        # Domain event
        self.event_bus.publish(InvoiceAccountedEvent(
            invoice_id=invoice.invoice_id,
            total=total
        ))
```

---

### 🎯 DDD + VSA - Rozhodovací matice

**Kdy POUŽÍT DDD s VSA:**

| Situace | Strategic DDD | Tactical DDD | Důvod |
|---------|---------------|--------------|-------|
| Malý projekt (< 5 features) | ⚠️ MAYBE | ❌ NE | Overkill - YAGNI |
| Střední projekt (5-20 features) | ✅ ANO | ⚠️ LITE | Bounded contexts pomáhají organizovat |
| Velký projekt (20+ features) | ✅ MUST | ✅ ANO | Bez DDD se ztratíš |
| Komplexní business pravidla | ✅ ANO | ✅ ANO | Value objects, aggregates pomáhají |
| Jednoduchá CRUD aplikace | ❌ NE | ❌ NE | Stačí VSA samo |
| Multiple týmy | ✅ MUST | ✅ ANO | Bounded contexts = team boundaries |

**Praktický postup:**

1. **Start simple** - začni s čistým VSA
2. **Add bounded contexts** - pokud features začínají mít konflikty v terminologii
3. **Add domain events** - pokud features potřebují komunikovat
4. **Add tactical patterns** - pouze pokud business logika je komplexní

**Nezapomeň:** DDD je nástroj pro řešení **komplexity**, ne módní framework pro každý projekt.

---

### 📊 Real-World Příklad: VSA + DDD

**Scénář:** E-commerce systém

```python
# Bounded contexts = top-level složky
bounded_contexts/
├── OrderManagement/     # Context: Správa objednávek
│   ├── core/
│   │   ├── domain/
│   │   │   ├── order.py        # Entity: Order
│   │   │   └── events.py       # Events: OrderPlaced, OrderCancelled
│   │   └── interfaces/
│   │       └── order_repo.py   # Repository interface
│   ├── features/
│   │   ├── place_order/        # VSA slice
│   │   ├── cancel_order/       # VSA slice
│   │   └── update_order/       # VSA slice
│   └── infrastructure/
│       └── order_repo_impl.py
│
├── PaymentProcessing/   # Context: Zpracování plateb
│   ├── core/
│   │   ├── domain/
│   │   │   ├── payment.py      # Entity: Payment
│   │   │   └── money.py        # Value object: Money
│   │   └── interfaces/
│   ├── features/
│   │   ├── process_payment/    # VSA slice
│   │   └── refund_payment/     # VSA slice
│   └── infrastructure/
│
└── Statistics/          # Context: Statistiky
    ├── core/
    │   └── domain/
    │       └── events.py       # Subscribe na events z jiných contexts
    ├── features/
    │   ├── order_stats/        # VSA slice
    │   └── revenue_report/     # VSA slice
    └── event_handlers/
        └── order_events.py     # React na OrderPlaced
```

**Komunikace mezi bounded contexts:**

```python
# OrderManagement context emituje event
# bounded_contexts/OrderManagement/features/place_order/handler.py
def handle(self, order: Order) -> Result:
    order_id = self._save_order(order)

    # Emit domain event - jiné contexty můžou poslouchat
    self.event_bus.publish(OrderPlacedEvent(
        order_id=order_id,
        total=order.total
    ))

# Statistics context reaguje
# bounded_contexts/Statistics/event_handlers/order_events.py
def on_order_placed(self, event: OrderPlacedEvent) -> None:
    self._update_stats(event)

# PaymentProcessing context reaguje
# bounded_contexts/PaymentProcessing/event_handlers/order_events.py
def on_order_placed(self, event: OrderPlacedEvent) -> None:
    self._trigger_payment_request(event)
```

**Výhody kombinace DDD + VSA:**
- ✅ **Clear boundaries** - každý bounded context je samostatný svět
- ✅ **Team scalability** - každý tým může vlastnit jeden bounded context
- ✅ **Business alignment** - terminologie = business jazyk
- ✅ **Low coupling** - komunikace pouze přes domain events
- ✅ **Easy testing** - můžeš testovat každý context izolovaně

---

### 💡 Key Takeaways

1. **DDD Strategic Design + VSA = 🤝 Perfect match**
   - Bounded contexts = logické hranice
   - Vertical slices = praktická implementace

2. **Domain Events = lepší než přímé volání**
   - Zero coupling mezi features
   - Async reakce na změny

3. **Ubiquitous Language = povinnost**
   - Názvy tříd/funkcí = business terminologie
   - Business stakeholder rozumí struktuře kódu

4. **DDD Lite je často dost**
   - Strategic DDD (contexts, events, language) = ✅ ano
   - Tactical DDD (aggregates, services) = pouze pokud je potřeba

5. **Start simple, add complexity only when needed**
   - Začni s čistým VSA
   - Přidávej DDD patterns postupně podle potřeby

---

### 11. Real-World Edge Cases

**"Potřebuji feature A komunikovat s feature B"**

**Odpověď**: Většinou ŠPATNĚ, ale:

✅ **OK přes events:**
```python
# VZOR - Event-based komunikace mezi features
# features/feature_a/handler.py
def handle(self, document):
    result = self._process(document)

    # Emit event místo přímého volání feature B
    self.event_bus.publish("document_processed", {
        "document_id": document.id,
        "method": self.__class__.__name__
    })
    return result

# features/feature_b/handler.py - Subscribe na event
def on_document_processed(self, event_data):
    """React na event z jiné feature - decoupled."""
    self.handle_external_event(event_data)
```

❌ **ŠPATNĚ - přímé volání:**
```python
# ❌ NIKDY nedělej import z jiné feature!
from features.other_feature.handler import some_function  # CROSS-FEATURE!
```

**"Přidal jsem feature C a zlomil feature A"**

**Prevence**:
1. Features nesmí importovat z jiných features
2. Integration test pipeline před commitem
3. Feature flags - vypni novou feature při problémech

**"Mám 20 features, pipeline je pomalý"**

**Optimalizace**: Paralelní `can_handle()` check:
```python
from concurrent.futures import ThreadPoolExecutor

def process(self, document):
    # Paralelní check kdo umí zpracovat
    with ThreadPoolExecutor() as executor:
        checks = {
            executor.submit(h.can_handle, document): h
            for h in self.handlers
        }

        for future in checks:
            if future.result():
                handler = checks[future]
                return handler.handle(document)
```

---

📚 DOPORUČENÁ ČETBA PRO HLUBŠÍ POCHOPENÍ
"Vertical Slice Architecture" - Jimmy Bogard
"The Wrong Abstraction" - Sandi Metz
"Feature Slices for ASP.NET Core" - Jimmy Bogard
"Domain-Driven Design" - Eric Evans (pro domain modeling)
🎓 ZÁVĚREČNÉ PRINCIPY

1. **Business First**
   Vždy začni otázkou: "Co chci dosáhnout?" (ne "Jakou technologii použiju?")

2. **Feature Isolation**
   Každá feature je samostatný svět - smažeš složku = funkce zmizí.

3. **Duplication Over Coupling**
   Raději duplicita než špatná abstrakce.

4. **Thin Core**
   Core je sacred - přidávej tam jen absolutní minimum.

5. **Evolvability**
   Architektura musí umožnit snadné přidávání/odebírání features.

---

## 🗺️ NEZTRATIL SES? Vrať se k navigaci

**Pokud hledáš konkrétní workflow nebo postup:**

👉 **[Otevři mapa.md](mapa.md)** - Decision tree pro všechny typy úkolů

- ⚡ Quick Reference - typ úkolu za 10 sekund
- 🚦 6 scénářů s kroky (přidat, upravit, refaktorovat, komunikace, shared, flags, DDD)
- 📋 Checklists před/po úkolu
- 🚨 Critical Rules - zakázané praktiky

**Zlaté pravidlo:**
> Úkol → [mapa.md](mapa.md) → Decision tree → Vrať se sem pro detaily

---

Tento dokument použij jako referenci při každém architektonickém rozhodnutí. Když si nejsi jistý - vrať se k základním principům VSA. Hodně zdaru při výstavbě čistého, udržovatelného systému! 🚀