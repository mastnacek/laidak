/// Enum pro role členů rodiny
enum FamilyRole {
  mother('Mamka'),
  father('Taťka'),
  brother('Bratr'),
  sister('Sestra'),
  grandmother('Babička'),
  grandfather('Děda'),
  aunt('Teta'),
  uncle('Strýc'),
  cousin('Bratranec/Sestřenice'),
  niece('Neteř'),
  nephew('Synovec'),
  stepmother('Nevlastní matka'),
  stepfather('Nevlastní otec'),
  stepbrother('Nevlastní bratr'),
  stepsister('Nevlastní sestra'),
  greatGrandmother('Prababička'),
  greatGrandfather('Praděda'),
  partner('Partner/ka'),
  other('Jiný');

  final String displayName;
  const FamilyRole(this.displayName);

  /// Parse z databázového stringu
  static FamilyRole fromString(String value) {
    return FamilyRole.values.firstWhere(
      (role) => role.name == value,
      orElse: () => FamilyRole.other,
    );
  }
}
