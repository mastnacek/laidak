import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:just_audio_media_kit/just_audio_media_kit.dart';
import 'core/theme/doom_one_theme.dart';
import 'core/observers/simple_bloc_observer.dart';
import 'core/utils/app_logger.dart';
import 'features/settings/presentation/cubit/settings_cubit.dart';
import 'features/settings/presentation/cubit/settings_state.dart';
import 'features/todo_list/presentation/bloc/todo_list_bloc.dart';
import 'features/todo_list/presentation/bloc/todo_list_event.dart';
import 'pages/main_page.dart';
import 'features/todo_list/data/repositories/todo_repository_impl.dart';
import 'features/ai_motivation/presentation/cubit/motivation_cubit.dart';
import 'features/ai_motivation/data/repositories/motivation_repository_impl.dart';
import 'features/ai_split/presentation/cubit/ai_split_cubit.dart';
import 'features/ai_split/data/repositories/ai_split_repository_impl.dart';
import 'features/ai_split/data/datasources/openrouter_datasource.dart';
import 'features/ai_brief/data/repositories/ai_brief_repository_impl.dart';
import 'features/ai_brief/data/datasources/brief_ai_datasource.dart';
import 'features/ai_brief/data/services/brief_settings_service.dart';
import 'core/services/database_helper.dart';
import 'core/services/clipboard_monitor_service.dart';
import 'core/widgets/smart_clipboard_dialog.dart';
import 'services/tag_service.dart';

void main() async {
  // Ensure Flutter bindings
  WidgetsFlutterBinding.ensureInitialized();

  // 🔧 Registrovat BlocObserver pro debugging
  Bloc.observer = SimpleBlocObserver();

  AppLogger.info('🚀 TODO App started');

  // Inicializovat FFI pro desktop platformy (Windows, Linux, macOS)
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Inicializovat just_audio_media_kit pro Windows/Linux audio podporu
  if (Platform.isWindows || Platform.isLinux) {
    JustAudioMediaKit.ensureInitialized();
    AppLogger.info('✅ JustAudioMediaKit initialized (Windows/Linux)');
  }

  // Inicializovat TagService (načíst definice tagů do cache)
  await TagService().init();
  AppLogger.info('✅ TagService initialized');

  // Inicializovat databázi
  final db = DatabaseHelper();

  // Inicializovat HTTP client pro AI split
  final httpClient = http.Client();

  // Inicializovat AI Split dependencies
  final openRouterDataSource = OpenRouterDataSource(client: httpClient);
  final aiSplitRepository = AiSplitRepositoryImpl(
    dataSource: openRouterDataSource,
    db: db,
  );

  // Inicializovat AI Brief dependencies
  final briefAiDatasource = BriefAiDatasource();
  final aiBriefRepository = AiBriefRepositoryImpl(
    db: db,
    aiDatasource: briefAiDatasource,
  );
  final briefSettingsService = BriefSettingsService(db);

  runApp(
    MultiBlocProvider(
      providers: [
        // SettingsCubit pro themes
        BlocProvider(
          create: (_) => SettingsCubit(db),
        ),
        // TodoListBloc pro todo list management
        BlocProvider(
          create: (_) => TodoListBloc(
            TodoRepositoryImpl(db),
            aiBriefRepository,
            briefSettingsService,
          )..add(const LoadTodosEvent()), // Automaticky načíst todos
        ),
        // MotivationCubit pro AI motivaci
        BlocProvider(
          create: (_) => MotivationCubit(MotivationRepositoryImpl(db)),
        ),
        // AiSplitCubit pro AI rozdělení úkolů
        BlocProvider(
          create: (_) => AiSplitCubit(repository: aiSplitRepository),
        ),
      ],
      child: const TodoApp(),
    ),
  );
}

class TodoApp extends StatefulWidget {
  const TodoApp({super.key});

  @override
  State<TodoApp> createState() => _TodoAppState();
}

class _TodoAppState extends State<TodoApp> {
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
    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, state) {
        // Získat theme ze state nebo použít fallback
        final theme = state is SettingsLoaded
            ? state.currentTheme
            : DoomOneTheme.darkTheme; // Fallback při načítání

        return MaterialApp(
          title: 'TODO Doom',
          theme: theme,
          navigatorKey: _navigatorKey, // Pro přístup k contextu z clipboard monitoru
          home: const MainPage(),
        );
      },
    );
  }
}
