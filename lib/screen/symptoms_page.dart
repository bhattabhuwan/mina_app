import 'dart:async';
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
  final ScrollController _scrollController = ScrollController();

  bool _loading = false;
  bool _loadingSymptoms = false;
  List<String> _availableSymptoms = [];

  @override
  void initState() {
    super.initState();
    _fetchSymptoms();
    _addMessage(
      'Welcome to AI Symptom Checker\nSelect chips or type your symptoms (e.g., fever, chest pain).',
      false,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _addMessage(String text, bool isUser) {
    setState(() {
      _messages.add({'text': text, 'isUser': isUser});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  Future<void> _fetchSymptoms() async {
    setState(() => _loadingSymptoms = true);

    try {
      final data = await _apiService.getAvailableSymptoms();
      setState(() {
        _availableSymptoms = List<String>.from(data['symptoms'] ?? []);
      });
    } catch (e) {
      // Fallback to a default list if API fails, but we still try backend analysis later.
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
      _addMessage('Could not load symptom list from server. Using default list.', false);
    } finally {
      if (mounted) setState(() => _loadingSymptoms = false);
    }
  }

  // Simple symptom parsing: split by commas, semicolons, 'and', 'with', 'plus'
  List<String> _parseSymptoms(String input) {
    final raw = input.trim().toLowerCase();
    if (raw.isEmpty) return [];

    final parts = raw.split(RegExp(r'[,;\n]+|\s+(?:and|with|plus)\s+'));
    return parts.map((p) => p.trim()).where((p) => p.isNotEmpty).toList();
  }

  Future<void> _analyzeSymptoms(List<String> symptoms) async {
    if (symptoms.isEmpty) return;

    _addMessage(symptoms.join(', '), true);
    setState(() => _loading = true);

    try {
      final request = {'symptoms': symptoms};
      final data = await _apiService.analyzeSymptoms(request);

      Map<String, dynamic>? wellness;
      try {
        wellness = await _apiService.getWellnessAdvice(request);
      } catch (e) {
        // Wellness advice is optional; continue without it.
      }

      final predictions = data['predictions'] as List?;
      final validSymptoms = List<String>.from(data['valid_symptoms'] ?? []);
      final unknownSymptoms = List<String>.from(data['unknown_symptoms'] ?? []);

      final buffer = StringBuffer('AI Medical Analysis\n\n');
      if (validSymptoms.isNotEmpty) {
        buffer.writeln('✅ Recognized: ${validSymptoms.join(', ')}\n');
      }
      if (unknownSymptoms.isNotEmpty) {
        buffer.writeln('⚠️ Not recognized: ${unknownSymptoms.join(', ')}\n');
      }

      if (predictions == null || predictions.isEmpty) {
        buffer.writeln('No conditions could be identified from the symptoms provided.');
        buffer.writeln('Please consult a healthcare professional for further evaluation.');
        _addMessage(buffer.toString(), false);
        return;
      }

      buffer.writeln('📋 Possible Conditions:');
      for (final prediction in predictions) {
        final condition = prediction['condition'] ?? 'Unknown';
        final rawConfidence = prediction['confidence'];
        final confidence = rawConfidence is num
            ? rawConfidence.toDouble()
            : double.tryParse('$rawConfidence') ?? 0;
        final severity = prediction['severity'] ?? 'unknown';
        buffer.writeln('\n▪ $condition');
        buffer.writeln('   Confidence: ${confidence.toStringAsFixed(1)}%');
        buffer.writeln('   Severity: $severity');

        final matchedSymptoms = prediction['matched_symptoms'] as List?;
        if (matchedSymptoms != null && matchedSymptoms.isNotEmpty) {
          buffer.writeln('   Matched symptoms: ${matchedSymptoms.join(', ')}');
        }

        final recommendations = prediction['recommendations'] as List?;
        if (recommendations != null && recommendations.isNotEmpty) {
          buffer.writeln('   💡 Recommendations:');
          for (final rec in recommendations) {
            buffer.writeln('      - $rec');
          }
        }
      }

      if (wellness != null) {
        buffer.writeln('\n✨ Wellness Advice:');
        final primary = wellness['primary_condition']?.toString();
        if (primary != null && primary.isNotEmpty) {
          buffer.writeln('   Primary concern: $primary');
        }
        final generalAdvice = wellness['general_advice'] as List?;
        if (generalAdvice != null && generalAdvice.isNotEmpty) {
          buffer.writeln('   🧘 General advice:');
          for (final adv in generalAdvice) {
            buffer.writeln('      - $adv');
          }
        }
        final seekHelp = wellness['when_to_seek_help'] as List?;
        if (seekHelp != null && seekHelp.isNotEmpty) {
          buffer.writeln('   🚨 Seek medical help if:');
          for (final item in seekHelp) {
            buffer.writeln('      - $item');
          }
        }
      }

      buffer.writeln('\n---');
      buffer.writeln(data['disclaimer'] ??
          '⚠️ This is an AI-based suggestion, not a medical diagnosis. Always consult a healthcare professional.');

      _addMessage(buffer.toString(), false);
    } catch (e) {
      // Show the actual error so the user knows what went wrong.
      _addMessage(
        '❌ Failed to analyze symptoms.\n\nError: $e\n\nPlease check your internet connection and try again.',
        false,
      );
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
        _addMessage('📄 Document Upload Result\n\n$message', false);
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
    if (symptoms.isEmpty) {
      _addMessage('Please enter at least one symptom (e.g., fever, cough).', false);
      return;
    }
    _controller.clear();
    _analyzeSymptoms(symptoms);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeManager>(context).isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.blue.shade50,
      appBar: AppBar(title: const Text('AI Symptom Checker')),
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
              controller: _scrollController,
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
                    child: SelectableText(
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
                        hintText: 'Enter symptoms, e.g. fever, chest pain',
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