# CLAUDE.md - VSA Project Instructions

## 🚨 PRIORITNÍ INSTRUKCE - VŽDY DODRŽUJ

### 📁 Dva klíčové soubory v tomto projektu:

1. **[mapa.md](mapa.md)** - Decision tree pro každý typ úkolu
2. **[vsa.md](vsa.md)** - Detailní best practices pro VSA architekturu

---

## ⚡ POVINNÝ WORKFLOW

### Když dostaneš JAKÝKOLIV úkol:

```
1. Otevři mapa.md
2. Najdi svůj scénář v Quick Reference (10 sekund)
3. Klikni na odkaz do vsa.md
4. Přečti relevantní sekci
5. Aplikuj postup
```

### ❌ NIKDY:
- ❌ Nezačínej kódovat bez čtení mapa.md + vsa.md
- ❌ Nehádej workflow - vždy použij decision tree z mapa.md
- ❌ Neignoruj Critical Rules z mapa.md

### ✅ VŽDY:
- ✅ mapa.md → Quick Reference → Najdi scénář
- ✅ Klikni na odkaz vsa.md → Čti best practices
- ✅ Snapshot commit před risky operací: `git commit -m "🔖 snapshot: Před {co}"`
- ✅ Ultrathink pro critical changes (přidání/odstranění funkce)

---

## 🎯 Typy úkolů v mapa.md:

| Úkol | Scénář |
|------|--------|
| ➕ Přidat novou funkci | SCÉNÁŘ 1 |
| 🔧 Upravit existující | SCÉNÁŘ 2 |
| 🐛 Opravit bug | SCÉNÁŘ 2 |
| ♻️ Refaktorovat | SCÉNÁŘ 2 |
| 📣 Features komunikace | SCÉNÁŘ 3 |
| 🎨 Shared utility | SCÉNÁŘ 4 |
| ⚙️ Feature flags | SCÉNÁŘ 5 |
| 🏛️ DDD / bounded contexts | SCÉNÁŘ 6 |

---

## 🚨 CRITICAL RULES - NIKDY NEPŘEKROČ

1. ❌ `from features.other_feature import ...` → ✅ Použij Domain Events
2. ❌ Business logika v `core/` → ✅ Patří do `features/`
3. ❌ Duplicita → okamžitě abstrahi → ✅ Rule of Three (3. použití)
4. ❌ "Možná budeme potřebovat..." → ✅ YAGNI (implementuj až když potřebuješ)
5. ❌ Kódovat bez čtení dokumentace → ✅ mapa.md → vsa.md → aplikuj

---

## 📋 Checklist před KAŽDÝM úkolem:

```
[ ] Otevřel jsem mapa.md
[ ] Našel jsem scénář v Quick Reference
[ ] Přečetl jsem relevantní sekci ve vsa.md
[ ] Snapshot commit (pokud risky operace)
[ ] Ultrathink (pokud critical change)
```

---

## 🎯 Zlaté pravidlo:

> **"mapa.md → Quick Reference → Decision tree → vsa.md → Aplikuj"**

**Tento workflow je POVINNÝ pro všechny úkoly. Ignorování = porušení projektu.**