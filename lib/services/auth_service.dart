import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:hive/hive.dart';

import '../models/user_profile.dart';
import 'storage_service.dart';

/// Local-only authentication. Stores hashed passwords in the shared `auth` box.
class AuthService {
  static const _saltPrefix = 'rq_v1::';

  String _hash(String password, String name) {
    final bytes = utf8.encode('$_saltPrefix$name::$password');
    return sha256.convert(bytes).toString();
  }

  Box get _box => StorageService.auth;

  UserProfile? get currentUser {
    final name = _box.get(StorageService.authKeyCurrentUser) as String?;
    if (name == null) return null;
    final raw = _box.get('user_$name');
    if (raw is UserProfile) return raw;
    if (raw is Map) return UserProfile.fromMap(raw);
    return null;
  }

  bool userExists(String name) =>
      _box.get('user_${name.trim().toLowerCase()}') != null;

  Future<UserProfile> signUp({
    required String name,
    required String password,
    required String characterId,
    String? displayName,
  }) async {
    final key = name.trim().toLowerCase();
    if (key.isEmpty) {
      throw const FormatException('empty-id');
    }
    if (password.length < 4) {
      throw const FormatException('short-pw');
    }
    if (userExists(key)) {
      throw StateError('user-exists');
    }
    final profile = UserProfile(
      name: name.trim(),
      displayName: displayName,
      characterId: characterId,
      passwordHash: _hash(password, key),
      lastLoginAt: DateTime.now(),
    );
    await _box.put('user_$key', profile);
    await _box.put(StorageService.authKeyCurrentUser, key);
    return profile;
  }

  Future<UserProfile> signIn({required String name, required String password}) async {
    final key = name.trim().toLowerCase();
    final raw = _box.get('user_$key');
    if (raw == null) throw StateError('user-not-found');
    final stored = raw is UserProfile ? raw : UserProfile.fromMap(raw as Map);
    if (stored.passwordHash != _hash(password, key)) {
      throw StateError('wrong-pw');
    }
    final updated = stored.copyWith(lastLoginAt: DateTime.now());
    await _box.put('user_$key', updated);
    await _box.put(StorageService.authKeyCurrentUser, key);
    return updated;
  }

  Future<void> signOut() async {
    await _box.delete(StorageService.authKeyCurrentUser);
  }

  Future<UserProfile> updateProfile(UserProfile updated) async {
    final key = updated.name.trim().toLowerCase();
    await _box.put('user_$key', updated);
    return updated;
  }
}
