import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/providers/repository_providers.dart';
import '../../../../core/utils/app_logger.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/entities/family_member.dart';
import '../bloc/profile_state.dart';

part 'profile_provider.g.dart';

/// Riverpod Notifier pro správu User Profile
///
/// Nahrazuje původní ProfileBloc
/// Business logika pro profil + rodina
@riverpod
class Profile extends _$Profile {
  @override
  Future<ProfileState> build({String userId = 'default'}) async {
    // Načíst initial data
    try {
      final repository = ref.read(profileRepositoryProvider);
      final userProfile = await repository.getUserProfile(userId: userId);
      final familyMembers = await repository.getAllFamilyMembers(userId: userId);

      return ProfileLoaded(
        userProfile: userProfile,
        familyMembers: familyMembers,
      );
    } catch (e) {
      AppLogger.error('Chyba při načítání profilu: $e');
      return ProfileError(e.toString());
    }
  }

  /// Reload profil
  Future<void> loadProfile({String userId = 'default'}) async {
    state = const AsyncValue.loading();

    try {
      final repository = ref.read(profileRepositoryProvider);
      final userProfile = await repository.getUserProfile(userId: userId);
      final familyMembers = await repository.getAllFamilyMembers(userId: userId);

      state = AsyncValue.data(ProfileLoaded(
        userProfile: userProfile,
        familyMembers: familyMembers,
      ));

      AppLogger.debug('✅ Profil načten');
    } catch (e) {
      AppLogger.error('Chyba při načítání profilu: $e');
      state = AsyncValue.data(ProfileError(e.toString()));
    }
  }

  /// Vytvořit/Aktualizovat UserProfile
  Future<void> saveUserProfile({
    required String firstName,
    required String lastName,
    DateTime? birthDate,
    DateTime? nameDay,
    String? nickname,
    String? gender,
    List<String>? hobbies,
    String? aboutMe,
    List<String>? silneStranky,
    List<String>? slabeStranky,
  }) async {
    // Validace
    if (firstName.trim().isEmpty || lastName.trim().isEmpty) {
      state = AsyncValue.data(const ProfileError('Jméno a příjmení jsou povinné'));
      return;
    }

    final currentState = state.value;
    if (currentState is! ProfileLoaded) {
      state = AsyncValue.data(const ProfileError('Profil není načten'));
      return;
    }

    try {
      final repository = ref.read(profileRepositoryProvider);
      final now = DateTime.now();

      // Update nebo Create
      if (currentState.userProfile != null) {
        // Update existujícího profilu
        final updated = currentState.userProfile!.copyWith(
          firstName: firstName,
          lastName: lastName,
          birthDate: birthDate,
          nameDay: nameDay,
          nickname: nickname,
          gender: gender,
          hobbies: hobbies,
          aboutMe: aboutMe,
          silneStranky: silneStranky,
          slabeStranky: slabeStranky,
          updatedAt: now,
        );

        await repository.updateUserProfile(updated);

        state = AsyncValue.data(currentState.copyWith(userProfile: updated));
        AppLogger.info('✅ Profil aktualizován');
      } else {
        // Create nového profilu
        final newProfile = UserProfile(
          userId: 'default',
          firstName: firstName,
          lastName: lastName,
          birthDate: birthDate,
          nameDay: nameDay,
          nickname: nickname,
          gender: gender,
          hobbies: hobbies,
          aboutMe: aboutMe,
          silneStranky: silneStranky,
          slabeStranky: slabeStranky,
          createdAt: now,
          updatedAt: now,
        );

        await repository.createUserProfile(newProfile);

        state = AsyncValue.data(currentState.copyWith(userProfile: newProfile));
        AppLogger.info('✅ Profil vytvořen');
      }
    } catch (e) {
      AppLogger.error('Chyba při ukládání profilu: $e');
      state = AsyncValue.data(ProfileError(e.toString()));
    }
  }

  /// Přidat člena rodiny
  Future<void> addFamilyMember({
    required String firstName,
    required String lastName,
    String? relationship,
    DateTime? birthDate,
    DateTime? nameDay,
    String? nickname,
    String? gender,
    List<String>? hobbies,
  }) async {
    final currentState = state.value;
    if (currentState is! ProfileLoaded) return;

    try {
      final repository = ref.read(profileRepositoryProvider);

      final newMember = FamilyMember(
        userId: currentState.userProfile?.userId ?? 'default',
        firstName: firstName,
        lastName: lastName,
        relationship: relationship,
        birthDate: birthDate,
        nameDay: nameDay,
        nickname: nickname,
        gender: gender,
        hobbies: hobbies,
      );

      await repository.addFamilyMember(newMember);

      // Reload family members
      final familyMembers = await repository.getAllFamilyMembers(
        userId: currentState.userProfile?.userId ?? 'default',
      );

      state = AsyncValue.data(currentState.copyWith(familyMembers: familyMembers));

      AppLogger.info('✅ Člen rodiny přidán: $firstName $lastName');
    } catch (e) {
      AppLogger.error('Chyba při přidávání člena rodiny: $e');
      state = AsyncValue.data(ProfileError(e.toString()));
    }
  }

  /// Aktualizovat člena rodiny
  Future<void> updateFamilyMember(FamilyMember member) async {
    final currentState = state.value;
    if (currentState is! ProfileLoaded) return;

    try {
      final repository = ref.read(profileRepositoryProvider);

      await repository.updateFamilyMember(member);

      // Reload family members
      final familyMembers = await repository.getAllFamilyMembers(
        userId: currentState.userProfile?.userId ?? 'default',
      );

      state = AsyncValue.data(currentState.copyWith(familyMembers: familyMembers));

      AppLogger.info('✅ Člen rodiny aktualizován: ${member.id}');
    } catch (e) {
      AppLogger.error('Chyba při aktualizaci člena rodiny: $e');
      state = AsyncValue.data(ProfileError(e.toString()));
    }
  }

  /// Smazat člena rodiny
  Future<void> deleteFamilyMember(int id) async {
    final currentState = state.value;
    if (currentState is! ProfileLoaded) return;

    try {
      final repository = ref.read(profileRepositoryProvider);

      await repository.deleteFamilyMember(id);

      // Reload family members
      final familyMembers = await repository.getAllFamilyMembers(
        userId: currentState.userProfile?.userId ?? 'default',
      );

      state = AsyncValue.data(currentState.copyWith(familyMembers: familyMembers));

      AppLogger.info('✅ Člen rodiny smazán: $id');
    } catch (e) {
      AppLogger.error('Chyba při mazání člena rodiny: $e');
      state = AsyncValue.data(ProfileError(e.toString()));
    }
  }

  /// Inkrementovat počet dokončených úkolů
  Future<void> incrementCompletedTasks() async {
    final currentState = state.value;
    if (currentState is! ProfileLoaded || currentState.userProfile == null) return;

    try {
      final repository = ref.read(profileRepositoryProvider);

      final updated = currentState.userProfile!.copyWith(
        completedTasksCount: currentState.userProfile!.completedTasksCount + 1,
        updatedAt: DateTime.now(),
      );

      await repository.updateUserProfile(updated);

      state = AsyncValue.data(currentState.copyWith(userProfile: updated));

      AppLogger.debug('✅ Completed tasks count: ${updated.completedTasksCount}');
    } catch (e) {
      AppLogger.error('Chyba při inkrementaci completed tasks: $e');
    }
  }
}

/// Helper provider: získat user profile
@riverpod
UserProfile? userProfile(UserProfileRef ref) {
  final profileAsync = ref.watch(profileProvider());

  return profileAsync.maybeWhen(
    data: (state) {
      if (state is ProfileLoaded) {
        return state.userProfile;
      }
      return null;
    },
    orElse: () => null,
  );
}

/// Helper provider: získat family members
@riverpod
List<FamilyMember> familyMembers(FamilyMembersRef ref) {
  final profileAsync = ref.watch(profileProvider());

  return profileAsync.maybeWhen(
    data: (state) {
      if (state is ProfileLoaded) {
        return state.familyMembers;
      }
      return [];
    },
    orElse: () => [],
  );
}
