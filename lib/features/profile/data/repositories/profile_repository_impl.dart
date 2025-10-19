import '../../../../core/services/database_helper.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/entities/family_member.dart';
import '../../domain/repositories/profile_repository.dart';

/// Implementace ProfileRepository s DatabaseHelper
class ProfileRepositoryImpl implements ProfileRepository {
  final DatabaseHelper _db;

  ProfileRepositoryImpl(this._db);

  // === UserProfile CRUD ===

  @override
  Future<UserProfile?> getUserProfile({String userId = 'default'}) async {
    final db = await _db.database;
    final results = await db.query(
      'user_profile',
      where: 'user_id = ?',
      whereArgs: [userId],
      limit: 1,
    );

    if (results.isEmpty) return null;
    return UserProfile.fromMap(results.first);
  }

  @override
  Future<int> createUserProfile(UserProfile profile) async {
    final db = await _db.database;
    return await db.insert('user_profile', profile.toMap());
  }

  @override
  Future<void> updateUserProfile(UserProfile profile) async {
    final db = await _db.database;
    await db.update(
      'user_profile',
      profile.toMap(),
      where: 'id = ?',
      whereArgs: [profile.id],
    );
  }

  @override
  Future<void> deleteUserProfile(int id) async {
    final db = await _db.database;
    await db.delete(
      'user_profile',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // === FamilyMember CRUD ===

  @override
  Future<List<FamilyMember>> getAllFamilyMembers({
    String userId = 'default',
  }) async {
    final db = await _db.database;
    final results = await db.query(
      'family_members',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );

    return results.map((map) => FamilyMember.fromMap(map)).toList();
  }

  @override
  Future<FamilyMember?> getFamilyMemberById(int id) async {
    final db = await _db.database;
    final results = await db.query(
      'family_members',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (results.isEmpty) return null;
    return FamilyMember.fromMap(results.first);
  }

  @override
  Future<int> createFamilyMember(FamilyMember member) async {
    final db = await _db.database;
    return await db.insert('family_members', member.toMap());
  }

  @override
  Future<void> updateFamilyMember(FamilyMember member) async {
    final db = await _db.database;
    await db.update(
      'family_members',
      member.toMap(),
      where: 'id = ?',
      whereArgs: [member.id],
    );
  }

  @override
  Future<void> deleteFamilyMember(int id) async {
    final db = await _db.database;
    await db.delete(
      'family_members',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
