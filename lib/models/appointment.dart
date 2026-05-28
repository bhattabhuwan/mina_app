import 'package:mina_app/utils/doctor_utils.dart';

class Appointment {
  final String id;
  final String doctorId;
  final String doctorName;
  final String specialty;
  final DateTime dateTime;
  final String status; // e.g., "scheduled", "completed", "cancelled"
  final String? videoCallUrl;

  Appointment({
    required this.id,
    required this.doctorId,
    required this.doctorName,
    required this.specialty,
    required this.dateTime,
    required this.status,
    this.videoCallUrl,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) => Appointment(
    id: json['id'],
    doctorId: json['doctor_id'],
    doctorName: json['doctor_name'],
    specialty: specialtyOrFallback(json),
    dateTime: DateTime.parse(json['date_time']),
    status: json['status'],
    videoCallUrl: json['video_call_url'],
  );
}
