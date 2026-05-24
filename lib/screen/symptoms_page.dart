import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mina_app/theme/theme_manager.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';

class SymptomsCheckerPage extends StatefulWidget {
  const SymptomsCheckerPage({super.key});

  @override
  State<SymptomsCheckerPage> createState() => _SymptomsCheckerPageState();
}

class _SymptomsCheckerPageState extends State<SymptomsCheckerPage> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];

  bool _loading = false;
  bool _loadingSymptoms = false;

  List<String> _availableSymptoms = [];

  final String baseUrl = "https://mina-backend-1.onrender.com";

  // ---------------- HEADERS ----------------
  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    return {
      "Content-Type": "application/json",
      if (token != null && token.isNotEmpty)
        "Authorization": "Bearer $token",
    };
  }

  @override
  void initState() {
    super.initState();
    _fetchSymptoms();
    _addWelcome();
  }

  void _addWelcome() {
    _messages.add({
      "text": "👋 Welcome\nSelect or type symptoms to analyze.",
      "isUser": false,
    });
  }

  // ---------------- ADD MESSAGE ----------------
  void _addMessage(String text, bool isUser) {
    setState(() {
      _messages.add({"text": text, "isUser": isUser});
    });
  }

  // ---------------- FETCH SYMPTOMS ----------------
  Future<void> _fetchSymptoms() async {
    setState(() => _loadingSymptoms = true);

    try {
      final res = await http.get(
        Uri.parse("$baseUrl/api/v1/symptom-checker/symptoms"),
        headers: await _getHeaders(),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);

        setState(() {
          _availableSymptoms = List<String>.from(data["symptoms"] ?? []);
        });
      }
    } catch (e) {
      _addMessage("❌ Failed to load symptoms", false);
    }

    setState(() => _loadingSymptoms = false);
  }

  // ---------------- ANALYZE SYMPTOMS ----------------
  Future<void> _analyzeSymptoms(String symptom) async {
    _addMessage(symptom, true);
    setState(() => _loading = true);

    try {
      final res = await http.post(
        Uri.parse("$baseUrl/api/v1/symptom-checker/analyze"),
        headers: await _getHeaders(),
        body: jsonEncode({
          "symptoms": [symptom],
          "age": 25,
          "gender": "male",
          "duration_days": 1,
          "severity": 1,
        }),
      );

      final data = jsonDecode(res.body);

      String output = "🧠 AI Medical Analysis\n\n";

      if (data["predictions"] != null) {
        output += "📌 Possible Conditions:\n";

        for (var p in data["predictions"]) {
          final condition = p["condition"] ?? "Unknown";
          final confidence = (p["confidence"] ?? 0).toDouble();
          final severity = p["severity"] ?? "unknown";

          output +=
              "• $condition (${confidence.toStringAsFixed(1)}%) - $severity\n";

          if (p["recommendations"] != null) {
            output += "  💊 Recommendations:\n";
            for (var r in p["recommendations"]) {
              output += "    - $r\n";
            }
          }
        }
      }

      output += "\n⚠️ ${data["disclaimer"] ?? "Not a medical diagnosis"}";

      _addMessage(output, false);
    } catch (e) {
      _addMessage("❌ Analysis failed: $e", false);
    }

    setState(() => _loading = false);
  }

  // ---------------- FIXED DOCUMENT UPLOAD ----------------
  Future<void> _uploadFile() async {
    FilePickerResult? result =
        await FilePicker.platform.pickFiles(type: FileType.any);

    if (result == null) return;

    final file = File(result.files.single.path!);
    final fileName = result.files.single.name;

    _addMessage("📎 Uploading $fileName...", true);
    setState(() => _loading = true);

    try {
      final request = http.MultipartRequest(
        "POST",
        Uri.parse("$baseUrl/api/v1/documents/upload"),
      );

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      request.headers.addAll({
        if (token != null && token.isNotEmpty)
          "Authorization": "Bearer $token",
      });

      // ✅ IMPORTANT: backend supports these fields
      request.fields["folder"] = "medical_files";
      request.fields["description"] = "Uploaded from Flutter app";

      request.files.add(
        await http.MultipartFile.fromPath("file", file.path),
      );

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      final data = jsonDecode(response.body);

      String output = "📄 Document Upload Result\n\n";

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (data is String) {
          output += data;
        } else if (data is Map) {
          output += data["message"] ??
              data["result"] ??
              data["file_url"] ??
              "Upload successful";

          if (data["storage_type"] != null) {
            output += "\n📦 Storage: ${data["storage_type"]}";
          }
        } else {
          output += "Upload completed successfully";
        }

        output +=
            "\n\n🧠 AI Note: Document uploaded successfully. If analysis is supported, results will appear in chat.";
      } else {
        output = "❌ Upload failed (${response.statusCode})";
      }

      _addMessage(output, false);
    } catch (e) {
      _addMessage("❌ Upload error: $e", false);
    }

    setState(() => _loading = false);
  }

  // ---------------- SEND ----------------
  void _send() {
    if (_controller.text.trim().isEmpty) return;
    _analyzeSymptoms(_controller.text.trim());
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeManager>(context).isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.blue.shade50,
      appBar: AppBar(title: const Text("Symptoms Checker")),

      body: Column(
        children: [
          // SYMPTOMS
          if (_loadingSymptoms)
            const LinearProgressIndicator()
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _availableSymptoms.take(10).map((s) {
                  return GestureDetector(
                    onTap: () => _analyzeSymptoms(s),
                    child: Container(
                      margin: const EdgeInsets.all(6),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(s),
                    ),
                  );
                }).toList(),
              ),
            ),

          // CHAT
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: _messages.length,
              itemBuilder: (context, i) {
                final msg = _messages[i];

                return Align(
                  alignment: msg["isUser"]
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: msg["isUser"] ? Colors.blue : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(msg["text"]),
                  ),
                );
              },
            ),
          ),

          // INPUT
          Container(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.attach_file),
                  onPressed: _uploadFile,
                ),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: "Enter symptoms...",
                    ),
                  ),
                ),
                IconButton(
                  icon: _loading
                      ? const CircularProgressIndicator()
                      : const Icon(Icons.send),
                  onPressed: _send,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}