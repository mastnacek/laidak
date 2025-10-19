/// FolderMode - Režim zobrazení poznámek (MILESTONE 4)
///
/// Začínáme s 3 základními folders:
/// - all: Všechny poznámky
/// - recent: Poslední týden
/// - favorites: Oblíbené (zatím prázdný - implementace později)
enum FolderMode {
  all,
  recent,
  favorites,
}

extension FolderModeExtension on FolderMode {
  /// Display name pro UI
  String get displayName {
    switch (this) {
      case FolderMode.all:
        return 'All Notes';
      case FolderMode.recent:
        return 'Recent';
      case FolderMode.favorites:
        return 'Favorites';
    }
  }

  /// Icon pro UI
  String get icon {
    switch (this) {
      case FolderMode.all:
        return '📝';
      case FolderMode.recent:
        return '🕐';
      case FolderMode.favorites:
        return '⭐';
    }
  }
}
