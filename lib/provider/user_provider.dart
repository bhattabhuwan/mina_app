import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserProvider extends ChangeNotifier {
  String _fullName = 'User';
  String _email = '';
  String? _profileImagePath;

  String get fullName => _fullName;
  String get email => _email;
  String? get profileImagePath => _profileImagePath;

  Future<void> loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    _fullName = prefs.getString('profile_full_name') ?? 'User';
    _email = prefs.getString('profile_email') ?? '';
    _profileImagePath = prefs.getString('profile_image_path');
    notifyListeners();
  }

  Future<void> updateUser({
    required String fullName,
    required String email,
    String? profileImagePath,
  }) async {
    _fullName = fullName;
    _email = email;
    if (profileImagePath != null) {
      _profileImagePath = profileImagePath;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile_full_name', fullName);
    await prefs.setString('profile_email', email);
    if (profileImagePath != null) {
      await prefs.setString('profile_image_path', profileImagePath);
    }
    notifyListeners();
  }

  Future<void> clearUserData() async {
    _fullName = 'User';
    _email = '';
    _profileImagePath = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('profile_full_name');
    await prefs.remove('profile_email');
    await prefs.remove('profile_image_path');
    notifyListeners();
  }
}