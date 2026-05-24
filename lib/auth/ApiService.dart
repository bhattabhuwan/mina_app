import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  final String baseUrl = "https://mina-backend-1.onrender.com";

  // ------------------------
  // Helper: Get headers with token
  // ------------------------
  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null || token.isEmpty) {
      throw Exception("User not authenticated");
    }
    return {
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    };
  }

  // ------------------------
  // AUTH METHODS
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

  Future<Map<String, dynamic>> getCurrentUser() async {
    final url = Uri.parse("$baseUrl/api/v1/auth/me");
    final headers = await _getHeaders();
    final response = await http.get(url, headers: headers);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 401) {
      await logout();
      throw Exception("Session expired. Please login again.");
    } else {
      throw Exception("Failed to fetch user: ${response.body}");
    }
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    return token != null && token.isNotEmpty;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }

  Future<Map<String, dynamic>> forgotPassword({required String email}) async {
    final url = Uri.parse("$baseUrl/api/v1/auth/forgot-password");
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email}),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Forgot password request failed: ${response.body}");
    }
  }

  // ------------------------
  // USER PROFILE (Update)
  // ------------------------
  Future<Map<String, dynamic>> updateUserProfile(Map<String, dynamic> data) async {
    final url = Uri.parse("$baseUrl/api/v1/auth/me");
    final headers = await _getHeaders();
    final response = await http.put(url, headers: headers, body: jsonEncode(data));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to update profile: ${response.body}");
    }
  }

  // ------------------------
  // DOCTORS (if your backend provides a list)
  // ------------------------
  Future<List<dynamic>> getDoctors() async {
    final url = Uri.parse("$baseUrl/api/v1/doctors"); // adjust endpoint if needed
    final headers = await _getHeaders();
    final response = await http.get(url, headers: headers);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      // If endpoint doesn't exist, return empty list or fallback
      return [];
    }
  }

  // ------------------------
  // APPOINTMENTS
  // ------------------------
  Future<Map<String, dynamic>> createAppointment(Map<String, dynamic> data) async {
    final url = Uri.parse("$baseUrl/api/v1/appointments/");
    final headers = await _getHeaders();
    final response = await http.post(url, headers: headers, body: jsonEncode(data));
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to create appointment: ${response.body}");
    }
  }

  Future<List<dynamic>> getAppointments() async {
    final url = Uri.parse("$baseUrl/api/v1/appointments/");
    final headers = await _getHeaders();
    final response = await http.get(url, headers: headers);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to fetch appointments: ${response.body}");
    }
  }

  Future<Map<String, dynamic>> getAppointmentById(String id) async {
    final url = Uri.parse("$baseUrl/api/v1/appointments/$id");
    final headers = await _getHeaders();
    final response = await http.get(url, headers: headers);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to fetch appointment: ${response.body}");
    }
  }

  Future<Map<String, dynamic>> updateAppointment(String id, Map<String, dynamic> data) async {
    final url = Uri.parse("$baseUrl/api/v1/appointments/$id");
    final headers = await _getHeaders();
    final response = await http.put(url, headers: headers, body: jsonEncode(data));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to update appointment: ${response.body}");
    }
  }

  Future<void> cancelAppointment(String id) async {
    final url = Uri.parse("$baseUrl/api/v1/appointments/$id");
    final headers = await _getHeaders();
    final response = await http.delete(url, headers: headers);
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception("Failed to cancel appointment: ${response.body}");
    }
  }

  Future<Map<String, dynamic>> updateAppointmentStatus(String id, String status) async {
    final url = Uri.parse("$baseUrl/api/v1/appointments/$id/status");
    final headers = await _getHeaders();
    final response = await http.patch(url, headers: headers, body: jsonEncode({"status": status}));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to update appointment status: ${response.body}");
    }
  }

  Future<String> startVideoCall(String id) async {
    final url = Uri.parse("$baseUrl/api/v1/appointments/$id/start-video-call");
    final headers = await _getHeaders();
    final response = await http.post(url, headers: headers);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['video_url']; // adjust based on backend response
    } else {
      throw Exception("Failed to start video call: ${response.body}");
    }
  }

  Future<List<dynamic>> getUpcomingAppointments() async {
    final url = Uri.parse("$baseUrl/api/v1/appointments/upcoming");
    final headers = await _getHeaders();
    final response = await http.get(url, headers: headers);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to fetch upcoming appointments: ${response.body}");
    }
  }

  // ------------------------
  // MEDICAL RECORDS
  // ------------------------
  Future<Map<String, dynamic>> createMedicalRecord(Map<String, dynamic> data) async {
    final url = Uri.parse("$baseUrl/api/v1/medical/records");
    final headers = await _getHeaders();
    final response = await http.post(url, headers: headers, body: jsonEncode(data));
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to create medical record: ${response.body}");
    }
  }

  Future<List<dynamic>> getMedicalRecords() async {
    final url = Uri.parse("$baseUrl/api/v1/medical/records");
    final headers = await _getHeaders();
    final response = await http.get(url, headers: headers);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to fetch medical records: ${response.body}");
    }
  }

  Future<Map<String, dynamic>> getMedicalRecordById(String recordId) async {
    final url = Uri.parse("$baseUrl/api/v1/medical/records/$recordId");
    final headers = await _getHeaders();
    final response = await http.get(url, headers: headers);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to fetch medical record: ${response.body}");
    }
  }

  Future<Map<String, dynamic>> updateMedicalRecord(String recordId, Map<String, dynamic> data) async {
    final url = Uri.parse("$baseUrl/api/v1/medical/records/$recordId");
    final headers = await _getHeaders();
    final response = await http.put(url, headers: headers, body: jsonEncode(data));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to update medical record: ${response.body}");
    }
  }

  Future<List<dynamic>> getRecordTypes() async {
    final url = Uri.parse("$baseUrl/api/v1/medical/records/types");
    final headers = await _getHeaders();
    final response = await http.get(url, headers: headers);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to fetch record types: ${response.body}");
    }
  }

  // ------------------------
  // PRESCRIPTIONS
  // ------------------------
  Future<Map<String, dynamic>> createPrescription(Map<String, dynamic> data) async {
    final url = Uri.parse("$baseUrl/api/v1/medical/prescriptions");
    final headers = await _getHeaders();
    final response = await http.post(url, headers: headers, body: jsonEncode(data));
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to create prescription: ${response.body}");
    }
  }

  Future<List<dynamic>> getPrescriptions() async {
    final url = Uri.parse("$baseUrl/api/v1/medical/prescriptions");
    final headers = await _getHeaders();
    final response = await http.get(url, headers: headers);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to fetch prescriptions: ${response.body}");
    }
  }

  Future<Map<String, dynamic>> getPrescriptionById(String prescriptionId) async {
    final url = Uri.parse("$baseUrl/api/v1/medical/prescriptions/$prescriptionId");
    final headers = await _getHeaders();
    final response = await http.get(url, headers: headers);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to fetch prescription: ${response.body}");
    }
  }

  Future<Map<String, dynamic>> updatePrescription(String prescriptionId, Map<String, dynamic> data) async {
    final url = Uri.parse("$baseUrl/api/v1/medical/prescriptions/$prescriptionId");
    final headers = await _getHeaders();
    final response = await http.put(url, headers: headers, body: jsonEncode(data));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to update prescription: ${response.body}");
    }
  }

  Future<void> deactivatePrescription(String prescriptionId) async {
    final url = Uri.parse("$baseUrl/api/v1/medical/prescriptions/$prescriptionId");
    final headers = await _getHeaders();
    final response = await http.delete(url, headers: headers);
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception("Failed to deactivate prescription: ${response.body}");
    }
  }
}