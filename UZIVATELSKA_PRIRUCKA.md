# 📱 TODO App - Uživatelská příručka

> **Moderní TODO aplikace s AI funkcemi pro efektivní správu úkolů**

Vítej v uživatelské příručce TODO aplikace! Tato příručka ti ukáže, jak maximálně využít všechny funkce aplikace.

---

## 📖 Obsah

1. [Rychlý start](#-rychlý-start)
2. [Základy](#-základy-práce-s-úkoly)
3. [Smart tagy](#-smart-tagy)
4. [Pohledy a filtry](#-pohledy-views-a-filtry)
5. [Vyhledávání a řazení](#-vyhledávání-a-řazení)
6. [Pomodoro timer](#-pomodoro-timer)
7. [AI funkce](#-ai-funkce)
8. [Nastavení](#-nastavení)
9. [Tipy a triky](#-tipy-a-triky)

---

## 🚀 Rychlý start

### První spuštění

1. **Otevři aplikaci** - při prvním spuštění se zobrazí **průvodce pro začátečníky**
2. **Projdi si tutorial** - interaktivní průvodce tě naučí základy
3. **Vytvoř první úkol** - klikni na INPUT BAR (spodní lišta) a napiš svůj první úkol

### První úkol

```
Koupit mléko *dnes* *a*
```

✅ **Výsledek**: Úkol s deadline DNES a prioritou A (vysoká)

---

## 📝 Základy práce s úkoly

### Vytvoření úkolu

1. Klikni na **INPUT BAR** (spodní lišta s ikonou ➕)
2. Napiš text úkolu
3. (Volitelné) Přidej tagy - viz [Smart tagy](#-smart-tagy)
4. Potvrď **✓** (nebo Enter)

**Příklad:**
```
Zavolat doktorovi *zitra* *b*
```

### Úprava úkolu

1. Klikni na **úkol** → otevře se TodoCard (rozbalený)
2. Klikni na **✏️ Edit** tlačítko
3. Uprav text
4. Potvrď **✓**

### Označení jako hotové

- **Rychlý způsob**: Klikni na **✓** vlevo od úkolu
- **V TodoCard**: Klikni na ✓ tlačítko vpravo nahoře

### Smazání úkolu

1. Otevři úkol (klikni na něj)
2. Klikni na **🗑️** tlačítko (vpravo dole)
3. Potvrď smazání

---

## 🏷️ Smart tagy

Tagy ti pomáhají **organizovat úkoly** pomocí priorit, deadlinů a vlastních kategorií.

### Syntaxe tagů

Tagy píšeš mezi **hvězdičky**: `*tag*`

### Typy tagů

#### 1. **Priorita** (🔴🟡🟢)

| Tag | Priorita | Zobrazení |
|-----|----------|-----------|
| `*a*` | Vysoká | 🔴 A |
| `*b*` | Střední | 🟡 B |
| `*c*` | Nízká | 🟢 C |

**Příklad:**
```
*a* Dokončit projekt
*b* Poslat email
*c* Uklidit garáž
```

#### 2. **Deadline** (📅⏰)

| Tag | Význam | Příklad |
|-----|--------|---------|
| `*dnes*` | Dnešní den | `*dnes* Zavolat mámě` |
| `*zitra*` | Zítřek | `*zitra* Schůzka s klientem` |
| `*15.1.*` | Konkrétní datum | `*15.1.* Odevzdat práci` |
| `*13.10.15:30*` | Datum + čas | `*13.10.15:30* Důležitá schůzka` |

**Formáty data:**
- `*DD.M.*` - např. `*5.1.*` (5. ledna)
- `*DD.M.HH:MM*` - např. `*5.1.14:30*` (5. ledna v 14:30)

**Příklad:**
```
*dnes* *a* Koupit dárek
*15.12.* *b* Návštěva u babičky
*zitra* Jít do fitka
```

#### 3. **Vlastní kategorie** (🎨)

Můžeš vytvořit **vlastní tagy** pro kategorii úkolů:

```
*projekt* *a* Napsat dokumentaci
*nakup* Koupit mléko
*domov* Uklidit pokoj
*prace* Dokončit report
```

**Poznámka:** Vlastní tagy začínají malým písmenem a nejsou rezervovaná slova (`dnes`, `zitra`, `a`, `b`, `c`).

### Kombinace tagů

Můžeš kombinovat **více tagů** v jednom úkolu:

```
*a* *dnes* *nakup* Koupit mléko a chleba
```

✅ **Výsledek**: Priorita A, Deadline dnes, Kategorie "nakup"

### Správa definic tagů

Vlastní tagy můžeš spravovat v **Tag Management** (přístupné přes nastavení):

1. Otevři **Nastavení** (⚙️ ikona vpravo nahoře)
2. Přejdi na záložku **Tag Management**
3. Vytvoř nový tag:
   - **Název**: např. "projekt"
   - **Emoji**: 🚀
   - **Barva**: modrá

**Výhoda:** Vlastní tagy budou mít **barevný chip** a emoji ve všech úkolech!

---

## 📊 Pohledy (Views) a filtry

Pohledy ti umožňují **filtrovat úkoly** podle časových kategorií.

### Built-in Views

Horizontální scroll nahoře (VIEW BAR):

| View | Ikona | Zobrazuje |
|------|-------|-----------|
| **📋 Všechny** | `list` | Všechny úkoly |
| **📅 Dnes** | `today` | Úkoly s deadline dnes |
| **🗓️ Týden** | `calendar_week` | Úkoly na nadcházející týden |
| **⏰ Nadcházející** | `schedule` | Všechny úkoly s deadline |
| **⚠️ Overdue** | `warning` | Úkoly po termínu (červeně!) |
| **✨ Brief** | `auto_awesome` | AI doporučené úkoly (viz [AI Brief](#ai-brief)) |

**Jak přepnout view:**
- Swipe VIEW BAR doleva/doprava
- Klikni na požadovaný view tab

### Custom Views (vlastní pohledy)

Můžeš vytvořit **vlastní pohledy** podle tagů!

#### Vytvoření Custom View:

1. Otevři **Nastavení** → záložka **Agenda**
2. Klikni na **PŘIDAT CUSTOM VIEW**
3. Vyplň:
   - **Název**: např. "Oblíbené"
   - **Tag Filter**: např. "projekt" (BEZ hvězdiček!)
   - **Emoji**: např. ⭐
4. Klikni **Přidat**

✅ **Výsledek**: Nový tab ve VIEW BAR s ikonou ⭐ a názvem "Oblíbené" - zobrazí pouze úkoly s tagem `*projekt*`

**Příklad Custom Views:**
- 🚀 **Projekty** - filter: `projekt`
- 🛒 **Nákupy** - filter: `nakup`
- 🏠 **Domácí** - filter: `domov`
- 💼 **Práce** - filter: `prace`

#### Správa Custom Views:

- **Zapnout/Vypnout**: Toggle switch v nastavení
- **Upravit**: ✏️ ikona v nastavení
- **Smazat**: 🗑️ ikona v nastavení

---

## 🔍 Vyhledávání a řazení

### Vyhledávání

1. Klikni na **🔍** ikonu (vlevo od INPUT BAR)
2. Napiš hledaný text
3. Aplikace **live filtruje** úkoly podle názvu a tagů

**Tipy:**
- Hledání je **case-insensitive** (nezáleží na velikosti písmen)
- Můžeš hledat podle **názvu** i **tagů**
- Prázdný search zobrazí všechny úkoly

### Řazení

Klikni na **⇅** ikonu (SORT BAR nahoře) a vyber způsob řazení:

| Řazení | Ikona | Popis |
|--------|-------|-------|
| **🔴 Priorita** | `priority_high` | A → B → C → bez priority |
| **📅 Deadline** | `event` | Nejbližší termín first |
| **✅ Status** | `check_circle` | Nedokončené → Hotové |
| **🆕 Datum** | `schedule` | Nejnovější úkoly first |

**Poznámka:** Řazení se automaticky **ukládá** a zachová se i po restartu aplikace.

---

## ⏱️ Pomodoro Timer

Pomodoro technika ti pomůže **soustředit se** na jeden úkol.

### Co je Pomodoro?

- **25 min práce** → **5 min pauza** → **repeat**
- Po **4 pomodorech** → **dlouhá pauza (15-30 min)**

### Jak použít Pomodoro timer:

#### Varianta A: Z úkolu

1. Otevři úkol (klikni na něj)
2. Klikni na **⏱️ Pomodoro** tlačítko
3. Timer se spustí (25 minut)
4. Pracuj na úkolu!
5. Po skončení → notifikace + automatická pauza

#### Varianta B: Z hlavní obrazovky

1. Klikni na **⏱️** ikonu (vpravo nahoře)
2. Otevře se **Pomodoro stránka**
3. Klikni **START**
4. Timer běží!

### Ovládání timeru:

- **▶️ START** - spustit timer
- **⏸️ PAUSE** - pozastavit
- **⏹️ STOP** - zastavit a ukončit session
- **⏭️ SKIP** - přeskočit na další fázi

### Nastavení Pomodoro:

V Pomodoro stránce → **⚙️ Nastavení**:

- **Pracovní doba**: 25 min (default)
- **Krátká pauza**: 5 min
- **Dlouhá pauza**: 15 min
- **Cyklů do dlouhé pauzy**: 4

### Historie session:

V Pomodoro stránce vidíš **historii dokončených session**:
- Datum a čas
- Úkol (pokud byl přiřazen)
- Délka session

---

## 🤖 AI funkce

Aplikace obsahuje **4 AI funkce** powered by OpenRouter API.

> **⚠️ Poznámka:** AI funkce vyžadují **OpenRouter API klíč** - viz [Nastavení AI](#nastavení-ai)

---

### AI Brief

**Co to je:** Inteligentní filtrování úkolů - AI ti doporučí, na čem se **soustředit teď**.

**Jak použít:**
1. Přejdi na view **✨ Brief** (ve VIEW BAR)
2. AI vygeneruje brief s 3 sekcemi:
   - 🎯 **FOCUS NOW** - top 3 úkoly k dokončení
   - 📊 **KEY INSIGHTS** - dependencies, quick wins
   - 💪 **MOTIVATION** - progress, encouragement
3. **Vidíš real TodoCards** - můžeš hned pracovat (označit jako hotové, editovat, spustit pomodoro)

**Regenerace:**
- Brief se **cachuje na 1 hodinu**
- Pro manuální regeneraci: swipe down (pull to refresh)

**Cost:** ~$0.009 per brief

---

### AI Split

**Co to je:** AI rozdělí **složitý úkol** na menší subtasky.

**Jak použít:**
1. Otevři úkol (klikni na něj)
2. Klikni na **🤖 AI Split** tlačítko
3. AI vygeneruje subtasky (obvykle 3-8 kroků)
4. Zkontroluj návrh
5. Klikni **PŘIJMOUT** → subtasky se uloží do úkolu

**Příklad:**

**Input:**
```
Naplánovat dovolenou v Itálii
```

**AI Output:**
```
1. Zjistit termín dovolené
2. Vybrat destinaci (Řím vs. Florencie)
3. Rezervovat letenky
4. Najít ubytování
5. Naplánovat aktivity
6. Zařídit pojištění
```

**Úprava subtasků:**
- Po přijetí můžeš subtasky **editovat** nebo **smazat**
- Označovat jako hotové (checkbox)

**Cost:** ~$0.015 per split

---

### AI Chat

**Co to je:** Konverzace s AI o tvých úkolech - AI zná **kontext** (seznam úkolů, deadliny, priority).

**Jak použít:**
1. Klikni na **💬** ikonu (vpravo nahoře)
2. Otevře se AI Chat stránka
3. AI má **automatický kontext**:
   - Počet úkolů
   - Overdue tasky
   - Nadcházející deadliny
4. Piš zprávy → AI ti odpoví

**Příklady dotazů:**
```
Co mám dělat jako první?
Jak organizovat úkoly pro projekt?
Jaké jsou moje priority na dnes?
Pomož mi s plánováním týdne
```

**Kontext:**
- AI vidí **aktuální seznam úkolů**
- Nezná **obsah hotových úkolů** (pouze aktivní)

**Cost:** ~$0.02 per zpráva (v závislosti na délce konverzace)

---

### AI Motivation

**Co to je:** AI vygeneruje **motivační prompt** podle typu úkolu.

**Jak použít:**
1. Otevři úkol (klikni na něj)
2. Klikni na **💪 Motivace** tlačítko
3. AI vygeneruje motivační text
4. (Volitelné) Zprávu můžeš **zavřít** nebo **zobrazit znovu**

**Příklad:**

**Úkol:**
```
Napsat seminární práci *a* *15.1.*
```

**AI Response:**
```
💪 Tvoje seminární práce bude skvělá! Začni s úvodem dnes -
stačí jen 3 odstavce. Rozdělení na menší kroky ti pomůže
dokončit včas. Máš na to! 🚀
```

**Custom prompty:**
- V nastavení můžeš vytvořit **vlastní motivační prompty**
- AI je použije podle typu úkolu

**Cost:** ~$0.01 per prompt

---

### Nastavení AI

Pro aktivaci AI funkcí je nutné nakonfigurovat OpenRouter API.

#### Získání API klíče:

1. Jdi na [openrouter.ai](https://openrouter.ai)
2. Registruj se / přihlaš se
3. Vytvoř API klíč (v dashboard)
4. Zkopíruj klíč (formát: `sk-or-v1-...`)

#### Konfigurace v aplikaci:

1. Otevři **Nastavení** (⚙️ ikona)
2. Přejdi na záložku **AI Settings**
3. Vyplň:
   - **API Key**: vlož svůj OpenRouter klíč
   - **Model**: vyber AI model (default: `mistralai/mistral-medium-3.1`)
   - **Temperature**: 0.0-2.0 (default: 0.7)
     - `0.0` - konzistentní, předvídatelné odpovědi
     - `2.0` - kreativní, náhodné odpovědi
   - **Max Tokens**: 100-4000 (default: 1000)
     - Maximální délka AI odpovědi

4. Klikni **Uložit**

#### Doporučené modely:

| Model | Cena | Rychlost | Kvalita |
|-------|------|----------|---------|
| `mistralai/mistral-medium-3.1` | 💰 | ⚡⚡ | ⭐⭐⭐ |
| `anthropic/claude-3.5-sonnet` | 💰💰💰 | ⚡ | ⭐⭐⭐⭐⭐ |
| `openai/gpt-4o` | 💰💰 | ⚡⚡ | ⭐⭐⭐⭐ |
| `google/gemini-flash-1.5` | 💰 | ⚡⚡⚡ | ⭐⭐⭐ |

**Tip:** Pro běžné použití stačí **Mistral Medium** - dobrý poměr cena/výkon.

#### Custom Motivační Prompty:

V **Nastavení → Motivační Prompty** můžeš vytvořit vlastní šablony:

1. Klikni **PŘIDAT PROMPT**
2. Vyplň:
   - **Název**: např. "Prokrastinace"
   - **Prompt**: např. "Nakopni mě, abych konečně začal s úkolem: {task}"
3. Klikni **Uložit**

**Placeholder:** `{task}` se nahradí názvem úkolu

---

## ⚙️ Nastavení

Nastavení najdeš kliknutím na **⚙️** ikonu (vpravo nahoře).

### Záložky:

#### 1. **AI Settings** (AI nastavení)

- OpenRouter API klíč
- Model selection
- Temperature / Max Tokens
- Viz [Nastavení AI](#nastavení-ai)

#### 2. **Prompts** (Motivační prompty)

- Správa custom motivačních promptů
- Vytvoř vlastní šablony pro AI Motivation

#### 3. **Themes** (Témata)

Vyber si barevné téma aplikace:

| Téma | Styl | Barvy |
|------|------|-------|
| **🌑 Doom One** | Dark | Tmavě modrá, červená, zelená |
| **🌃 Blade Runner** | Dark | Neonová růžová, cyan, tmavá |
| **🌸 Osaka Jade** | Light | Pastelové zelené a růžové |
| **⚫ AMOLED** | Dark | Čistě černá (battery saving) |
| **🔵 Monokai Pro** | Dark | Fialová, zelená, žlutá |
| **🧛 Dracula** | Dark | Fialová, cyan, zelená |

**Jak změnit téma:**
1. Otevři **Nastavení → Themes**
2. Klikni na požadované téma
3. Aplikace se automaticky přebarvuje

#### 4. **Agenda** (Agenda Views)

##### Built-in Views

Zapni/vypni standardní pohledy:

- ✅ **📋 Všechny** (default: ON)
- ✅ **📅 Dnes** (default: ON)
- ✅ **🗓️ Týden** (default: ON)
- ✅ **⏰ Nadcházející** (default: ON)
- ✅ **⚠️ Overdue** (default: ON)

**Tip:** Pokud některé pohledy nepoužíváš, vypni je → VIEW BAR bude přehlednější.

##### Custom Views

Vytvoř vlastní pohledy podle tagů:

1. Klikni **PŘIDAT CUSTOM VIEW**
2. Vyplň název, tag filter, emoji
3. Zapni/Vypni podle potřeby

**Příklad:**
- 🚀 **Projekty** - zobrazí úkoly s `*projekt*`
- 🛒 **Nákupy** - zobrazí úkoly s `*nakup*`

#### 5. **Tag Management** (Správa tagů)

- Definuj **vlastní tagy** s emoji a barvou
- Tagy se zobrazí jako barevné chipy ve všech úkolech

**Postup:**
1. Klikni **PŘIDAT TAG**
2. Vyplň:
   - **Název**: např. "projekt" (lowercase!)
   - **Emoji**: např. 🚀
   - **Barva**: např. modrá
3. Klikni **Uložit**

✅ **Výsledek:** Všechny úkoly s `*projekt*` budou mít 🚀 modrý chip!

---

## 💡 Tipy a triky

### 1. **Klávesové zkratky (mobile)**

- **Swipe doleva** na TodoCard → **Smazat**
- **Swipe doprava** na TodoCard → **Označit jako hotové**
- **Long press** na úkol → **Rychlé akce**

### 2. **Efektivní workflow**

**Ranní rutina:**
1. Přejdi na **📅 Dnes**
2. Prohlédni si úkoly s deadlinem dnes
3. Použij **✨ AI Brief** pro prioritizaci
4. Spusť **⏱️ Pomodoro** na první úkol

**Večerní příprava:**
1. Zkontroluj **⚠️ Overdue** - dožeň nebo přesuň
2. Vytvoř úkoly na zítřek s tagem `*zitra*`
3. Použij **🤖 AI Split** pro složité úkoly

### 3. **Organizace pomocí tagů**

**Doporučený systém:**
```
*a* = MUSÍM udělat dnes
*b* = MĚLO BY být hotové brzy
*c* = NICE TO HAVE

+ deadline (*dnes*, *zitra*, *DD.M.*)
+ kategorie (*projekt*, *nakup*, *domov*)
```

**Příklad:**
```
*a* *dnes* *projekt* Dokončit prezentaci
*b* *15.1.* *nakup* Koupit dárek mámě
*c* *domov* Uklidit garáž
```

### 4. **Custom Views pro projekty**

Pokud pracuješ na více projektech, vytvoř **Custom View pro každý projekt**:

1. Tag každý úkol podle projektu: `*projektA*`, `*projektB*`
2. Vytvoř Custom Views:
   - 🚀 **Projekt A** - filter: `projektA`
   - 🎯 **Projekt B** - filter: `projektB`
3. Přepínej mezi projekty jedním kliknutím!

### 5. **AI Brief pro prioritizaci**

Máš moc úkolů a nevíš, kde začít?

1. Přejdi na **✨ Brief**
2. AI ti ukáže **top 3 priority** (FOCUS NOW)
3. Začni s prvním úkolem
4. Po dokončení → refresh Brief (swipe down)

### 6. **Pomodoro pro prokrastinaci**

Prokrastinuješ? Použij Pomodoro:

1. Vyber úkol, na který se nemůžeš donutit
2. Klikni **⏱️ Pomodoro**
3. Řekni si: "Jen 25 minut!"
4. Po timer → odměna (5 min pauza)

**Tip:** Často zjistíš, že po 1 pomodoru chceš pokračovat!

### 7. **Backup a export** (TODO - zatím neimplementováno)

> **⚠️ Poznámka:** Export funkcionalita zatím není dostupná. Plánováno v budoucí verzi.

---

## 🆘 Řešení problémů (Troubleshooting)

### AI funkce nefungují

**Příznaky:**
- Kliknutí na AI tlačítko → chyba "API key not configured"
- AI Brief se nezobrazuje

**Řešení:**
1. Zkontroluj **Nastavení → AI Settings**
2. Ověř, že máš správně zadaný **API klíč** (formát: `sk-or-v1-...`)
3. Zkontroluj **internet connection**
4. Zkus jiný AI model (některé modely mohou být offline)

### Tagy se neparsují správně

**Příznaky:**
- Tag se zobrazuje jako běžný text (např. `*a*` místo 🔴 A)

**Řešení:**
- Ujisti se, že tagy jsou **mezi hvězdičkami**: `*a*` ne `a*` nebo `*a`
- Priority jsou **lowercase**: `*a*` ne `*A*`
- Datum je ve správném formátu: `*15.1.*` ne `*15/1*`

### Úkoly mizí z pohledů

**Příznaky:**
- Úkol existuje, ale nevidím ho v "Dnes" nebo "Týden"

**Řešení:**
- Zkontroluj **VIEW BAR** - možná jsi na špatném pohledu
- Zkontroluj **SEARCH BAR** - možná máš aktivní vyhledávání (clear search)
- Zkontroluj **SORT BAR** - řazení může úkol posunout dolů

### Pomodoro timer se zastavuje

**Příznaky:**
- Timer se pozastaví sám od sebe

**Řešení:**
- Zkontroluj **Battery Saver** nastavení (může zastavovat background processes)
- Zkontroluj **App Permissions** - povolení pro notifikace

### Aplikace je pomalá

**Řešení:**
1. **Clear completed tasks**: Smaž staré hotové úkoly
2. **Restart app**: Zavři a znovu otevři aplikaci
3. **Clear cache**: (TODO - zatím není funkce, plánováno)

---

## ❓ FAQ (Často kladené otázky)

### Kolik stojí AI funkce?

**Odpověď:** Aplikace sama je **ZDARMA**, ale AI funkce spotřebovávají OpenRouter kredity:

- **AI Brief**: ~$0.009 per generování
- **AI Split**: ~$0.015 per split
- **AI Chat**: ~$0.02 per zpráva
- **AI Motivation**: ~$0.01 per prompt

**Odhad:** Při průměrném používání (10 AI requestů denně) ~ **$3-5 per měsíc**.

### Můžu používat aplikaci bez AI funkcí?

**Odpověď:** Ano! Všechny **základní funkce** fungují bez API klíče:
- Správa úkolů
- Smart tagy
- Pohledy a filtry
- Vyhledávání a řazení
- Pomodoro timer

AI funkce jsou **volitelné enhancement**.

### Jak zabezpečit API klíč?

**Odpověď:**
- API klíč se ukládá **pouze lokálně** na tvém zařízení (SQLite databáze)
- **Nebude** synchronizován na cloud
- **Nebude** sdílen s třetími stranami
- Při odinstalovaci aplikace → klíč se **smaže**

**Tip:** Nikdy nesdílej svůj API klíč veřejně!

### Budou přidány další AI funkce?

**Odpověď:** Ano! Plánované funkce:
- 📊 **AI Analytics** - statistiky produktivity
- 🎯 **Smart Suggestions** - AI doporučení nových úkolů
- 📅 **Calendar Sync** - integrace s Google Calendar
- 🔄 **Backup & Sync** - cloud synchronizace

---

## 📞 Podpora a kontakt

### Nahlášení chyby (Bug Report)

Našel jsi chybu? Napiš mi na:
- **GitHub Issues**: [github.com/yourusername/flutter-todo/issues](https://github.com/yourusername/flutter-todo/issues)
- **Email**: your.email@example.com

**Co zahrnout:**
- Popis chyby
- Kroky k reprodukci
- Screenshot (pokud možné)
- Verze aplikace

### Feature Request

Máš nápad na novou funkci?
- **GitHub Discussions**: [github.com/yourusername/flutter-todo/discussions](https://github.com/yourusername/flutter-todo/discussions)
- Popište use case a důvod, proč by funkce byla užitečná

---

## 📜 Licence a autorská práva

**TODO App** © 2025

Vyvinuto s pomocí [Claude Code](https://claude.com/claude-code) by Anthropic.

**Licence:** MIT License

**Použité technologie:**
- [Flutter](https://flutter.dev/) - UI framework
- [BLoC](https://bloclibrary.dev/) - State management
- [SQLite](https://pub.dev/packages/sqflite) - Local database
- [OpenRouter](https://openrouter.ai) - AI API gateway

---

## 📚 Další zdroje

### Interní dokumentace (pro vývojáře)

- [CLAUDE.md](CLAUDE.md) - Architektura a best practices
- [bloc.md](bloc.md) - BLoC pattern guide
- [mapa-bloc.md](mapa-bloc.md) - Decision tree pro implementaci
- [brief.md](brief.md) - AI Brief implementační plán

### Externí odkazy

- [Flutter dokumentace](https://docs.flutter.dev/)
- [BLoC pattern tutorial](https://bloclibrary.dev/#/gettingstarted)
- [OpenRouter docs](https://openrouter.ai/docs)

---

## 🎓 Závěr

Gratulujeme! Dokončil jsi uživatelskou příručku TODO aplikace.

### Co dál?

1. **Vyzkoušej AI Brief** - nech AI prioritizovat úkoly
2. **Vytvoř Custom Views** - organizuj úkoly podle projektů
3. **Použij Pomodoro** - zvyš produktivitu
4. **Experimentuj s tagy** - najdi si svůj workflow

### Potřebuješ pomoct?

- **Interaktivní nápověda**: Klikni na **❓** ikonu v aplikaci
- **Průvodce**: Spusť znovu průvodce pro začátečníky (v Help stránce)
- **Kontakt**: Napiš na GitHub Issues nebo email

---

**Děkujeme, že používáš TODO App! 🚀**

*Hodně štěstí s produktivitou!* ✅
