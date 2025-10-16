# 📱 Flutter TODO App

Modern TODO application with AI-powered features, built with Flutter and BLoC architecture.

## ✨ Features

- ✅ **Task Management** - Create, edit, complete and delete tasks
- 🏷️ **Smart Tags** - Priority (🔴🟡🟢), deadlines (📅⏰), custom categories
- 🎨 **Multiple Themes** - Doom One, Monokai Pro, Dracula, etc.
- 🤖 **AI Integration** - Task splitting and motivational prompts (requires OpenRouter API)
- 📊 **Views & Filters** - Today, Week, Upcoming, Overdue
- 🔍 **Search & Sort** - Fast search with multiple sorting options
- 🎯 **Mobile-First UI** - Thumb zone optimized for one-handed use

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.0+)
- Android Studio / VS Code with Flutter plugin
- Android SDK (for Android builds)

### Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/flutter-todo.git
cd flutter-todo/todo
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the app:
```bash
flutter run
```

## 🤖 AI Features Setup (Optional)

The app includes AI-powered features:
- **Task Splitting** - Break down complex tasks into subtasks
- **Motivational Prompts** - Get AI-generated motivation for tasks

To enable AI features:

1. Get your **OpenRouter API key** from [openrouter.ai](https://openrouter.ai)

2. Open the app and navigate to **Settings → AI Settings**

3. Enter your API key and configure:
   - Model (default: `mistralai/mistral-medium-3.1`)
   - Temperature (0.0-2.0)
   - Max Tokens (100-2000)

4. (Optional) Create custom motivational prompts in **Settings → Motivační Prompty**

> **Note:** AI features require an active internet connection and will consume OpenRouter credits. The app works perfectly fine without AI features enabled.

## 🏗️ Architecture

This project follows **Feature-First + BLoC** architecture:

```
lib/
├── core/                   # Shared utilities, themes, services
├── features/              # Feature modules (BLoC pattern)
│   ├── todo_list/        # Main TODO feature
│   ├── ai_split/         # AI task splitting
│   ├── ai_motivation/    # AI motivational prompts
│   └── help/             # Help & onboarding
└── models/               # Shared data models
```

Each feature follows Clean Architecture principles:
- **Presentation**: UI (Pages, Widgets) + BLoC/Cubit
- **Domain**: Business logic (Entities, Use Cases)
- **Data**: Repositories, Data Sources

## 🛠️ Building for Release

### Android APK

```bash
flutter build apk --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

### Android App Bundle (for Google Play)

```bash
flutter build appbundle --release
```

Output: `build/app/outputs/bundle/release/app-release.aab`

## 📚 Documentation

- [BLoC Architecture Guide](CLAUDE.md) - Detailed architecture documentation
- [Feature Implementation](mapa-bloc.md) - Decision tree for adding features
- [UI Design System](gui.md) - Mobile-first UI guidelines

## 🤝 Contributing

Contributions are welcome! Please read our contributing guidelines before submitting PRs.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Built with [Flutter](https://flutter.dev/)
- State management: [flutter_bloc](https://bloclibrary.dev/)
- Database: [sqflite](https://pub.dev/packages/sqflite)
- AI powered by [OpenRouter](https://openrouter.ai)

---

**Note:** This project was developed with assistance from [Claude Code](https://claude.com/claude-code) by Anthropic.
