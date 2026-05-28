import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mina_app/auth/ApiService.dart';
import 'package:mina_app/theme/theme_manager.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SymptomsCheckerPage extends StatefulWidget {
  const SymptomsCheckerPage({super.key});

  @override
  State<SymptomsCheckerPage> createState() => _SymptomsCheckerPageState();
}

class _SymptomsCheckerPageState extends State<SymptomsCheckerPage> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  final ApiService _apiService = ApiService();

  bool _loading = false;
  bool _loadingSymptoms = false;
  List<String> _availableSymptoms = [];

  final Map<String, List<Map<String, dynamic>>> _localConditions = {
    'cough': [
      {
        'condition': 'Common Cold',
        'confidence': 75.0,
        'severity': 'mild',
        'recommendations': [
          'Rest and stay hydrated',
          'Use honey or lozenges for sore throat',
          'Use an over-the-counter cough suppressant if needed',
          'Consult a doctor if symptoms persist beyond 7 days',
        ],
      },
      {
        'condition': 'Allergic Rhinitis',
        'confidence': 40.0,
        'severity': 'mild',
        'recommendations': [
          'Avoid known allergens',
          'Use antihistamines when appropriate',
          'Keep windows closed during high pollen seasons',
        ],
      },
    ],
    'fever': [
      {
        'condition': 'Viral Infection',
        'confidence': 80.0,
        'severity': 'moderate',
        'recommendations': [
          'Rest and stay hydrated',
          'Take acetaminophen or ibuprofen for fever if safe for you',
          'Seek help if fever is high or persistent',
        ],
      },
    ],
    'headache': [
      {
        'condition': 'Tension Headache',
        'confidence': 70.0,
        'severity': 'mild',
        'recommendations': [
          'Rest in a quiet, dark room',
          'Apply a cold or warm compress',
          'Stay hydrated',
        ],
      },
    ],
    'fatigue': [
      {
        'condition': 'Sleep Deprivation',
        'confidence': 65.0,
        'severity': 'mild',
        'recommendations': [
          'Improve sleep hygiene',
          'Take short rests during the day',
          'Eat balanced meals and stay hydrated',
        ],
      },
    ],
    'chest pain': [
      {
        'condition': 'Possible Cardiac or Respiratory Concern',
        'confidence': 60.0,
        'severity': 'urgent',
        'recommendations': [
          'Seek urgent medical care for severe or persistent chest pain',
          'Call emergency services if pain occurs with shortness of breath, sweating, or fainting',
        ],
      },
    ],
    'shortness of breath': [
      {
        'condition': 'Respiratory Distress',
        'confidence': 65.0,
        'severity': 'urgent',
        'recommendations': [
          'Avoid exertion and sit upright',
          'Seek urgent care if breathing difficulty is new, severe, or worsening',
        ],
      },
    ],
  };

  @override
  void initState() {
    super.initState();
    _fetchSymptoms();
    _addMessage('Welcome\nSelect chips or type multiple symptoms to analyze.', false);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _addMessage(String text, bool isUser) {
    setState(() {
      _messages.add({'text': text, 'isUser': isUser});
    });
  }

  Future<void> _fetchSymptoms() async {
    setState(() => _loadingSymptoms = true);

    try {
      final data = await _apiService.getAvailableSymptoms();
      setState(() {
        _availableSymptoms = List<String>.from(data['symptoms'] ?? []);
      });
    } catch (_) {
      setState(() {
        _availableSymptoms = [
          'cough',
          'fever',
          'headache',
          'fatigue',
          'sore throat',
          'nausea',
          'dizziness',
          'chest pain',
          'shortness of breath',
        ];
      });
      _addMessage('Using offline symptom list. Some features may be limited.', false);
    } finally {
      if (mounted) setState(() => _loadingSymptoms = false);
    }
  }

  List<String> _parseSymptoms(String input) {
    final raw = input.trim().toLowerCase();
    if (raw.isEmpty) return [];

    final symptoms = <String>{};
    final normalizedInput = raw.replaceAll(RegExp(r'\s+'), ' ');

    final knownSymptoms = _availableSymptoms
        .map((symptom) => symptom.trim().toLowerCase())
        .where((symptom) => symptom.isNotEmpty)
        .toList()
      ..sort((a, b) => b.length.compareTo(a.length));

    for (final symptom in knownSymptoms) {
      final pattern = RegExp(
        r'(^|[^a-z])' + RegExp.escape(symptom) + r'([^a-z]|$)',
        caseSensitive: false,
      );
      if (pattern.hasMatch(normalizedInput)) {
        symptoms.add(symptom);
      }
    }

    final splitParts = raw
        .split(RegExp(r'[,;\n]+|\s+(?:and|with|plus)\s+', caseSensitive: false))
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty);

    for (final part in splitParts) {
      symptoms.add(part);
    }

    return symptoms.toList();
  }

  String _getLocalAnalysis(List<String> symptoms) {
    final matches = <Map<String, dynamic>>[];

    for (final symptom in symptoms) {
      final lowerSymptom = symptom.toLowerCase();
      final symptomMatches = _localConditions.entries
          .where((entry) =>
              lowerSymptom.contains(entry.key) || entry.key.contains(lowerSymptom))
          .expand((entry) => entry.value);
      matches.addAll(symptomMatches);
    }

    if (matches.isEmpty) {
      return 'AI Medical Analysis (Offline)\n\n'
          'No specific conditions matched: ${symptoms.join(', ')}.\n\n'
          'General tips:\n'
          '- Rest and stay hydrated\n'
          '- Monitor your symptoms\n'
          '- Consult a healthcare professional if symptoms worsen\n\n'
          'This is not a medical diagnosis.';
    }

    final buffer = StringBuffer('AI Medical Analysis (Offline)\n\nPossible Conditions:\n');
    final seen = <String>{};
    for (final match in matches) {
      final condition = match['condition']?.toString() ?? 'Unknown';
      if (!seen.add(condition)) continue;
      buffer.writeln('- $condition (${match['confidence']}%) - ${match['severity']}');
      final recommendations = match['recommendations'] as List? ?? [];
      if (recommendations.isNotEmpty) {
        buffer.writeln('  Recommendations:');
        for (final recommendation in recommendations) {
          buffer.writeln('  - $recommendation');
        }
      }
      buffer.writeln();
    }
    buffer.write('This is not a medical diagnosis.');
    return buffer.toString();
  }

  Future<void> _analyzeSymptoms(List<String> symptoms) async {
    if (symptoms.isEmpty) return;

    _addMessage(symptoms.join(', '), true);
    setState(() => _loading = true);

    try {
      final data = await _apiService.analyzeSymptoms({'symptoms': symptoms});
      final predictions = data['predictions'] as List?;
      final validSymptoms = List<String>.from(data['valid_symptoms'] ?? []);
      final unknownSymptoms = List<String>.from(data['unknown_symptoms'] ?? []);

      final buffer = StringBuffer('AI Medical Analysis\n\n');
      if (validSymptoms.isNotEmpty) {
        buffer.writeln('Recognized symptoms: ${validSymptoms.join(', ')}\n');
      }
      if (unknownSymptoms.isNotEmpty) {
        buffer.writeln('Not recognized: ${unknownSymptoms.join(', ')}\n');
      }

      if (predictions != null && predictions.isNotEmpty) {
        buffer.writeln('Possible Conditions:');
        for (final prediction in predictions) {
          final condition = prediction['condition'] ?? 'Unknown';
          final confidence = (prediction['confidence'] ?? 0).toDouble();
          final severity = prediction['severity'] ?? 'unknown';
          buffer.writeln('- $condition (${confidence.toStringAsFixed(1)}%) - $severity');

          final recommendations = prediction['recommendations'] as List?;
          if (recommendations != null && recommendations.isNotEmpty) {
            buffer.writeln('  Recommendations:');
            for (final recommendation in recommendations) {
              buffer.writeln('  - $recommendation');
            }
          }
        }
        buffer.writeln();
        buffer.write(data['disclaimer'] ??
            'This is not a medical diagnosis. Always consult a healthcare professional.');
        _addMessage(buffer.toString(), false);
      } else {
        _addMessage(_getLocalAnalysis(symptoms), false);
      }
    } catch (e) {
      final errorMsg = e.toString();
      if (errorMsg.contains('unordered_map::at') ||
          errorMsg.contains('Unknown') ||
          errorMsg.contains('not recognized')) {
        _addMessage(_getLocalAnalysis(symptoms), false);
      } else {
        _addMessage('Analysis failed: $errorMsg', false);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _uploadFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any);
    if (result == null || result.files.single.path == null) return;

    final file = File(result.files.single.path!);
    final fileName = result.files.single.name;

    _addMessage('Uploading $fileName...', true);
    setState(() => _loading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${_apiService.baseUrl}/api/v1/documents/upload'),
      );

      request.headers.addAll({
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      });
      request.fields['folder'] = 'medical_files';
      request.fields['description'] = 'Uploaded from Flutter app';
      request.files.add(await http.MultipartFile.fromPath('file', file.path));

      final response = await http.Response.fromStream(await request.send());
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final message = data is Map
            ? data['message'] ?? data['result'] ?? data['file_url'] ?? 'Upload successful'
            : data.toString();
        _addMessage('Document Upload Result\n\n$message', false);
      } else {
        _addMessage('Upload failed (${response.statusCode})', false);
      }
    } catch (e) {
      _addMessage('Upload error: $e', false);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _send() {
    final symptoms = _parseSymptoms(_controller.text);
    if (symptoms.isEmpty) return;
    _controller.clear();
    _analyzeSymptoms(symptoms);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeManager>(context).isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.blue.shade50,
      appBar: AppBar(title: const Text('Symptoms Checker')),
      body: Column(
        children: [
          if (_loadingSymptoms)
            const LinearProgressIndicator()
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                children: _availableSymptoms.take(12).map((symptom) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      label: Text(symptom),
                      onPressed: () => _analyzeSymptoms([symptom]),
                    ),
                  );
                }).toList(),
              ),
            ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isUser = message['isUser'] == true;
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.82,
                    ),
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.blue : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      message['text'] ?? '',
                      style: TextStyle(color: isUser ? Colors.white : Colors.black87),
                    ),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.attach_file),
                    onPressed: _loading ? null : _uploadFile,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: 'Enter symptoms, e.g. fever, cough',
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: _loading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                    onPressed: _loading ? null : _send,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
