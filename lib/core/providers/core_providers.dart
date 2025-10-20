import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../services/database_helper.dart';
import '../services/clipboard_monitor_service.dart';
import '../../services/tag_service.dart';

/// Provider pro DatabaseHelper (singleton)
final databaseHelperProvider = Provider<DatabaseHelper>((ref) {
  return DatabaseHelper();
});

/// Provider pro HTTP client
final httpClientProvider = Provider<http.Client>((ref) {
  return http.Client();
});

/// Provider pro TagService (singleton)
final tagServiceProvider = Provider<TagService>((ref) {
  return TagService();
});

/// Provider pro ClipboardMonitorService
/// Note: Lifecycle je spravován v TodoApp widget
final clipboardMonitorServiceProvider = Provider<ClipboardMonitorService>((ref) {
  return ClipboardMonitorService();
});
