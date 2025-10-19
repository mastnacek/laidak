import 'package:equatable/equatable.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/entities/family_member.dart';
import '../../domain/entities/family_role.dart';
import '../../domain/entities/gender.dart';

/// Profile Events
abstract class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => [];
}

/// Načíst profil + rodinu
class LoadProfileEvent extends ProfileEvent {
  final String userId;

  const LoadProfileEvent({this.userId = 'default'});

  @override
  List<Object?> get props => [userId];
}

/// Vytvořit/Aktualizovat UserProfile
class SaveUserProfileEvent extends ProfileEvent {
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

  const SaveUserProfileEvent({
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
  });

  @override
  List<Object?> get props => [
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
      ];
}

/// Přidat člena rodiny
class AddFamilyMemberEvent extends ProfileEvent {
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

  const AddFamilyMemberEvent({
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
  });

  @override
  List<Object?> get props => [
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
      ];
}

/// Aktualizovat člena rodiny
class UpdateFamilyMemberEvent extends ProfileEvent {
  final int id; // ID existujícího člena
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

  const UpdateFamilyMemberEvent({
    required this.id,
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
  });

  @override
  List<Object?> get props => [
        id,
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
      ];
}

/// Smazat člena rodiny
class DeleteFamilyMemberEvent extends ProfileEvent {
  final int memberId;

  const DeleteFamilyMemberEvent(this.memberId);

  @override
  List<Object?> get props => [memberId];
}

/// Inkrementovat počet dokončených úkolů (pro střídání prank/good deed)
class IncrementCompletedTasksEvent extends ProfileEvent {
  const IncrementCompletedTasksEvent();

  @override
  List<Object?> get props => [];
}
