import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mina_app/auth/ApiService.dart';
import 'package:mina_app/provider/user_provider.dart';
import 'package:mina_app/screen/chat_page.dart';
import 'package:mina_app/screen/video_call_page.dart';
import 'package:mina_app/utils/doctor_utils.dart';
import 'package:mina_app/widgets/profile_avatar.dart';
import 'package:provider/provider.dart';

class ConsultPage extends StatefulWidget {
  const ConsultPage({super.key});

  @override
  State<ConsultPage> createState() => _ConsultPageState();
}

class _ConsultPageState extends State<ConsultPage> {
  final ApiService _api = ApiService();
  List<Map<String, dynamic>> doctors = [];
  bool _loadingDoctors = true;
  bool _startingCall = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchDoctors();
  }

  Future<void> _fetchDoctors() async {
    setState(() {
      _loadingDoctors = true;
      _error = null;
    });

    try {
      final dashboard = await _api.getPatientDashboard();
      final dashboardData = dashboard['data'] is Map ? dashboard['data'] as Map : dashboard;
      var doctorsList = dashboardData['doctors'] as List? ?? [];
      if (doctorsList.isEmpty) {
        doctorsList = await _api.getDoctors();
      }
      final mappedDoctors = doctorsList
          .whereType<Map>()
          .map<Map<String, dynamic>>((doc) => _doctorFromApi(doc))
          .toList();
      final enrichedDoctors = await Future.wait(mappedDoctors.map(_withDoctorRating));

      setState(() {
        doctors = enrichedDoctors;
        _loadingDoctors = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loadingDoctors = false;
      });
    }
  }

  Map<String, dynamic> _doctorFromApi(Map<dynamic, dynamic> doc) {
    final map = Map<String, dynamic>.from(doc);
    final rating = map['rating'];
    return {
      'id': map['id'] ?? map['user_id'] ?? map['doctor_id'],
      'name': map['full_name'] ?? map['name'] ?? 'Dr. Unknown',
      'specialty': parseSpecialty(map),
      'rating': rating is num ? rating.toDouble() : double.tryParse('$rating') ?? 4.5,
      'ratingCount': map['rating_count'] ?? 0,
      'email': map['email'] ?? '',
      'phone': map['phone'] ?? '',
      'experience': map['years_of_experience'] ?? 0,
      'fee': map['consultation_fee'] ?? 0,
      'profileImageUrl': map['profile_image_url'],
      'canChat': map['can_chat'] ?? true,
      'canCall': map['can_call'] ?? false,
      'nextAppointmentId': map['next_appointment_id'],
      'nextAppointmentAt': map['next_appointment_at'],
      'nextAppointmentStatus': map['next_appointment_status'],
    };
  }

  Future<Map<String, dynamic>> _withDoctorRating(Map<String, dynamic> doctor) async {
    final doctorId = doctor['id'];
    if (doctorId == null) return doctor;
    try {
      final ratingData = await _api.getDoctorRating(doctorId);
      final rating = ratingData['rating'];
      return {
        ...doctor,
        'rating': rating is num ? rating.toDouble() : double.tryParse('$rating') ?? doctor['rating'],
        'ratingCount': ratingData['rating_count'] ?? doctor['ratingCount'],
      };
    } catch (_) {
      return doctor;
    }
  }

  Future<void> _bookAppointment(
    Map<String, dynamic> doctor,
    DateTime scheduledAt, {
    String? reason,
    List<String> symptoms = const [],
  }) async {
    final doctorId = doctor['id'];
    if (doctorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid doctor ID. Cannot book appointment.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final patientId = userProvider.userId;
    if (patientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Patient ID not found. Please log in again.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final cleanReason = reason?.trim();
    final appointmentData = {
      'patient_id': patientId,
      'doctor_id': doctorId,
      'scheduled_at': scheduledAt.toIso8601String(),
      'appointment_type': 'video_call',
      'title': cleanReason?.isNotEmpty == true ? cleanReason : 'Consultation',
      if (cleanReason?.isNotEmpty == true) 'description': cleanReason,
      if (symptoms.isNotEmpty) 'symptoms': symptoms,
      'duration_minutes': 30,
    };

    try {
      await _api.createAppointment(appointmentData);
      if (!mounted) return;

      final formattedDate = DateFormat('MMM d, yyyy - h:mm a').format(scheduledAt);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Appointment booked with ${doctor['name']} on $formattedDate'),
          backgroundColor: Colors.green,
        ),
      );
      await _fetchDoctors();
    } catch (e) {
      if (mounted) {
        final errorMsg = e.toString().replaceFirst('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Booking failed: $errorMsg'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _showBookingDialog(Map<String, dynamic> doctor) async {
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    TimeOfDay selectedTime = TimeOfDay.now();
    final reasonController = TextEditingController();
    final symptomsController = TextEditingController();

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: Text('Book with ${doctor['name']}'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 90)),
                            );
                            if (picked != null) {
                              setStateDialog(() => selectedDate = picked);
                            }
                          },
                          icon: const Icon(Icons.calendar_today),
                          label: Text(DateFormat('MMM d').format(selectedDate)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: selectedTime,
                            );
                            if (picked != null) {
                              setStateDialog(() => selectedTime = picked);
                            }
                          },
                          icon: const Icon(Icons.access_time),
                          label: Text(selectedTime.format(context)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: reasonController,
                    decoration: const InputDecoration(
                      labelText: 'Reason for visit',
                      prefixIcon: Icon(Icons.notes),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: symptomsController,
                    decoration: const InputDecoration(
                      labelText: 'Symptoms (comma separated)',
                      prefixIcon: Icon(Icons.healing),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  final combinedDateTime = DateTime(
                    selectedDate.year,
                    selectedDate.month,
                    selectedDate.day,
                    selectedTime.hour,
                    selectedTime.minute,
                  );
                  Navigator.pop(context, {'dateTime': combinedDateTime});
                },
                child: const Text('Confirm'),
              ),
            ],
          );
        },
      ),
    );

    if (result != null && result['dateTime'] != null) {
      final symptoms = symptomsController.text
          .split(',')
          .map((symptom) => symptom.trim())
          .where((symptom) => symptom.isNotEmpty)
          .toList();
      await _bookAppointment(
        doctor,
        result['dateTime'],
        reason: reasonController.text,
        symptoms: symptoms,
      );
    }

    reasonController.dispose();
    symptomsController.dispose();
  }

  Future<void> _startCall(Map<String, dynamic> doctor) async {
    final appointmentId = doctor['nextAppointmentId'] ??
        await _api.findAppointmentIdWithParticipant(doctor['id'].toString());
    if (!mounted) return;
    if (appointmentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Book an appointment before starting a call.')),
      );
      return;
    }

    setState(() => _startingCall = true);
    try {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VideoCallPage(
            appointmentId: appointmentId,
            title: 'Call with ${doctor['name'] ?? 'Doctor'}',
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Call failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _startingCall = false);
    }
  }

  void _openChat(Map<String, dynamic> doctor) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatPage(
          participantId: doctor['id'].toString(),
          participantName: doctor['name'] ?? 'Dr. Unknown',
          participantRole: 'doctor',
          participantAvatar: doctor['name']?[0] ?? '?',
          appointmentId: doctor['nextAppointmentId'],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: AppBar(
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.lightBlue.shade400, Colors.lightBlue.shade700],
              ),
            ),
          ),
          title: const Text('Consult a Doctor', style: TextStyle(fontSize: 22)),
          centerTitle: true,
          elevation: 6,
        ),
      ),
      body: _loadingDoctors
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text('Error: $_error', textAlign: TextAlign.center),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(onPressed: _fetchDoctors, child: const Text('Retry')),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchDoctors,
                  child: doctors.isEmpty
                      ? const Center(child: Text('No doctors available'))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: doctors.length,
                          itemBuilder: (context, index) => _buildDoctorCard(doctors[index]),
                        ),
                ),
    );
  }

  Widget _buildDoctorCard(Map<String, dynamic> doctor) {
    final isDoctor = Provider.of<UserProvider>(context).role.toLowerCase() == 'doctor';
    final nextAppointmentAt = DateTime.tryParse(doctor['nextAppointmentAt'] ?? '');

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ProfileAvatar(
              imagePathOrUrl: doctor['profileImageUrl'],
              radius: 38,
              iconSize: 30,
              backgroundColor: Colors.lightBlue,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doctor['name'],
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    doctor['specialty'].toString().trim().isNotEmpty
                        ? doctor['specialty'].toString()
                        : 'General Physician',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        doctor['rating'].toStringAsFixed(1),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        ' (${doctor['ratingCount'] ?? 0})',
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      if ((doctor['fee'] ?? 0) > 0) ...[
                        const SizedBox(width: 12),
                        Text('Fee: ${doctor['fee']}'),
                      ],
                    ],
                  ),
                  if (nextAppointmentAt != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Next: ${DateFormat('MMM d, h:mm a').format(nextAppointmentAt.toLocal())}',
                      style: TextStyle(color: Colors.green.shade700, fontSize: 12),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: doctor['canChat'] == false ? null : () => _openChat(doctor),
                        icon: const Icon(Icons.message, size: 18),
                        label: const Text('Message'),
                      ),
                      if (isDoctor)
                        OutlinedButton.icon(
                          onPressed: _startingCall ? null : () => _startCall(doctor),
                          icon: const Icon(Icons.videocam, size: 18),
                          label: const Text('Call'),
                        ),
                      ElevatedButton.icon(
                        onPressed: () => _showBookingDialog(doctor),
                        icon: const Icon(Icons.calendar_today, size: 18),
                        label: const Text('Book'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
