/// Věková kategorie uživatele
enum AgeCategory {
  toddler('Batolátko', '👶'),
  child('Dítě', '🧒'),
  teenager('Teenager', '🧑'),
  adult('Dospělý', '👨'),
  senior('Senior', '👴');

  final String czechName;
  final String emoji;

  const AgeCategory(this.czechName, this.emoji);

  /// Vypočítat věkovou kategorii podle věku
  static AgeCategory fromAge(int age) {
    if (age <= 5) return AgeCategory.toddler;
    if (age <= 11) return AgeCategory.child;
    if (age <= 17) return AgeCategory.teenager;
    if (age <= 64) return AgeCategory.adult;
    return AgeCategory.senior;
  }

  /// Z databázového stringu
  static AgeCategory? fromString(String? value) {
    if (value == null || value.isEmpty) return null;
    return AgeCategory.values.firstWhere(
      (e) => e.name == value,
      orElse: () => AgeCategory.child, // Default fallback
    );
  }
}
