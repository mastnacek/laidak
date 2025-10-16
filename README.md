# lAidak 🤖

> **AI asistent pro chytré lajdáky** - Motivuje, rozděluje úkoly a radí jak dosáhnout cílů

[![Flutter](https://img.shields.io/badge/Flutter-3.9.2-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.9.2-0175C2?logo=dart)](https://dart.dev)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

---

## 🎯 Co je lAidak?

**lAidak** je inteligentní produktivní asistent, který ti pomůže dosáhnout cílů - i když jsi trochu lajdák! 😄

Kombinuje klasické TODO seznamy, poznámky a Pomodoro timer s **AI-powered funkcemi**, které tě motivují, rozdělují velké úkoly na menší kroky a dávají ti rady jak postupovat.

### ✨ Hlavní AI funkce:

- 🤖 **AI Motivátor** - personalizované motivační texty (s TTS!)
- 🧠 **AI Brief** - inteligentní prioritizace úkolů
- ✂️ **AI Task Split** - automatické rozdělení velkých úkolů na podúkoly
- 💬 **AI Chat** - rady a doporučení k řešení problémů

---

## 📱 Funkce

### 🎯 Úkoly (Tasks)
- ✅ Smart tagy s custom oddělovači (\`*tag*\`, \`*dnes*\`, \`*a*\`)
- 📊 Prioritizace (A, B, C) + due dates
- 🔍 Fulltext search (FTS5 na Androidu)
- 📅 Kalendář s long-press pro rychlé přidání
- 📈 Custom Agenda views (Today, Week, Overdue, Custom filters)
- 🏷️ Tag autocomplete při psaní

### 📝 Poznámky (Notes)
- 📁 PARA organizace (Projects, Areas, Resources, Archives)
- 🔗 Bidirectional linking mezi poznámkami
- 🏷️ Stejný tag systém jako TODO
- 📤 Markdown export

### ⏱️ Pomodoro Timer
- ⏰ Konfigurovatelné intervaly
- 📳 Vibrace při dokončení
- 📊 Sledování produktivity

### 🤖 AI Asistent
- **Motivátor**: Generuje personalizované motivační texty podle tvých úkolů
- **Brief**: AI vybere top 3 úkoly + key insights + motivation
- **Task Split**: Rozdělí velký úkol na konkrétní kroky
- **Chat**: Chatbot pro rady a doporučení

### 🎨 Vzhled
- 🌙 Doom One dark theme (Emacs inspirace)
- 🎨 Custom barevné tagy s glow efektem
- 📱 Mobile-first design (Easy Thumb Zone)

### 📤 Export
- 📄 Markdown export (tasks + notes)
- 💾 Storage Access Framework na Androidu
- 📁 Strukturované složky (tasks/, notes/)

---

## 🚀 Instalace

### Prerekvizity
- Flutter SDK 3.9.2+
- Dart 3.9.2+
- Android Studio / VS Code

### Build

\`\`\`bash
# Clone repository
git clone https://github.com/mastancek/laidak.git
cd laidak

# Install dependencies
flutter pub get

# Run na Android emulátoru
flutter run

# Produkční build
flutter build apk --release        # APK
flutter build appbundle --release  # App Bundle (pro Google Play)
\`\`\`

---

## 🛠️ Tech Stack

- **Framework**: Flutter 3.9.2
- **State Management**: BLoC pattern (flutter_bloc)
- **Database**: SQLite (sqflite) + FTS5 fulltext search
- **Architecture**: Clean Architecture + Feature-First
- **AI**: OpenRouter API (GPT-4, Claude, Llama)
- **TTS**: flutter_tts (Text-to-Speech)
- **Storage**: Storage Access Framework (Android)

---

## 📂 Struktura Projektu

\`\`\`
lib/
├── core/                      # Sdílený kód
│   ├── services/              # DatabaseHelper, ClipboardMonitor
│   ├── theme/                 # Doom One theme
│   └── utils/                 # AppLogger, helpers
├── features/                  # Feature-First organizace
│   ├── todo_list/             # TODO management
│   ├── notes/                 # Notes + PARA system
│   ├── calendar/              # Calendar integration
│   ├── pomodoro/              # Pomodoro timer
│   ├── ai_motivation/         # AI motivátor
│   ├── ai_brief/              # AI Brief
│   ├── ai_split/              # AI Task Split
│   └── settings/              # Nastavení
└── main.dart                  # Entry point
\`\`\`

---

## 🤝 Přispívání

Contributions jsou vítány! 🎉

1. Fork repository
2. Vytvoř feature branch (\`git checkout -b feature/amazing-feature\`)
3. Commit změny (\`git commit -m '✨ feat: Přidání amazing feature'\`)
4. Push do branchi (\`git push origin feature/amazing-feature\`)
5. Otevři Pull Request

---

## 📄 License

Tento projekt je licencován pod [MIT License](LICENSE).

---

## 👨‍💻 Autor

**Jaroslav Maštanec**
- GitHub: [@mastancek](https://github.com/mastancek)
- Email: mastnacek@gmail.com

---

## 🙏 Poděkování

- [Flutter](https://flutter.dev) - Amazing framework
- [OpenRouter](https://openrouter.ai) - AI API access
- [Doom Emacs](https://github.com/doomemacs/doomemacs) - Theme inspirace

---

**🍺 Užij si produktivitu... i když jsi lajdák!** 😄
