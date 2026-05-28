import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:mina_app/auth/ApiService.dart';
import 'package:mina_app/auth/auth_service.dart';
import 'package:mina_app/provider/user_provider.dart';
import 'package:mina_app/screen/chat_page.dart';
import 'package:mina_app/screen/video_call_page.dart';
import 'package:mina_app/widgets/profile_avatar.dart';
import 'package:provider/provider.dart';

enum _DoctorDashboardTab { patients, appointments, unread, chats }

class DoctorHome extends StatefulWidget {
  const DoctorHome({super.key});

  @override
  State<DoctorHome> createState() => _DoctorHomeState();
}

class _DoctorHomeState extends State<DoctorHome> {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _dashboardData;
  Map<String, dynamic>? _doctorProfile;
  _DoctorDashboardTab _selectedTab = _DoctorDashboardTab.patients;

  @override
  void initState() {
    super.initState();
    _fetchDashboard();
  }

  Future<void> _fetchDashboard() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final api = ApiService();
      final data = await api.getDoctorDashboard();
      Map<String, dynamic>? profile;
      try {
        profile = await api.getDoctorDashboardProfile();
      } catch (_) {
        profile = null;
      }
      if (mounted) {
        setState(() {
          _dashboardData = data;
          _doctorProfile = profile;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _logout(BuildContext context) async {
    final api = ApiService();
    await api.logout();
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    await userProvider.clearUserData();
    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AuthPage()),
      );
    }
  }

  Future<void> _pickProfileImage(ImageSource source) async {
    try {
      final pickedFile = await ImagePicker().pickImage(
        source: source,
        imageQuality: 80,
      );
      if (pickedFile == null) return;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Uploading profile picture...')),
        );
      }

      final api = ApiService();
      final updatedUser = await api.uploadProfilePicture(pickedFile.path);
      final data = updatedUser['data'] ?? updatedUser;
      final imageUrl = data['profile_image_url'] as String?;
      if (imageUrl == null || imageUrl.isEmpty) {
        throw Exception('Profile image URL missing from server response');
      }

      if (!mounted) return;
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await userProvider.updateUser(
        fullName: data['full_name'] ?? userProvider.fullName,
        email: data['email'] ?? userProvider.email,
        profileImagePath: imageUrl,
        role: data['role'] ?? userProvider.role,
        userId: data['id'] ?? userProvider.userId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile picture updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload profile picture: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showProfileImagePickerDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take a photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickProfileImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickProfileImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPatientDetails(Map<String, dynamic> patient) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: const Color(0xFF5C5FFF),
                    child: const Icon(Icons.person, size: 40, color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          patient['full_name'] ?? 'Unknown',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          patient['email'] ?? 'No email',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    _buildDetailTile('Phone', patient['phone'] ?? 'Not provided'),
                    _buildDetailTile('Gender', patient['gender'] ?? 'Not specified'),
                    _buildDetailTile(
                      'Date of Birth',
                      patient['date_of_birth'] != null
                          ? DateFormat('MMM d, yyyy').format(
                              DateTime.parse(patient['date_of_birth']),
                            )
                          : 'Not provided',
                    ),
                    _buildDetailTile('Address', patient['address'] ?? 'Not provided'),
                    _buildDetailTile(
                      'Emergency Contact',
                      patient['emergency_contact'] ?? 'Not provided',
                    ),
                    _buildDetailTile(
                      'Medical Conditions',
                      (patient['medical_conditions'] as List?)?.isNotEmpty == true
                          ? (patient['medical_conditions'] as List).join(', ')
                          : 'None',
                    ),
                    _buildDetailTile(
                      'Allergies',
                      (patient['allergies'] as List?)?.isNotEmpty == true
                          ? (patient['allergies'] as List).join(', ')
                          : 'None',
                    ),
                    _buildDetailTile(
                      'Current Medications',
                      (patient['current_medications'] as List?)?.isNotEmpty == true
                          ? (patient['current_medications'] as List).join(', ')
                          : 'None',
                    ),
                    if (patient['profile_image_url'] != null &&
                        patient['profile_image_url'].isNotEmpty)
                      _buildDetailTile('Profile Image', 'Available'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.message),
                  label: const Text('Message Patient'),
                  onPressed: () {
                    final patientId = patient['id'];
                    final patientName = patient['full_name'] ?? 'Patient';
                    if (patientId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Cannot open chat: Patient ID not found')),
                      );
                      return;
                    }
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatPage(
                          participantId: patientId.toString(),
                          participantName: patientName,
                          participantRole: 'patient',
                          participantAvatar: patientName.isNotEmpty ? patientName[0] : '?',
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 16),
          ),
          const Divider(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final doctorName = userProvider.fullName;

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Doctor Dashboard'),
          backgroundColor: const Color(0xFF5C5FFF),
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $_error'),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _fetchDashboard,
                child: const Text('Retry'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => _logout(context),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Logout'),
              ),
            ],
          ),
        ),
      );
    }

    final List<dynamic> patients = _dashboardData?['patients'] ?? [];
    final List<dynamic> schedule = _dashboardData?['schedule'] ?? [];
    final List<dynamic> recentConversations = _dashboardData?['recent_conversations'] ?? [];
    final Map<String, dynamic> unread = _dashboardData?['unread'] ?? {};
    final int totalUnread = unread['total_unread'] ?? 0;
    final specialization = _doctorProfile?['specialization']?.toString();

    final today = DateTime.now();
    final todayAppointments = schedule.where((apt) {
      final scheduledAt = DateTime.tryParse(apt['scheduled_at'] ?? '');
      return scheduledAt != null &&
          scheduledAt.year == today.year &&
          scheduledAt.month == today.month &&
          scheduledAt.day == today.day;
    }).toList();

    final futureAppointments = schedule.where((apt) {
      final scheduledAt = DateTime.tryParse(apt['scheduled_at'] ?? '');
      final status = apt['status']?.toString().toLowerCase();
      final isClosed = status == 'completed' || status == 'cancelled' || status == 'no_show';
      final tomorrow = DateTime(today.year, today.month, today.day + 1);
      return scheduledAt != null && !scheduledAt.isBefore(tomorrow) && !isClosed;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Doctor Dashboard'),
        backgroundColor: const Color(0xFF5C5FFF),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.photo_camera),
            onPressed: _showProfileImagePickerDialog,
            tooltip: 'Upload photo',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchDashboard,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Card
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF5C5FFF),
                        const Color(0xFF5C5FFF).withOpacity(0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: _showProfileImagePickerDialog,
                            child: ProfileAvatar(
                              imagePathOrUrl: userProvider.profileImageUrl,
                              radius: 34,
                              iconSize: 30,
                              backgroundColor: Colors.white24,
                              showCameraBadge: true,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Welcome back,', style: TextStyle(color: Colors.white70, fontSize: 16)),
                                const SizedBox(height: 4),
                                Text(doctorName, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                                if (specialization != null && specialization.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(specialization, style: const TextStyle(color: Colors.white, fontSize: 15)),
                                ],
                                const SizedBox(height: 8),
                                Text('You have $totalUnread unread items', style: const TextStyle(color: Colors.white70, fontSize: 14)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Stats Cards
              const Text('Today\'s Overview', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF5C5FFF))),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildInfoCard(_DoctorDashboardTab.patients, 'Patients', patients.length.toString(), Icons.people, Colors.green)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildInfoCard(_DoctorDashboardTab.appointments, 'Today\'s Appts', todayAppointments.length.toString(), Icons.calendar_today, Colors.blue)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildInfoCard(_DoctorDashboardTab.unread, 'Unread Messages', totalUnread.toString(), Icons.chat_bubble_outline, Colors.orange)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildInfoCard(_DoctorDashboardTab.chats, 'Recent Chats', recentConversations.length.toString(), Icons.message, Colors.purple)),
                ],
              ),
              const SizedBox(height: 24),
              _buildSelectedTabContent(
                patients: patients,
                todayAppointments: todayAppointments,
                futureAppointments: futureAppointments,
                recentConversations: recentConversations,
                totalUnread: totalUnread,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToAppointmentDetail(BuildContext context, Map<String, dynamic> appointment, List<dynamic> patients) {
    final patientId = appointment['patient_id'];
    final patient = patients.firstWhere(
      (p) => p['id'] == patientId,
      orElse: () => {},
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AppointmentDetailPage(
          appointment: appointment,
          patient: patient,
        ),
      ),
    ).then((_) => _fetchDashboard());
  }

  Widget _buildInfoCard(_DoctorDashboardTab tab, String title, String value, IconData icon, Color color) {
    final isSelected = _selectedTab == tab;
    return Card(
      elevation: isSelected ? 5 : 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => setState(() => _selectedTab = tab),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: isSelected ? color : Colors.transparent, width: 2),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 8),
              Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(title, style: TextStyle(color: Colors.grey.shade600, fontSize: 14), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedTabContent({
    required List<dynamic> patients,
    required List<dynamic> todayAppointments,
    required List<dynamic> futureAppointments,
    required List<dynamic> recentConversations,
    required int totalUnread,
  }) {
    switch (_selectedTab) {
      case _DoctorDashboardTab.patients:
        return _buildPatientsSection(patients);
      case _DoctorDashboardTab.appointments:
        return Column(
          children: [
            _buildAppointmentsSection('Today\'s Appointments', todayAppointments, patients, showDate: false),
            const SizedBox(height: 24),
            _buildAppointmentsSection('Upcoming Appointments', futureAppointments, patients, maxItems: 5),
          ],
        );
      case _DoctorDashboardTab.unread:
        final unreadConversations = recentConversations.where((conv) {
          final count = conv is Map ? conv['unread_count'] : 0;
          final parsedCount = count is num ? count : int.tryParse('$count') ?? 0;
          return parsedCount > 0;
        }).toList();
        return _buildConversationsSection('Unread Messages ($totalUnread)', unreadConversations, emptyText: 'No unread messages');
      case _DoctorDashboardTab.chats:
        return _buildConversationsSection('Recent Conversations', recentConversations, maxItems: 5, emptyText: 'No recent conversations');
    }
  }

  Widget _buildPatientsSection(List<dynamic> patients) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('My Patients', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF5C5FFF))),
        const SizedBox(height: 12),
        patients.isEmpty
            ? const Card(child: Padding(padding: EdgeInsets.all(16), child: Center(child: Text('No patients assigned yet'))))
            : ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: patients.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final patient = patients[index];
                  return Card(
                    elevation: 2,
                    child: ListTile(
                      leading: const CircleAvatar(backgroundColor: Color(0xFF5C5FFF), child: Icon(Icons.person, color: Colors.white)),
                      title: Text(patient['full_name'] ?? 'Unknown'),
                      subtitle: Text(patient['email'] ?? 'No email'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _showPatientDetails(patient),
                    ),
                  );
                },
              ),
      ],
    );
  }

  Widget _buildAppointmentsSection(String title, List<dynamic> appointments, List<dynamic> patients, {bool showDate = true, int? maxItems}) {
    final visibleAppointments = maxItems == null ? appointments : appointments.take(maxItems).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF5C5FFF))),
        const SizedBox(height: 12),
        visibleAppointments.isEmpty
            ? Card(child: Padding(padding: const EdgeInsets.all(16), child: Center(child: Text(title.contains('Today') ? 'No appointments today' : 'No future appointments'))))
            : ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: visibleAppointments.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final apt = visibleAppointments[index];
                  final patientName = apt['patient_name'] ?? 'Patient';
                  final scheduledAt = DateTime.tryParse(apt['scheduled_at'] ?? '');
                  final formatted = scheduledAt != null
                      ? DateFormat(showDate ? 'MMM d, h:mm a' : 'h:mm a').format(scheduledAt)
                      : 'Date not set';
                  final status = apt['status'] ?? 'scheduled';
                  final statusColor = _statusColor(status.toString());
                  return Card(
                    elevation: 2,
                    child: ListTile(
                      leading: const CircleAvatar(backgroundColor: Color(0xFF5C5FFF), child: Icon(Icons.person, color: Colors.white)),
                      title: Text(patientName),
                      subtitle: Text(formatted),
                      trailing: Chip(label: Text(status), backgroundColor: statusColor, labelStyle: const TextStyle(color: Colors.white)),
                      onTap: () => _navigateToAppointmentDetail(context, apt, patients),
                    ),
                  );
                },
              ),
      ],
    );
  }

  Widget _buildConversationsSection(String title, List<dynamic> conversations, {int? maxItems, required String emptyText}) {
    final visibleConversations = maxItems == null ? conversations : conversations.take(maxItems).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF5C5FFF))),
        const SizedBox(height: 12),
        visibleConversations.isEmpty
            ? Card(child: Padding(padding: const EdgeInsets.all(16), child: Center(child: Text(emptyText))))
            : ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: visibleConversations.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final conv = visibleConversations[index];
                  final partnerName = conv['partner_name'] ?? 'Unknown';
                  final partnerId = conv['partner_id'];
                  final partnerRole = conv['partner_role'] ?? 'patient';
                  final lastMessage = conv['last_message'] ?? '';
                  final lastMessageTime = DateTime.tryParse(conv['last_message_time'] ?? '');
                  final formattedTime = lastMessageTime != null ? DateFormat('MMM d, h:mm a').format(lastMessageTime) : '';
                  final unreadCount = conv['unread_count'] ?? 0;
                  return Card(
                    elevation: 2,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: unreadCount > 0 ? Colors.red : const Color(0xFF5C5FFF),
                        child: Text(partnerName.isNotEmpty ? partnerName[0].toUpperCase() : '?', style: const TextStyle(color: Colors.white)),
                      ),
                      title: Text(partnerName, style: TextStyle(fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal)),
                      subtitle: Text(lastMessage),
                      trailing: unreadCount > 0
                          ? Chip(label: Text('$unreadCount new'), backgroundColor: Colors.red, labelStyle: const TextStyle(color: Colors.white))
                          : Text(formattedTime, style: const TextStyle(fontSize: 12)),
                      onTap: partnerId == null
                          ? null
                          : () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ChatPage(
                                    participantId: partnerId.toString(),
                                    participantName: partnerName,
                                    participantRole: partnerRole,
                                    appointmentId: conv['appointment_id'],
                                  ),
                                ),
                              ).then((_) => _fetchDashboard()),
                    ),
                  );
                },
              ),
      ],
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
      case 'completed':
        return Colors.green;
      case 'cancelled':
      case 'no_show':
        return Colors.red;
      case 'in_progress':
        return Colors.blue;
      default:
        return Colors.orange;
    }
  }
}

// ==================== Appointment Detail Page ====================
class AppointmentDetailPage extends StatefulWidget {
  final Map<String, dynamic> appointment;
  final Map<String, dynamic> patient;

  const AppointmentDetailPage({super.key, required this.appointment, required this.patient});

  @override
  State<AppointmentDetailPage> createState() => _AppointmentDetailPageState();
}

class _AppointmentDetailPageState extends State<AppointmentDetailPage> {
  late Map<String, dynamic> _appointment;
  bool _isUpdating = false;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _appointment = widget.appointment;
  }

  Future<void> _updateAppointmentStatus(String newStatus) async {
    final currentStatus = _appointment['status']?.toString().toLowerCase() ?? 'scheduled';
    if (_isTerminalStatus(currentStatus)) {
      _showStatusMessage('This appointment is already closed.', isError: true);
      return;
    }
    if (newStatus == 'completed' && currentStatus == 'scheduled') {
      _showStatusMessage('Start or confirm the appointment before marking it complete.', isError: true);
      return;
    }

    setState(() => _isUpdating = true);
    try {
      await _apiService.updateAppointmentStatus(_appointment['id'], newStatus);
      setState(() {
        _appointment['status'] = newStatus;
        _isUpdating = false;
      });
      if (mounted) {
        final message = newStatus == 'completed'
            ? 'Appointment completed'
            : newStatus == 'cancelled'
                ? 'Appointment cancelled'
                : 'Appointment status updated to ${_statusLabel(newStatus)}';
        _showStatusMessage(message);
      }
    } catch (e) {
      setState(() => _isUpdating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _startVideoCall(BuildContext context) async {
    try {
      final patientName = widget.patient['full_name'] ?? widget.appointment['patient_name'] ?? 'Patient';
      final patientId = widget.patient['id'] ?? widget.appointment['patient_id'];
      final appointmentId = _appointment['id'];
      if (patientId != null && appointmentId != null) {
        final parsedAppointmentId = appointmentId is int
            ? appointmentId
            : int.tryParse(appointmentId.toString());
        if (parsedAppointmentId != null) {
          await _apiService.sendCallInvitation(
            recipientId: patientId.toString(),
            appointmentId: parsedAppointmentId,
          );
        }
      }
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VideoCallPage(
            appointmentId: _appointment['id'],
            title: 'Call with $patientName',
          ),
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start call: $e')),
        );
      }
    }
  }

  bool _isTerminalStatus(String status) {
    return status == 'completed' || status == 'cancelled' || status == 'no_show';
  }

  String _statusLabel(String status) {
    return status.replaceAll('_', ' ').split(' ').map((word) {
      if (word.isEmpty) return word;
      return '${word[0].toUpperCase()}${word.substring(1)}';
    }).join(' ');
  }

  void _showStatusMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  void _sendMessage(BuildContext context) {
    final patientName = widget.patient['full_name'] ?? widget.appointment['patient_name'] ?? 'Patient';
    final patientId = widget.patient['id'] ?? widget.appointment['patient_id'];
    
    if (patientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot open chat: Patient ID not found')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatPage(
          participantId: patientId.toString(),
          participantName: patientName,
          participantRole: 'patient',
          participantAvatar: patientName.isNotEmpty ? patientName[0] : '?',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheduledAt = DateTime.tryParse(_appointment['scheduled_at'] ?? '');
    final formattedDateTime = scheduledAt != null
        ? DateFormat('EEEE, MMM d, yyyy – h:mm a').format(scheduledAt)
        : 'Date not set';
    final status = _appointment['status']?.toString() ?? 'scheduled';
    final statusText = status.toLowerCase();
    final isClosed = _isTerminalStatus(statusText);
    final patientName = widget.patient['full_name'] ?? _appointment['patient_name'] ?? 'Patient';

    return Scaffold(
      appBar: AppBar(
        title: Text('Appointment with $patientName'),
        backgroundColor: const Color(0xFF5C5FFF),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Patient Info Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 35,
                      backgroundColor: const Color(0xFF5C5FFF),
                      child: const Icon(Icons.person, size: 35, color: Colors.white),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(patientName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(widget.patient['email'] ?? 'No email', style: const TextStyle(color: Colors.grey)),
                          const SizedBox(height: 4),
                          Text(widget.patient['phone'] ?? 'No phone', style: const TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Appointment Details Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Appointment Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const Divider(),
                    _buildDetailRow('Date & Time', formattedDateTime),
                    _buildDetailRow('Status', status),
                    _buildDetailRow('Type', _appointment['appointment_type']?.toString() ?? 'Video Call'),
                    if (_appointment['title'] != null)
                      _buildDetailRow('Title', _appointment['title'].toString()),
                    if (_appointment['description'] != null)
                      _buildDetailRow('Description', _appointment['description'].toString()),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            _buildStatusActions(statusText, isClosed),
            const SizedBox(height: 30),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.chat),
                    label: const Text('Message'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => _sendMessage(context),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.videocam),
                    label: const Text('Video Call'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5C5FFF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: isClosed ? null : () => _startVideoCall(context),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildStatusActions(String status, bool isClosed) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Appointment Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            if (_isUpdating) const CircularProgressIndicator(),
            if (!_isUpdating && isClosed)
              Text(
                status == 'completed'
                    ? 'Appointment complete'
                    : status == 'cancelled'
                        ? 'Appointment cancelled'
                        : 'Appointment closed as no-show',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            if (!_isUpdating && !isClosed)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (status == 'scheduled')
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => _updateAppointmentStatus('confirmed'),
                      child: const Text('Confirm'),
                    ),
                  if (status == 'scheduled' || status == 'confirmed')
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => _updateAppointmentStatus('in_progress'),
                      child: const Text('Start'),
                    ),
                  if (status == 'confirmed' || status == 'in_progress')
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => _updateAppointmentStatus('completed'),
                      child: const Text('Mark Complete'),
                    ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => _confirmStatusChange(
                      title: 'Cancel appointment?',
                      message: 'This will cancel the appointment and close it for both sides.',
                      status: 'cancelled',
                    ),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => _confirmStatusChange(
                      title: 'Mark no-show?',
                      message: 'Use no-show only when the patient did not attend.',
                      status: 'no_show',
                    ),
                    child: const Text('No Show'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmStatusChange({
    required String title,
    required String message,
    required String status,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Keep Appointment')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirm')),
        ],
      ),
    );
    if (confirmed == true) {
      await _updateAppointmentStatus(status);
    }
  }
}
