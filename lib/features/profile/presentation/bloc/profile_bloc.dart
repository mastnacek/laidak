import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/entities/family_member.dart';
import 'profile_event.dart';
import 'profile_state.dart';

/// ProfileBloc - Business logika pro profil
class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final ProfileRepository _repository;

  ProfileBloc(this._repository) : super(ProfileInitial()) {
    on<LoadProfileEvent>(_onLoadProfile);
    on<SaveUserProfileEvent>(_onSaveUserProfile);
    on<AddFamilyMemberEvent>(_onAddFamilyMember);
    on<UpdateFamilyMemberEvent>(_onUpdateFamilyMember);
    on<DeleteFamilyMemberEvent>(_onDeleteFamilyMember);
    on<IncrementCompletedTasksEvent>(_onIncrementCompletedTasks);
  }

  /// Načíst profil + rodinu
  Future<void> _onLoadProfile(
    LoadProfileEvent event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileLoading());

    try {
      final userProfile = await _repository.getUserProfile(userId: event.userId);
      final familyMembers =
          await _repository.getAllFamilyMembers(userId: event.userId);

      emit(ProfileLoaded(
        userProfile: userProfile,
        familyMembers: familyMembers,
      ));
    } catch (e) {
      emit(ProfileError('Chyba při načítání profilu: $e'));
    }
  }

  /// Vytvořit/Aktualizovat UserProfile
  Future<void> _onSaveUserProfile(
    SaveUserProfileEvent event,
    Emitter<ProfileState> emit,
  ) async {
    // Fail Fast validace
    if (event.firstName.trim().isEmpty || event.lastName.trim().isEmpty) {
      emit(const ProfileError('Jméno a příjmení jsou povinné'));
      return;
    }

    try {
      final currentState = state;
      if (currentState is! ProfileLoaded) {
        emit(const ProfileError('Profil není načten'));
        return;
      }

      final now = DateTime.now();

      // Update nebo Create
      if (currentState.userProfile != null) {
        // Update existujícího profilu
        final updated = currentState.userProfile!.copyWith(
          firstName: event.firstName,
          lastName: event.lastName,
          birthDate: event.birthDate,
          nameDay: event.nameDay,
          nickname: event.nickname,
          gender: event.gender,
          hobbies: event.hobbies,
          aboutMe: event.aboutMe,
          silneStranky: event.silneStranky,
          slabeStranky: event.slabeStranky,
          updatedAt: now,
        );

        await _repository.updateUserProfile(updated);

        emit(currentState.copyWith(userProfile: updated));
      } else {
        // Create nového profilu
        final newProfile = UserProfile(
          userId: 'default',
          firstName: event.firstName,
          lastName: event.lastName,
          birthDate: event.birthDate,
          nameDay: event.nameDay,
          nickname: event.nickname,
          gender: event.gender,
          hobbies: event.hobbies,
          aboutMe: event.aboutMe,
          silneStranky: event.silneStranky,
          slabeStranky: event.slabeStranky,
          createdAt: now,
          updatedAt: now,
        );

        final id = await _repository.createUserProfile(newProfile);
        final created = newProfile.copyWith(id: id);

        emit(currentState.copyWith(userProfile: created));
      }
    } catch (e) {
      emit(ProfileError('Chyba při ukládání profilu: $e'));
    }
  }

  /// Přidat člena rodiny
  Future<void> _onAddFamilyMember(
    AddFamilyMemberEvent event,
    Emitter<ProfileState> emit,
  ) async {
    // Fail Fast validace
    if (event.firstName.trim().isEmpty || event.lastName.trim().isEmpty) {
      emit(const ProfileError('Jméno a příjmení jsou povinné'));
      return;
    }

    try {
      final currentState = state;
      if (currentState is! ProfileLoaded) {
        emit(const ProfileError('Profil není načten'));
        return;
      }

      final now = DateTime.now();

      final newMember = FamilyMember(
        userId: 'default',
        firstName: event.firstName,
        lastName: event.lastName,
        birthDate: event.birthDate,
        nameDay: event.nameDay,
        nickname: event.nickname,
        gender: event.gender,
        role: event.role,
        relationshipDescription: event.relationshipDescription,
        personalityTraits: event.personalityTraits,
        hobbies: event.hobbies,
        occupation: event.occupation,
        otherNotes: event.otherNotes,
        silneStranky: event.silneStranky,
        slabeStranky: event.slabeStranky,
        createdAt: now,
        updatedAt: now,
      );

      final id = await _repository.createFamilyMember(newMember);
      final created = newMember.copyWith(id: id);

      final updatedMembers = [created, ...currentState.familyMembers];

      emit(currentState.copyWith(familyMembers: updatedMembers));
    } catch (e) {
      emit(ProfileError('Chyba při přidávání člena rodiny: $e'));
    }
  }

  /// Aktualizovat člena rodiny
  Future<void> _onUpdateFamilyMember(
    UpdateFamilyMemberEvent event,
    Emitter<ProfileState> emit,
  ) async {
    // Fail Fast validace
    if (event.firstName.trim().isEmpty || event.lastName.trim().isEmpty) {
      emit(const ProfileError('Jméno a příjmení jsou povinné'));
      return;
    }

    try {
      final currentState = state;
      if (currentState is! ProfileLoaded) {
        emit(const ProfileError('Profil není načten'));
        return;
      }

      // Najít existujícího člena
      final existingMember = currentState.familyMembers
          .where((m) => m.id == event.id)
          .firstOrNull;

      if (existingMember == null) {
        emit(const ProfileError('Člen rodiny nebyl nalezen'));
        return;
      }

      final now = DateTime.now();

      // Vytvořit aktualizovaného člena (zachovat createdAt, updatovat updatedAt)
      final updatedMember = existingMember.copyWith(
        firstName: event.firstName,
        lastName: event.lastName,
        birthDate: event.birthDate,
        nameDay: event.nameDay,
        nickname: event.nickname,
        gender: event.gender,
        role: event.role,
        relationshipDescription: event.relationshipDescription,
        personalityTraits: event.personalityTraits,
        hobbies: event.hobbies,
        occupation: event.occupation,
        otherNotes: event.otherNotes,
        silneStranky: event.silneStranky,
        slabeStranky: event.slabeStranky,
        updatedAt: now,
      );

      // Uložit do DB
      await _repository.updateFamilyMember(updatedMember);

      // Aktualizovat state
      final updatedMembers = currentState.familyMembers
          .map((m) => m.id == event.id ? updatedMember : m)
          .toList();

      emit(currentState.copyWith(familyMembers: updatedMembers));
    } catch (e) {
      emit(ProfileError('Chyba při aktualizaci člena rodiny: $e'));
    }
  }

  /// Smazat člena rodiny
  Future<void> _onDeleteFamilyMember(
    DeleteFamilyMemberEvent event,
    Emitter<ProfileState> emit,
  ) async {
    try {
      final currentState = state;
      if (currentState is! ProfileLoaded) {
        emit(const ProfileError('Profil není načten'));
        return;
      }

      await _repository.deleteFamilyMember(event.memberId);

      final updatedMembers = currentState.familyMembers
          .where((m) => m.id != event.memberId)
          .toList();

      emit(currentState.copyWith(familyMembers: updatedMembers));
    } catch (e) {
      emit(ProfileError('Chyba při mazání člena rodiny: $e'));
    }
  }

  /// Inkrementovat počet dokončených úkolů (pro střídání prank/good deed)
  Future<void> _onIncrementCompletedTasks(
    IncrementCompletedTasksEvent event,
    Emitter<ProfileState> emit,
  ) async {
    try {
      final currentState = state;
      if (currentState is! ProfileLoaded) {
        return; // Tiše ignorovat pokud není načtený profil
      }

      final userProfile = currentState.userProfile;
      if (userProfile == null) {
        return; // Tiše ignorovat pokud není user profile
      }

      // Inkrementovat count
      final updatedProfile = userProfile.copyWith(
        completedTasksCount: userProfile.completedTasksCount + 1,
        updatedAt: DateTime.now(),
      );

      // Uložit do DB
      await _repository.updateUserProfile(updatedProfile);

      // Emit nový state
      emit(currentState.copyWith(userProfile: updatedProfile));
    } catch (e) {
      // Chybu logujeme, ale neemitujeme error state (nechtěme rušit flow dokončení úkolu)
      print('⚠️ Chyba při inkrementaci completed tasks: $e');
    }
  }
}
