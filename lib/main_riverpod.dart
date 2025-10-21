import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/theme/doom_one_theme.dart';
import 'core/utils/app_logger.dart';
import 'core/providers/core_providers.dart';
import 'core/providers/repository_providers.dart';
import 'core/connectivity/providers/connectivity_provider.dart';
import 'features/settings/presentation/providers/settings_provider.dart';
import 'features/todo_list/presentation/providers/todo_provider.dart';
import 'features/notes/presentation/providers/notes_provider.dart';
import 'features/profile/presentation/providers/profile_provider.dart';
import 'features/pomodoro/presentation/providers/pomodoro_provider.dart';
import 'features/ai_motivation/presentation/providers/motivation_provider.dart';
import 'features/ai_split/presentation/providers/ai_split_provider.dart';
import 'features/ai_prank/presentation/providers/prank_provider.dart';
import 'pages/main_page.dart';
import 'core/services/clipboard_monitor_service.dart';
import 'core/widgets/smart_clipboard_dialog.dart';
import 'services/tag_service.dart';

void main() async {
  // Ensure Flutter bindings
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializovat lokalizaci pro date formatting (měsíce, dny v češtině)
  await initializeDateFormatting('cs_CZ', null);
  AppLogger.info('✅ Date formatting initialized (cs_CZ)');

  AppLogger.info('🚀 TODO App started (Riverpod edition)');

  // Inicializovat FFI pro desktop platformy (Windows, Linux, macOS)
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Inicializovat TagService (načíst definice tagů do cache)
  await TagService().init();
  AppLogger.info('✅ TagService initialized');

  runApp(
    // ProviderScope je root pro Riverpod aplikaci
    const ProviderScope(
      child: TodoApp(),
    ),
  );
}

class TodoApp extends ConsumerStatefulWidget {
  const TodoApp({super.key});

  @override
  ConsumerState<TodoApp> createState() => _TodoAppState();
}

class _TodoAppState extends ConsumerState<TodoApp> {
  late final ClipboardMonitorService _clipboardMonitor;
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();

    // Inicializovat clipboard monitor
    _clipboardMonitor = ClipboardMonitorService();
    _clipboardMonitor.onActionableContentDetected = (detected) {
      // Získat context z navigátoru
      final context = _navigatorKey.currentContext;
      if (context != null && context.mounted) {
        // Zobrazit Smart Clipboard Dialog
        showSmartClipboardDialog(context, detected);
      }
    };

    // Spustit monitoring
    _clipboardMonitor.start();
    AppLogger.info('✅ ClipboardMonitor started');
  }

  @override
  void dispose() {
    _clipboardMonitor.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch settings provider pro získání aktuálního tématu
    final settingsAsync = ref.watch(settingsProvider);

    return settingsAsync.when(
      data: (settings) {
        return MaterialApp(
          title: 'TODO Doom',
          theme: settings.currentTheme,
          navigatorKey: _navigatorKey, // Pro přístup k contextu z clipboard monitoru
          locale: const Locale('cs', 'CZ'), // Česká lokalizace
          home: const MainPage(),
        );
      },
      loading: () {
        // Zobrazit loading screen při načítání nastavení
        return MaterialApp(
          title: 'TODO Doom',
          theme: DoomOneTheme.darkTheme,
          home: const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          ),
        );
      },
      error: (error, stack) {
        // Zobrazit error screen při chybě
        AppLogger.error('Chyba při načítání nastavení: $error');
        return MaterialApp(
          title: 'TODO Doom',
          theme: DoomOneTheme.darkTheme,
          home: Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Chyba při načítání nastavení',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    error.toString(),
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
