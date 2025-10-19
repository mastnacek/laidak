import 'package:equatable/equatable.dart';
import 'dart:convert';
import 'gender.dart';
import 'age_category.dart';

/// Profil uživatele aplikace (dítě)
class UserProfile extends Equatable {
  final int? id;
  final String userId;
  final String firstName;
  final String lastName;
  final DateTime birthDate;
  final String? nameDay;
  final String? nickname;
  final Gender gender;
  final List<String> hobbies;
  final String aboutMe;
  final String? silneStranky;
  final String? slabeStranky;
  final int completedTasksCount; // ✅ Counter pro střídání prank/good deed
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserProfile({
    this.id,
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.birthDate,
    this.nameDay,
    this.nickname,
    required this.gender,
    required this.hobbies,
    required this.aboutMe,
    this.silneStranky,
    this.slabeStranky,
    this.completedTasksCount = 0, // ✅ Default 0
    required this.createdAt,
    required this.updatedAt,
  });

  /// Věk (odvozený z birthDate)
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

  /// AI briefing style podle věku
  String get ageBriefingStyle {
    if (age <= 8) return 'playful';      // Hravý, jednoduché věty
    if (age <= 12) return 'encouraging'; // Povzbuzující, více informací
    return 'teen';                       // Pro teenagery, cool tone
  }

  /// Z databázové mapy
  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] as int?,
      userId: map['user_id'] as String? ?? 'default',
      firstName: map['first_name'] as String,
      lastName: map['last_name'] as String,
      birthDate: DateTime.fromMillisecondsSinceEpoch(map['birth_date'] as int),
      nameDay: map['name_day'] as String?,
      nickname: map['nickname'] as String?,
      gender: Gender.fromString(map['gender'] as String? ?? 'other'),
      hobbies: map['hobbies'] != null && (map['hobbies'] as String).isNotEmpty
          ? (jsonDecode(map['hobbies'] as String) as List<dynamic>)
              .cast<String>()
          : [],
      aboutMe: map['about_me'] as String? ?? '',
      silneStranky: map['silne_stranky'] as String?,
      slabeStranky: map['slabe_stranky'] as String?,
      completedTasksCount: map['completed_tasks_count'] as int? ?? 0, // ✅ Load z DB
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
      'hobbies': jsonEncode(hobbies),
      'about_me': aboutMe,
      'silne_stranky': silneStranky,
      'slabe_stranky': slabeStranky,
      'completed_tasks_count': completedTasksCount, // ✅ Save do DB
      'age_category': ageCategory.name, // Automaticky vypočítaná kategorie
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  /// CopyWith pro immutability
  UserProfile copyWith({
    int? id,
    String? userId,
    String? firstName,
    String? lastName,
    DateTime? birthDate,
    String? nameDay,
    String? nickname,
    Gender? gender,
    List<String>? hobbies,
    String? aboutMe,
    String? silneStranky,
    String? slabeStranky,
    int? completedTasksCount, // ✅ Přidáno do copyWith
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      birthDate: birthDate ?? this.birthDate,
      nameDay: nameDay ?? this.nameDay,
      nickname: nickname ?? this.nickname,
      gender: gender ?? this.gender,
      hobbies: hobbies ?? this.hobbies,
      aboutMe: aboutMe ?? this.aboutMe,
      silneStranky: silneStranky ?? this.silneStranky,
      slabeStranky: slabeStranky ?? this.slabeStranky,
      completedTasksCount: completedTasksCount ?? this.completedTasksCount, // ✅ Copy
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
        hobbies,
        aboutMe,
        silneStranky,
        slabeStranky,
        completedTasksCount, // ✅ Přidáno do Equatable props
        createdAt,
        updatedAt,
      ];
}
