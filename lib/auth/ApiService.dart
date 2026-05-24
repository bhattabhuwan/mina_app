import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  final String baseUrl = "https://mina-backend-1.onrender.com";

  // ------------------------
  // REGISTER USER
  // ------------------------
  Future<Map<String, dynamic>> registerUser({
    required String email,
    required String username,
    required String fullName,
    required String phone,
    required String gender,
    required String role,
    required String password,
    required DateTime dateOfBirth,
    required String address,
    required String emergencyContact,
    List<String>? medicalConditions,
    List<String>? allergies,
    List<String>? currentMedications,
  }) async {
    final url = Uri.parse("$baseUrl/api/v1/auth/register");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "email": email,
        "username": username,
        "full_name": fullName,
        "phone": phone,
        "gender": gender,
        "role": role,
        "password": password,
        "date_of_birth": dateOfBirth.toIso8601String(),
        "address": address,
        "emergency_contact": emergencyContact,
        "medical_conditions": medicalConditions ?? [],
        "allergies": allergies ?? [],
        "current_medications": currentMedications ?? [],
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to register: ${response.body}");
    }
  }

  // ------------------------
  // LOGIN USER (SAVE TOKEN CORRECTLY)
  // ------------------------
  Future<void> loginUser({
    required String username,
    required String password,
  }) async {
    final url = Uri.parse("$baseUrl/api/v1/auth/login");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "username": username,
        "password": password,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      // Adjust this depending on your backend's token key
      // Common possibilities: data['access_token'], data['data']['access_token'], etc.
      final token = data['access_token'] ?? data['data']?['access_token'];

      if (token == null) {
        throw Exception("Access token not found in response: $data");
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', token);
    } else {
      throw Exception("Login failed: ${response.body}");
    }
  }

  // ------------------------
  // GET CURRENT USER (/me)
  // ------------------------
  Future<Map<String, dynamic>> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null || token.isEmpty) {
      throw Exception("User not logged in");
    }

    final url = Uri.parse("$baseUrl/api/v1/auth/me");

    final response = await http.get(
      url,
      headers: {
        "Authorization": "Bearer $token",
        "Accept": "application/json",
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);

      // Ensure user data exists
      if (!data.containsKey('full_name')) {
        throw Exception("User data missing in response: $data");
      }

      return data;
    } else if (response.statusCode == 401) {
      // Token invalid or expired
      await logout();
      throw Exception("Session expired. Please login again.");
    } else {
      throw Exception("Failed to fetch user: ${response.body}");
    }
  }

  // ------------------------
  // CHECK LOGIN STATUS
  // ------------------------
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    return token != null && token.isNotEmpty;
  }

  // ------------------------
  // LOGOUT USER
  // ------------------------
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }


  // ------------------------
  // FORGOT PASSWORD
  // ------------------------
  Future<Map<String, dynamic>> forgotPassword({
    required String email,
  }) async {
    final url = Uri.parse("$baseUrl/api/v1/auth/forgot-password");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "email": email,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Forgot password request failed: ${response.body}");
    }
  }
}
