import 'package:equatable/equatable.dart';
import 'family_role.dart';
import 'gender.dart';
import 'age_category.dart';

/// Člen rodiny
class FamilyMember extends Equatable {
  final int? id;
  final String userId;
  final String firstName;
  final String lastName;
  final DateTime birthDate;
  final String? nameDay;
  final String? nickname;
  final Gender gender;
  final FamilyRole role;
  final String? relationshipDescription;
  final String? personalityTraits;
  final String? hobbies;
  final String? occupation;
  final String? otherNotes;
  final String? silneStranky;
  final String? slabeStranky;
  final DateTime createdAt;
  final DateTime updatedAt;

  const FamilyMember({
    this.id,
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.birthDate,
    this.nameDay,
    this.nickname,
    required this.gender,
    required this.role,
    this.relationshipDescription,
    this.personalityTraits,
    this.hobbies,
    this.occupation,
    this.otherNotes,
    this.silneStranky,
    this.slabeStranky,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Věk
  int get age {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  /// Věková kategorie (odvozená z age)
  AgeCategory get ageCategory => AgeCategory.fromAge(age);

  /// Dny do narozenin
  int get daysUntilBirthday {
    final now = DateTime.now();
    final thisYear = DateTime(now.year, birthDate.month, birthDate.day);
    final nextYear = DateTime(now.year + 1, birthDate.month, birthDate.day);

    final target = thisYear.isAfter(now) ? thisYear : nextYear;
    return target.difference(now).inDays;
  }

  /// Z databázové mapy
  factory FamilyMember.fromMap(Map<String, dynamic> map) {
    return FamilyMember(
      id: map['id'] as int?,
      userId: map['user_id'] as String? ?? 'default',
      firstName: map['first_name'] as String,
      lastName: map['last_name'] as String,
      birthDate: DateTime.fromMillisecondsSinceEpoch(map['birth_date'] as int),
      nameDay: map['name_day'] as String?,
      nickname: map['nickname'] as String?,
      gender: Gender.fromString(map['gender'] as String? ?? 'other'),
      role: FamilyRole.fromString(map['role'] as String),
      relationshipDescription: map['relationship_description'] as String?,
      personalityTraits: map['personality_traits'] as String?,
      hobbies: map['hobbies'] as String?,
      occupation: map['occupation'] as String?,
      otherNotes: map['other_notes'] as String?,
      silneStranky: map['silne_stranky'] as String?,
      slabeStranky: map['slabe_stranky'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
    );
  }

  /// Do databázové mapy
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'first_name': firstName,
      'last_name': lastName,
      'birth_date': birthDate.millisecondsSinceEpoch,
      'name_day': nameDay,
      'nickname': nickname,
      'gender': gender.name,
      'role': role.name,
      'relationship_description': relationshipDescription,
      'personality_traits': personalityTraits,
      'hobbies': hobbies,
      'occupation': occupation,
      'other_notes': otherNotes,
      'silne_stranky': silneStranky,
      'slabe_stranky': slabeStranky,
      'age_category': ageCategory.name, // Automaticky vypočítaná kategorie
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  /// CopyWith pro immutability
  FamilyMember copyWith({
    int? id,
    String? userId,
    String? firstName,
    String? lastName,
    DateTime? birthDate,
    String? nameDay,
    String? nickname,
    Gender? gender,
    FamilyRole? role,
    String? relationshipDescription,
    String? personalityTraits,
    String? hobbies,
    String? occupation,
    String? otherNotes,
    String? silneStranky,
    String? slabeStranky,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FamilyMember(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      birthDate: birthDate ?? this.birthDate,
      nameDay: nameDay ?? this.nameDay,
      nickname: nickname ?? this.nickname,
      gender: gender ?? this.gender,
      role: role ?? this.role,
      relationshipDescription:
          relationshipDescription ?? this.relationshipDescription,
      personalityTraits: personalityTraits ?? this.personalityTraits,
      hobbies: hobbies ?? this.hobbies,
      occupation: occupation ?? this.occupation,
      otherNotes: otherNotes ?? this.otherNotes,
      silneStranky: silneStranky ?? this.silneStranky,
      slabeStranky: slabeStranky ?? this.slabeStranky,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        firstName,
        lastName,
        birthDate,
        nameDay,
        nickname,
        gender,
        role,
        relationshipDescription,
        personalityTraits,
        hobbies,
        occupation,
        otherNotes,
        silneStranky,
        slabeStranky,
        createdAt,
        updatedAt,
      ];
}
