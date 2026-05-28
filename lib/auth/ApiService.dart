import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class VideoCallConnection {
  final WebSocketChannel channel;
  final Uri websocketUri;
  final Map<String, dynamic> response;

  const VideoCallConnection({
    required this.channel,
    required this.websocketUri,
    required this.response,
  });
}

class ApiService {
  final String baseUrl = "https://mina-backend-1.onrender.com";

  String resolveBackendUrl(String urlOrPath) {
    final value = urlOrPath.trim();
    final uri = Uri.tryParse(value);
    if (uri != null && uri.hasScheme) {
      return value;
    }
    if (value.startsWith('/')) {
      return '$baseUrl$value';
    }
    return '$baseUrl/$value';
  }

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

  Future<String> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null || token.isEmpty) {
      throw Exception("User not authenticated");
    }
    return token;
  }

  // ------------------------
  // AUTH METHODS (base registration – no role field)
  // ------------------------
  Future<Map<String, dynamic>> registerUser({
    required String email,
    required String username,
    required String fullName,
    String? phone,
    String? gender,
    required String password,
    DateTime? dateOfBirth,
    String? address,
    String? emergencyContact,
    List<String>? medicalConditions,
    List<String>? allergies,
    List<String>? currentMedications,
  }) async {
    final url = Uri.parse("$baseUrl/api/v1/auth/register");

    final requestBody = {
      "email": email,
      "username": username,
      "full_name": fullName,
      "password": password,
      if (phone?.isNotEmpty ?? false) "phone": phone,
      if (gender?.isNotEmpty ?? false) "gender": gender,
      if (dateOfBirth != null) "date_of_birth": dateOfBirth.toIso8601String(),
      if (address?.isNotEmpty ?? false) "address": address,
      if (emergencyContact?.isNotEmpty ?? false) "emergency_contact": emergencyContact,
      "medical_conditions": medicalConditions ?? [],
      "allergies": allergies ?? [],
      "current_medications": currentMedications ?? [],
    };

    print("REGISTER REQUEST BODY: $requestBody");
    print("REGISTER PAYLOAD: ${jsonEncode(requestBody)}");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(requestBody),
    );

    print("REGISTER RESPONSE: Status=${response.statusCode}");
    print("REGISTER RESPONSE BODY: ${response.body}");

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Registration failed: ${response.body}");
    }
  }

  // ------------------------
  // DOCTOR PROFILE UPDATE (after registration)
  // ------------------------
  Future<Map<String, dynamic>> updateDoctorProfile({
    required String specialization,
    required String licenseNumber,
    required String clinicName,
    required String clinicAddress,
    required int yearsOfExperience,
    required double consultationFee,
    required String availableDays,
  }) async {
    final url = Uri.parse("$baseUrl/api/v1/doctor/profile");
    final headers = await _getHeaders();
    final response = await http.patch(
      url,
      headers: headers,
      body: jsonEncode({
        "specialization": specialization,
        "license_number": licenseNumber,
        "clinic_name": clinicName,
        "clinic_address": clinicAddress,
        "years_of_experience": yearsOfExperience,
        "consultation_fee": consultationFee,
        "available_days": availableDays,
      }),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to update doctor profile: ${response.body}");
    }
  }

  // ------------------------
  // LOGIN & SESSION
  // ------------------------
  Future<void> loginUser({
    required String username,
    required String password,
  }) async {
    final url = Uri.parse("$baseUrl/api/v1/auth/login");
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"username": username, "password": password}),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final token = data['access_token'] ?? data['data']?['access_token'];
      if (token == null) throw Exception("Access token not found");
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
  // DOCTORS LIST
  // ------------------------
  Future<List<dynamic>> getDoctors() async {
    final url = Uri.parse("$baseUrl/api/v1/auth/users?role=doctor");
    final headers = await _getHeaders();
    final response = await http.get(url, headers: headers);
    if (response.statusCode == 200 || response.statusCode == 201) {
      final decoded = jsonDecode(response.body);
      if (decoded is List) {
        return decoded;
      }
      if (decoded is Map && decoded['data'] is List) {
        return decoded['data'] as List;
      }
      return [];
    } else {
      return [];
    }
  }

  // ------------------------
  // DOCTOR DASHBOARD
  // ------------------------
  Future<Map<String, dynamic>> getDoctorDashboard() async {
    final url = Uri.parse("$baseUrl/api/v1/dashboard/doctor");
    final headers = await _getHeaders();
    final response = await http.get(url, headers: headers);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to fetch doctor dashboard: ${response.body}");
    }
  }

  Future<Map<String, dynamic>> getDoctorDashboardProfile() async {
    final url = Uri.parse("$baseUrl/api/v1/dashboard/doctor/profile");
    final headers = await _getHeaders();
    final response = await http.get(url, headers: headers);
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        return decoded['data'] is Map<String, dynamic> ? decoded['data'] : decoded;
      }
      throw Exception("Unexpected doctor profile response: ${response.body}");
    } else {
      throw Exception("Failed to fetch doctor profile: ${response.body}");
    }
  }

  Future<Map<String, dynamic>> getDoctorRating(Object doctorId) async {
    final url = Uri.parse("$baseUrl/api/v1/dashboard/doctors/$doctorId/rating");
    final headers = await _getHeaders();
    final response = await http.get(url, headers: headers);
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        return decoded['data'] is Map<String, dynamic> ? decoded['data'] : decoded;
      }
      throw Exception("Unexpected doctor rating response: ${response.body}");
    } else {
      throw Exception("Failed to fetch doctor rating: ${response.body}");
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
      String errorMsg = response.body;
      try {
        final errorJson = jsonDecode(response.body);
        errorMsg = errorJson['message'] ?? errorJson['error'] ?? errorJson['detail'] ?? response.body;
      } catch (_) {}
      throw Exception("Booking failed: $errorMsg");
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

  Future<int?> findAppointmentIdWithParticipant(String participantId) async {
    final appointments = await getAppointments();
    final participant = int.tryParse(participantId);

    bool matchesParticipant(dynamic value) {
      if (participant != null && value is int) return value == participant;
      return value?.toString() == participantId;
    }

    final matching = appointments.whereType<Map>().where((appointment) {
      final status = appointment['status']?.toString().toLowerCase();
      if (status == 'cancelled' || status == 'completed' || status == 'no_show') {
        return false;
      }
      return matchesParticipant(appointment['doctor_id']) ||
          matchesParticipant(appointment['patient_id']);
    }).toList();

    if (matching.isEmpty) return null;

    matching.sort((a, b) {
      final aDate = DateTime.tryParse(a['scheduled_at']?.toString() ?? '');
      final bDate = DateTime.tryParse(b['scheduled_at']?.toString() ?? '');
      if (aDate == null && bDate == null) return 0;
      if (aDate == null) return 1;
      if (bDate == null) return -1;
      return aDate.compareTo(bDate);
    });

    final now = DateTime.now();
    final futureMatch = matching.cast<Map>().where((appointment) {
      final scheduledAt = DateTime.tryParse(appointment['scheduled_at']?.toString() ?? '');
      return scheduledAt == null || !scheduledAt.isBefore(now);
    }).toList();
    final selected = futureMatch.isNotEmpty ? futureMatch.first : matching.first;
    final id = selected['id'];
    return id is int ? id : int.tryParse(id.toString());
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

  Future<Map<String, dynamic>> updateAppointmentStatus(Object id, String status) async {
    final url = Uri.parse("$baseUrl/api/v1/appointments/$id/status");
    final headers = await _getHeaders();
    final response = await http.patch(url, headers: headers, body: jsonEncode({"status": status}));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to update appointment status: ${response.body}");
    }
  }

  Future<VideoCallConnection> startVideoCall(Object id, {String? accessToken}) async {
    final token = accessToken ?? await getAccessToken();
    final url = Uri.parse("$baseUrl/api/v1/appointments/$id/start-video-call");
    final response = await http.post(
      url,
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      if (data is! Map) {
        throw Exception("Unexpected video call response: ${response.body}");
      }
      final responseData = Map<String, dynamic>.from(data);

      final nestedAppointment = data['appointment'] is Map ? data['appointment'] as Map : null;
      final nestedData = data['data'] is Map ? data['data'] as Map : null;
      final wsTemplate = data['websocket_url_template'] ??
          data['websocket_url'] ??
          data['ws_url'] ??
          data['websocket_path'] ??
          nestedAppointment?['websocket_url_template'] ??
          nestedAppointment?['websocket_url'] ??
          nestedAppointment?['ws_url'] ??
          nestedAppointment?['websocket_path'] ??
          nestedData?['websocket_url_template'] ??
          nestedData?['websocket_url'] ??
          nestedData?['ws_url'] ??
          nestedData?['websocket_path'];
      final roomId = data['room_id'] ??
          data['roomId'] ??
          data['room'] ??
          data['room_name'] ??
          nestedAppointment?['room_id'] ??
          nestedAppointment?['roomId'] ??
          nestedAppointment?['room'] ??
          nestedAppointment?['room_name'] ??
          nestedData?['room_id'] ??
          nestedData?['roomId'] ??
          nestedData?['room'] ??
          nestedData?['room_name'];

      String? valueAsString(dynamic value) {
        final text = value?.toString().trim();
        return text == null || text.isEmpty ? null : text;
      }

      Uri websocketUriFrom(String value) {
        final withToken = value.replaceAll('{token}', token);
        final parsed = Uri.parse(withToken);
        if (parsed.hasScheme) {
          if (parsed.scheme == 'http') {
            return parsed.replace(scheme: 'ws');
          }
          if (parsed.scheme == 'https') {
            return parsed.replace(scheme: 'wss');
          }
          return parsed;
        }
        final resolved = Uri.parse(baseUrl).resolve(withToken);
        return resolved.replace(scheme: resolved.scheme == 'http' ? 'ws' : 'wss');
      }

      final templateText = valueAsString(wsTemplate);
      final roomText = valueAsString(roomId);
      final websocketUri = templateText != null
          ? websocketUriFrom(templateText)
          : roomText != null
              ? websocketUriFrom('/api/v1/ws/video/$roomText/{token}')
              : null;

      if (websocketUri == null) {
        throw Exception(
          "Video call started, but the backend did not return a WebSocket URL.",
        );
      }

      final channel = WebSocketChannel.connect(websocketUri);
      return VideoCallConnection(
        channel: channel,
        websocketUri: websocketUri,
        response: responseData,
      );
    } else {
      String errorMsg = response.body;
      try {
        final errorJson = jsonDecode(response.body);
        errorMsg = errorJson['detail']?.toString() ??
            errorJson['message']?.toString() ??
            response.body;
      } catch (_) {}
      throw Exception("Failed to start video call: $errorMsg");
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

  Future<Map<String, dynamic>> getPatientDashboard() async {
    final url = Uri.parse("$baseUrl/api/v1/dashboard/patient");
    final headers = await _getHeaders();
    final response = await http.get(url, headers: headers);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to fetch patient dashboard: ${response.body}");
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

  // ------------------------
  // PROFILE PICTURE UPLOAD
  // ------------------------
  Future<Map<String, dynamic>> uploadProfilePicture(String imagePath) async {
    final url = Uri.parse("$baseUrl/api/v1/auth/me/profile-image");
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null || token.isEmpty) {
      throw Exception("User not authenticated");
    }

    final request = http.MultipartRequest('POST', url);
    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(
      await http.MultipartFile.fromPath('file', imagePath),
    );

    try {
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = jsonDecode(responseBody);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
        throw Exception("Unexpected profile picture response: $responseBody");
      } else {
        String errorMsg = responseBody;
        try {
          final errorJson = jsonDecode(responseBody);
          errorMsg = errorJson['detail']?.toString() ??
              errorJson['message']?.toString() ??
              responseBody;
        } catch (_) {}
        throw Exception("Failed to upload profile picture: $errorMsg");
      }
    } catch (e) {
      throw Exception("Profile picture upload error: $e");
    }
  }

  // ------------------------
  // DOCTOR PATIENTS
  // ------------------------
  Future<List<dynamic>> getDoctorPatients() async {
    final url = Uri.parse("$baseUrl/api/v1/doctor/patients");
    final headers = await _getHeaders();
    final response = await http.get(url, headers: headers);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to fetch doctor patients: ${response.body}");
    }
  }

  Future<Map<String, dynamic>> getPatientDetails(String patientId) async {
    final url = Uri.parse("$baseUrl/api/v1/patients/$patientId");
    final headers = await _getHeaders();
    final response = await http.get(url, headers: headers);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to fetch patient details: ${response.body}");
    }
  }

  // ------------------------
  // MESSAGING/CHAT
  // ------------------------
  Future<Map<String, dynamic>> sendMessage({
    required String recipientId,
    required String message,
    String? recipientType,
    int? appointmentId,
  }) async {
    final receiverId = int.tryParse(recipientId);
    if (receiverId == null) {
      throw Exception("Invalid receiver ID");
    }

    final url = Uri.parse("$baseUrl/api/v1/communication/messages");
    final headers = await _getHeaders();
    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode({
        'receiver_id': receiverId,
        'content': message,
        'message_type': 'text',
        if (appointmentId != null) 'appointment_id': appointmentId,
      }),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to send message: ${response.body}");
    }
  }

  Future<Map<String, dynamic>> sendCallInvitation({
    required String recipientId,
    required int appointmentId,
  }) {
    return sendMessage(
      recipientId: recipientId,
      message: 'Incoming video call. Tap Join Call to answer.',
      appointmentId: appointmentId,
    );
  }

  Future<List<dynamic>> getConversation(String participantId, {int? appointmentId}) async {
    final conversationWith = int.tryParse(participantId);
    if (conversationWith == null) {
      throw Exception("Invalid conversation participant ID");
    }

    final query = <String, String>{
      'conversation_with': conversationWith.toString(),
      'limit': '100',
      if (appointmentId != null) 'appointment_id': appointmentId.toString(),
    };
    final url = Uri.parse("$baseUrl/api/v1/communication/messages")
        .replace(queryParameters: query);
    final headers = await _getHeaders();
    final response = await http.get(url, headers: headers);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to fetch conversation: ${response.body}");
    }
  }

  Future<List<dynamic>> getConversations() async {
    final currentUser = await getCurrentUser();
    final user = currentUser['data'] ?? currentUser;
    final role = user['role']?.toString() ?? 'patient';
    final dashboard = role == 'doctor'
        ? await getDoctorDashboard()
        : await getPatientDashboard();
    return dashboard['recent_conversations'] ?? [];
  }

  Future<void> markMessageAsRead(String messageId) async {
    final url = Uri.parse("$baseUrl/api/v1/communication/messages/$messageId/read");
    final headers = await _getHeaders();
    final response = await http.patch(url, headers: headers);
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception("Failed to mark as read: ${response.body}");
    }
  }

  Future<void> markMessagesAsRead(Iterable<dynamic> messageIds) async {
    for (final id in messageIds) {
      if (id == null) continue;
      await markMessageAsRead(id.toString());
    }
  }

  // ------------------------
  // SYMPTOM CHECKER
  // ------------------------

  /// Analyze symptoms and predict possible conditions
  Future<Map<String, dynamic>> analyzeSymptoms(Map<String, dynamic> symptomsData) async {
    final url = Uri.parse("$baseUrl/api/v1/symptom-checker/analyze");
    final headers = await _getHeaders();
    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode(symptomsData),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      String errorMsg = response.body;
      try {
        final errorJson = jsonDecode(response.body);
        errorMsg = errorJson['detail']?.toString() ?? errorJson['message'] ?? response.body;
      } catch (_) {}
      throw Exception("Symptom analysis failed: $errorMsg");
    }
  }

  /// Get comprehensive wellness advice based on symptoms
  Future<Map<String, dynamic>> getWellnessAdvice(Map<String, dynamic> symptomsData) async {
    final url = Uri.parse("$baseUrl/api/v1/symptom-checker/wellness-advice");
    final headers = await _getHeaders();
    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode(symptomsData),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      String errorMsg = response.body;
      try {
        final errorJson = jsonDecode(response.body);
        errorMsg = errorJson['detail']?.toString() ?? errorJson['message'] ?? response.body;
      } catch (_) {}
      throw Exception("Wellness advice failed: $errorMsg");
    }
  }

  /// Get list of all recognized symptoms
  Future<Map<String, dynamic>> getAvailableSymptoms() async {
    final url = Uri.parse("$baseUrl/api/v1/symptom-checker/symptoms");
    final headers = await _getHeaders();
    final response = await http.get(url, headers: headers);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to fetch available symptoms: ${response.body}");
    }
  }

  /// Get detailed information about a specific medical condition
  Future<Map<String, dynamic>> getConditionInfo(String conditionName) async {
    final url = Uri.parse("$baseUrl/api/v1/symptom-checker/conditions/$conditionName");
    final headers = await _getHeaders();
    final response = await http.get(url, headers: headers);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to fetch condition info: ${response.body}");
    }
  }

  /// Health check for symptom checker service
  Future<String> symptomCheckerHealth() async {
    final url = Uri.parse("$baseUrl/api/v1/symptom-checker/health");
    final headers = await _getHeaders();
    final response = await http.get(url, headers: headers);
    if (response.statusCode == 200) {
      // Response is a plain string
      return response.body;
    } else {
      throw Exception("Symptom checker health check failed: ${response.body}");
    }
  }

} // end of class
