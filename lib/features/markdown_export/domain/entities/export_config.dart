import 'package:equatable/equatable.dart';
import 'export_format.dart';

/// Konfigurace pro markdown export
class ExportConfig extends Equatable {
  /// Cílová složka pro export (user-selected)
  final String? targetDirectory;

  /// Formát exportu (default / obsidian)
  final ExportFormat format;

  /// Exportovat TODO úkoly?
  final bool exportTodos;

  /// Exportovat Notes poznámky?
  final bool exportNotes;

  /// Automatický export při každém uložení?
  final bool autoExportOnSave;

  const ExportConfig({
    this.targetDirectory,
    this.format = ExportFormat.default_,
    this.exportTodos = true,
    this.exportNotes = true,
    this.autoExportOnSave = false,
  });

  /// Default config (žádná složka vybraná)
  const ExportConfig.initial()
      : targetDirectory = null,
        format = ExportFormat.default_,
        exportTodos = true,
        exportNotes = true,
        autoExportOnSave = false;

  /// CopyWith pro immutable updates
  ExportConfig copyWith({
    String? targetDirectory,
    bool clearTargetDirectory = false,
    ExportFormat? format,
    bool? exportTodos,
    bool? exportNotes,
    bool? autoExportOnSave,
  }) {
    return ExportConfig(
      targetDirectory: clearTargetDirectory
          ? null
          : (targetDirectory ?? this.targetDirectory),
      format: format ?? this.format,
      exportTodos: exportTodos ?? this.exportTodos,
      exportNotes: exportNotes ?? this.exportNotes,
      autoExportOnSave: autoExportOnSave ?? this.autoExportOnSave,
    );
  }

  /// Je export nakonfigurovaný? (target directory je nastaven)
  bool get isConfigured => targetDirectory != null && targetDirectory!.isNotEmpty;

  @override
  List<Object?> get props => [
        targetDirectory,
        format,
        exportTodos,
        exportNotes,
        autoExportOnSave,
      ];
}
