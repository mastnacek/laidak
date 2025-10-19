/// Enum pro typ opakování úkolu
///
/// Používá se v RecurrenceRule pro definici frekvence opakování.
enum RecurType {
  /// Denně (každý den)
  daily,

  /// Týdně (každý týden, konkrétní den v týdnu)
  weekly,

  /// Měsíčně (každý měsíc, konkrétní den v měsíci)
  monthly,

  /// Ročně (každý rok)
  yearly,
}

/// Extension pro konverzi mezi enum a databázovým řetězcem
extension RecurTypeExtension on RecurType {
  /// Konverze enum → databázový řetězec
  String toDbString() {
    switch (this) {
      case RecurType.daily:
        return 'daily';
      case RecurType.weekly:
        return 'weekly';
      case RecurType.monthly:
        return 'monthly';
      case RecurType.yearly:
        return 'yearly';
    }
  }

  /// Konverze enum → uživatelsky přívětivý název (čeština)
  String get displayName {
    switch (this) {
      case RecurType.daily:
        return 'Denně';
      case RecurType.weekly:
        return 'Týdně';
      case RecurType.monthly:
        return 'Měsíčně';
      case RecurType.yearly:
        return 'Ročně';
    }
  }

  /// Konverze enum → zkratka pro tag syntax (d/t/m/r)
  String get tagSuffix {
    switch (this) {
      case RecurType.daily:
        return 'd';
      case RecurType.weekly:
        return 't'; // týdně
      case RecurType.monthly:
        return 'm'; // měsíčně
      case RecurType.yearly:
        return 'r'; // ročně
    }
  }
}

/// Helper metody pro konverzi z databázového řetězce na enum
extension RecurTypeFromString on String {
  /// Konverze databázový řetězec → enum
  RecurType? toRecurType() {
    switch (toLowerCase()) {
      case 'daily':
        return RecurType.daily;
      case 'weekly':
        return RecurType.weekly;
      case 'monthly':
        return RecurType.monthly;
      case 'yearly':
        return RecurType.yearly;
      default:
        return null;
    }
  }
}

/// Helper metody pro konverzi z tag suffix na enum
extension RecurTypeFromTagSuffix on String {
  /// Konverze tag suffix (d/t/m/r) → enum
  RecurType? fromTagSuffix() {
    switch (toLowerCase()) {
      case 'd':
        return RecurType.daily;
      case 't':
        return RecurType.weekly;
      case 'm':
        return RecurType.monthly;
      case 'r':
        return RecurType.yearly;
      default:
        return null;
    }
  }
}
