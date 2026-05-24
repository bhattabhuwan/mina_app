// lib/screen/Counsult_page.dart
import 'package:flutter/material.dart';
import 'package:mina_app/auth/ApiService.dart';
import 'package:mina_app/models/appointment.dart';

class ConsultPage extends StatefulWidget {
  const ConsultPage({super.key});

  @override
  State<ConsultPage> createState() => _ConsultPageState();
}

class _ConsultPageState extends State<ConsultPage> {
  final ApiService _api = ApiService();
  List<Map<String, dynamic>> doctors = [];
  bool _loadingDoctors = true;

  // You can fetch doctors from an API or keep them static
  @override
  void initState() {
    super.initState();
    _fetchDoctors(); // optional if doctors come from backend
  }

  Future<void> _fetchDoctors() async {
    // Replace with actual endpoint if available
    // For now, use static list
    setState(() {
      doctors = const [
        {'name': 'Dr. John Smith', 'specialty': 'Cardiologist', 'rating': 4.8, 'id': 'doc1'},
        {'name': 'Dr. Amy Johnson', 'specialty': 'Dermatologist', 'rating': 4.6, 'id': 'doc2'},
        {'name': 'Dr. Robert Lee', 'specialty': 'Neurologist', 'rating': 4.7, 'id': 'doc3'},
      ];
      _loadingDoctors = false;
    });
  }

  Future<void> _bookAppointment(Map<String, dynamic> doctor, DateTime selectedDate) async {
    try {
      final appointmentData = {
        'doctor_id': doctor['id'],
        'doctor_name': doctor['name'],
        'specialty': doctor['specialty'],
        'date_time': selectedDate.toIso8601String(),
      };
      final result = await _api.createAppointment(appointmentData);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Appointment booked with ${doctor['name']} on ${selectedDate.toString()}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking failed. Please try again.')),
      );
    }
  }

  void _showBookingDialog(Map<String, dynamic> doctor) {
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: Text('Book with ${doctor['name']}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Select date and time:'),
                const SizedBox(height: 10),
                ElevatedButton(
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
                  child: Text('${selectedDate.toLocal()}'.split(' ')[0]),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _bookAppointment(doctor, selectedDate);
                },
                child: const Text('Confirm'),
              ),
            ],
          );
        },
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
          : Padding(
              padding: const EdgeInsets.all(16),
              child: ListView.builder(
                itemCount: doctors.length,
                itemBuilder: (context, index) {
                  final doctor = doctors[index];
                  return _buildDoctorCard(doctor);
                },
              ),
            ),
    );
  }

  Widget _buildDoctorCard(Map<String, dynamic> doctor) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      shadowColor: Colors.blue.shade200,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 40,
              backgroundColor: Colors.lightBlue,
              child: Icon(Icons.medical_services, size: 30, color: Colors.white),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(doctor['name'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(doctor['specialty'], style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 18),
                      const SizedBox(width: 4),
                      Text(doctor['rating'].toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () => _showBookingDialog(doctor),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                backgroundColor: Colors.lightBlue,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Book'),
            ),
          ],
        ),
      ),
    );
  }
}