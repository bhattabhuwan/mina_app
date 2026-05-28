String parseSpecialty(Map<String, dynamic> map) {
  final doctor = map['doctor'];

  final value = map['specialization'] ??
      map['speciality'] ??
      map['specialty'] ??
      map['doctor_specialization'] ??
      map['doctorSpecialization'] ??
      map['department'] ??
      map['category'] ??
      (doctor is Map ? doctor['specialization'] : null) ??
      (doctor is Map ? doctor['speciality'] : null) ??
      (doctor is Map ? doctor['specialty'] : null) ??
      (doctor is Map ? doctor['department'] : null) ??
      '';

  return value.toString().trim();
}

String specialtyOrFallback(Map<String, dynamic> map) {
  final specialty = parseSpecialty(map);
  return specialty.isNotEmpty ? specialty : 'General Physician';
}
