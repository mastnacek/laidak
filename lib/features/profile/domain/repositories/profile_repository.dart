import '../entities/user_profile.dart';
import '../entities/family_member.dart';

/// Repository interface pro profile operace
abstract class ProfileRepository {
  // === UserProfile CRUD ===
  Future<UserProfile?> getUserProfile({String userId = 'default'});
  Future<int> createUserProfile(UserProfile profile);
  Future<void> updateUserProfile(UserProfile profile);
  Future<void> deleteUserProfile(int id);

  // === FamilyMember CRUD ===
  Future<List<FamilyMember>> getAllFamilyMembers({String userId = 'default'});
  Future<FamilyMember?> getFamilyMemberById(int id);
  Future<int> createFamilyMember(FamilyMember member);
  Future<void> updateFamilyMember(FamilyMember member);
  Future<void> deleteFamilyMember(int id);
}
