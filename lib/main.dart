import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'core/theme/doom_one_theme.dart';
import 'features/settings/presentation/cubit/settings_cubit.dart';
import 'features/settings/presentation/cubit/settings_state.dart';
import 'features/todo_list/presentation/bloc/todo_list_bloc.dart';
import 'features/todo_list/presentation/bloc/todo_list_event.dart';
import 'features/todo_list/presentation/pages/todo_list_page.dart';
import 'features/todo_list/data/repositories/todo_repository_impl.dart';
import 'features/ai_motivation/presentation/cubit/motivation_cubit.dart';
import 'features/ai_motivation/data/repositories/motivation_repository_impl.dart';
import 'features/ai_split/presentation/cubit/ai_split_cubit.dart';
import 'features/ai_split/data/repositories/ai_split_repository_impl.dart';
import 'features/ai_split/data/datasources/openrouter_datasource.dart';
import 'core/services/database_helper.dart';
import 'services/tag_service.dart';

void main() async {
  // Ensure Flutter bindings
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializovat FFI pro desktop platformy (Windows, Linux, macOS)
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Inicializovat TagService (načíst definice tagů do cache)
  await TagService().init();

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

  runApp(
    MultiBlocProvider(
      providers: [
        // SettingsCubit pro themes
        BlocProvider(
          create: (_) => SettingsCubit(db),
        ),
        // TodoListBloc pro todo list management
        BlocProvider(
          create: (_) => TodoListBloc(TodoRepositoryImpl(db))
            ..add(const LoadTodosEvent()), // Automaticky načíst todos
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

class TodoApp extends StatelessWidget {
  const TodoApp({super.key});

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
          home: const TodoListPage(),
        );
      },
    );
  }
}
