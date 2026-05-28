import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserProvider extends ChangeNotifier {
  String _fullName = 'User';
  String _email = '';
  String? _profileImagePath;
  String _role = 'patient';
  int? _userId;                       // 👈 NEW

  String get fullName => _fullName;
  String get email => _email;
  String? get profileImagePath => _profileImagePath;
  String? get profileImageUrl => _profileImagePath;
  String get role => _role;
  int? get userId => _userId;         // 👈 NEW

  Future<void> loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    _fullName = prefs.getString('profile_full_name') ?? 'User';
    _email = prefs.getString('profile_email') ?? '';
    _profileImagePath = prefs.getString('profile_image_url') ??
        prefs.getString('profile_image_path');
    _role = prefs.getString('profile_role') ?? 'patient';
    _userId = prefs.getInt('profile_user_id');    // 👈 NEW
    notifyListeners();
  }

  Future<void> updateUser({
    required String fullName,
    required String email,
    String? profileImagePath,
    String? role,
    int? userId,                       // 👈 NEW
  }) async {
    _fullName = fullName;
    _email = email;
    if (profileImagePath != null) _profileImagePath = profileImagePath;
    if (role != null) _role = role;
    if (userId != null) _userId = userId;   // 👈 NEW

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile_full_name', fullName);
    await prefs.setString('profile_email', email);
    if (profileImagePath != null) {
      await prefs.setString('profile_image_url', profileImagePath);
      await prefs.setString('profile_image_path', profileImagePath);
    }
    if (role != null) {
      await prefs.setString('profile_role', role);
    }
    if (userId != null) {                     // 👈 NEW
      await prefs.setInt('profile_user_id', userId);
    }
    notifyListeners();
  }

  Future<void> clearUserData() async {
    _fullName = 'User';
    _email = '';
    _profileImagePath = null;
    _role = 'patient';
    _userId = null;                           // 👈 NEW
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('profile_full_name');
    await prefs.remove('profile_email');
    await prefs.remove('profile_image_path');
    await prefs.remove('profile_image_url');
    await prefs.remove('profile_role');
    await prefs.remove('profile_user_id');    // 👈 NEW
    notifyListeners();
  }
}
