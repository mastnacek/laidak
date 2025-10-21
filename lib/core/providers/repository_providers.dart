import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/todo_list/data/repositories/todo_repository_impl.dart';
import '../../features/todo_list/domain/repositories/todo_repository.dart';
import '../../features/profile/data/repositories/profile_repository_impl.dart';
import '../../features/profile/domain/repositories/profile_repository.dart';
import '../../features/ai_motivation/data/repositories/motivation_repository_impl.dart';
import '../../features/ai_motivation/domain/repositories/motivation_repository.dart';
import '../../features/ai_split/data/repositories/ai_split_repository_impl.dart';
import '../../features/ai_split/domain/repositories/ai_split_repository.dart';
import '../../features/ai_split/data/datasources/openrouter_datasource.dart';
import '../../features/ai_brief/data/repositories/ai_brief_repository_impl.dart';
import '../../features/ai_brief/domain/repositories/ai_brief_repository.dart';
import '../../features/ai_brief/data/datasources/brief_ai_datasource.dart';
import '../../features/ai_brief/data/services/brief_settings_service.dart';
import '../../features/markdown_export/domain/services/markdown_formatter_service.dart';
import '../../features/markdown_export/domain/services/file_writer_service.dart';
import '../../features/markdown_export/domain/repositories/markdown_export_repository.dart';
import '../../features/markdown_export/data/repositories/markdown_export_repository_impl.dart';
import '../../features/ai_prank/data/repositories/prank_repository_impl.dart';
import '../../features/ai_prank/domain/repositories/prank_repository.dart';
import 'core_providers.dart';

/// === TODO REPOSITORY ===

final todoRepositoryProvider = Provider<TodoRepository>((ref) {
  final db = ref.watch(databaseHelperProvider);
  return TodoRepositoryImpl(db);
});

/// === PROFILE REPOSITORY ===

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final db = ref.watch(databaseHelperProvider);
  return ProfileRepositoryImpl(db);
});

/// === AI MOTIVATION REPOSITORY ===

final motivationRepositoryProvider = Provider<MotivationRepository>((ref) {
  final db = ref.watch(databaseHelperProvider);
  return MotivationRepositoryImpl(db);
});

/// === AI SPLIT REPOSITORY ===

final openRouterDataSourceProvider = Provider<OpenRouterDataSource>((ref) {
  final httpClient = ref.watch(httpClientProvider);
  return OpenRouterDataSource(client: httpClient);
});

final aiSplitRepositoryProvider = Provider<AiSplitRepository>((ref) {
  final dataSource = ref.watch(openRouterDataSourceProvider);
  final db = ref.watch(databaseHelperProvider);
  return AiSplitRepositoryImpl(
    dataSource: dataSource,
    db: db,
  );
});

/// === AI BRIEF REPOSITORY ===

final briefAiDatasourceProvider = Provider<BriefAiDatasource>((ref) {
  return BriefAiDatasource();
});

final briefSettingsServiceProvider = Provider<BriefSettingsService>((ref) {
  final db = ref.watch(databaseHelperProvider);
  return BriefSettingsService(db);
});

final aiBriefRepositoryProvider = Provider<AiBriefRepository>((ref) {
  final db = ref.watch(databaseHelperProvider);
  final aiDatasource = ref.watch(briefAiDatasourceProvider);
  return AiBriefRepositoryImpl(
    db: db,
    aiDatasource: aiDatasource,
  );
});

/// === MARKDOWN EXPORT REPOSITORY ===

final markdownFormatterServiceProvider = Provider<MarkdownFormatterService>((ref) {
  return MarkdownFormatterService();
});

final fileWriterServiceProvider = Provider<FileWriterService>((ref) {
  return FileWriterService();
});

final markdownExportRepositoryProvider = Provider<MarkdownExportRepository>((ref) {
  final formatter = ref.watch(markdownFormatterServiceProvider);
  final fileWriter = ref.watch(fileWriterServiceProvider);
  final todoRepository = ref.watch(todoRepositoryProvider);
  final db = ref.watch(databaseHelperProvider);

  return MarkdownExportRepositoryImpl(
    formatter: formatter,
    fileWriter: fileWriter,
    todoRepository: todoRepository,
    db: db,
  );
});

/// === AI PRANK REPOSITORY ===

final prankRepositoryProvider = Provider<PrankRepository>((ref) {
  final db = ref.watch(databaseHelperProvider);
  return PrankRepositoryImpl(db);
});
