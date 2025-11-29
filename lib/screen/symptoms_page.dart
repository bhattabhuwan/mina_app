import 'package:flutter/material.dart';

class SymptomsCheckerUI extends StatefulWidget {
  const SymptomsCheckerUI({super.key});

  @override
  State<SymptomsCheckerUI> createState() => _SymptomsCheckerUIState();
}

class _SymptomsCheckerUIState extends State<SymptomsCheckerUI> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, dynamic>> _messages = []; // {'text': '', 'isUser': bool}

  void _sendMessage() {
    if (_controller.text.trim().isEmpty) return;

    setState(() {
      // User message
      _messages.add({'text': _controller.text.trim(), 'isUser': true});
      // Simulated AI response
      _messages.add({
        'text': "Analyzing symptoms for '${_controller.text.trim()}'...",
        'isUser': false
      });
      _controller.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      appBar: AppBar(
        title: const Text('Symptoms Checker'),
        backgroundColor: Colors.lightBlue.shade700,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Decorative background bubbles
          Positioned(
            top: -50,
            left: -50,
            child: _buildBackgroundCircle(200, Colors.lightBlue.shade200),
          ),
          Positioned(
            bottom: -80,
            right: -60,
            child: _buildBackgroundCircle(250, Colors.lightBlue.shade100),
          ),
          Positioned(
            top: 150,
            right: -30,
            child: _buildBackgroundCircle(100, Colors.lightBlue.shade100.withOpacity(0.5)),
          ),
          
          Column(
            children: [
              // Messages List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final msg = _messages[index];
                    return Align(
                      alignment:
                          msg['isUser'] ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.75,
                        ),
                        decoration: BoxDecoration(
                          color: msg['isUser']
                              ? Colors.lightBlue.shade400
                              : Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(20),
                            topRight: const Radius.circular(20),
                            bottomLeft: Radius.circular(msg['isUser'] ? 20 : 0),
                            bottomRight: Radius.circular(msg['isUser'] ? 0 : 20),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.2),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            )
                          ],
                        ),
                        child: Text(
                          msg['text'],
                          style: TextStyle(
                            color: msg['isUser'] ? Colors.white : Colors.black87,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Input Area
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    )
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        decoration: InputDecoration(
                          hintText: 'Enter your symptoms...',
                          filled: true,
                          fillColor: Colors.blue.shade50,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: _sendMessage,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.lightBlue.shade700,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.lightBlue.shade200.withOpacity(0.5),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            )
                          ],
                        ),
                        child: const Icon(Icons.send, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}
