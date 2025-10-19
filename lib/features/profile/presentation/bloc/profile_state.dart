import 'package:equatable/equatable.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/entities/family_member.dart';

/// Profile States
abstract class ProfileState extends Equatable {
  const ProfileState();

  @override
  List<Object?> get props => [];
}

/// Počáteční stav
class ProfileInitial extends ProfileState {}

/// Načítání
class ProfileLoading extends ProfileState {}

/// Data načtena
class ProfileLoaded extends ProfileState {
  final UserProfile? userProfile;
  final List<FamilyMember> familyMembers;

  const ProfileLoaded({
    this.userProfile,
    required this.familyMembers,
  });

  @override
  List<Object?> get props => [userProfile, familyMembers];

  /// CopyWith pro immutability
  ProfileLoaded copyWith({
    UserProfile? userProfile,
    List<FamilyMember>? familyMembers,
  }) {
    return ProfileLoaded(
      userProfile: userProfile ?? this.userProfile,
      familyMembers: familyMembers ?? this.familyMembers,
    );
  }
}

/// Chyba
class ProfileError extends ProfileState {
  final String message;

  const ProfileError(this.message);

  @override
  List<Object?> get props => [message];
}
