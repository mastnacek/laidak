/// Enum pro pohlaví
enum Gender {
  male('Muž'),
  female('Žena'),
  other('Jiné');

  final String displayName;
  const Gender(this.displayName);

  /// Parse z databázového stringu
  static Gender fromString(String value) {
    return Gender.values.firstWhere(
      (gender) => gender.name == value,
      orElse: () => Gender.other,
    );
  }
}
