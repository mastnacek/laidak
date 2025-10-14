import 'package:equatable/equatable.dart';
import 'custom_notes_view.dart';

/// Konfigurace Notes Views (built-in + custom)
///
/// Obsahuje:
/// - Built-in views toggles (All Notes, Recent Notes)
/// - Seznam custom views (tag-based filtering)
class NotesViewConfig extends Equatable {
  /// Zapnout/vypnout "Všechny poznámky"
  final bool showAllNotes;

  /// Zapnout/vypnout "Poslední týden" (Recent)
  final bool showRecentNotes;

  /// Seznam custom views (tag-based filters)
  final List<CustomNotesView> customViews;

  const NotesViewConfig({
    this.showAllNotes = true,
    this.showRecentNotes = true,
    this.customViews = const [],
  });

  /// Default konfigurace (všechny built-in views zapnuté, žádné custom views)
  factory NotesViewConfig.defaultConfig() {
    return const NotesViewConfig(
      showAllNotes: true,
      showRecentNotes: true,
      customViews: [],
    );
  }

  /// CopyWith pro immutable updates
  NotesViewConfig copyWith({
    bool? showAllNotes,
    bool? showRecentNotes,
    List<CustomNotesView>? customViews,
  }) {
    return NotesViewConfig(
      showAllNotes: showAllNotes ?? this.showAllNotes,
      showRecentNotes: showRecentNotes ?? this.showRecentNotes,
      customViews: customViews ?? this.customViews,
    );
  }

  @override
  List<Object?> get props => [showAllNotes, showRecentNotes, customViews];

  @override
  String toString() {
    return 'NotesViewConfig(showAllNotes: $showAllNotes, showRecentNotes: $showRecentNotes, customViews: ${customViews.length})';
  }
}
