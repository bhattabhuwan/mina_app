import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../theme/theme_manager.dart';

class HelpSupportPage extends StatelessWidget {
  const HelpSupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context);
    final isDarkMode = themeManager.isDarkMode;
    final accentColor = isDarkMode ? Colors.blue.shade300 : Colors.blue.shade700;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
        backgroundColor: isDarkMode ? Colors.grey.shade800 : Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          // FAQ Section
          _buildSectionHeader('Frequently Asked Questions', Icons.help_outline, accentColor),
          _buildFaqTile(
            question: 'How do I book an appointment?',
            answer: 'Go to the Consult page, select a doctor, choose a time slot, and confirm.',
          ),
          _buildFaqTile(
            question: 'How is my health data protected?',
            answer: 'We use AES-256 encryption for stored data and TLS for transmission. See Privacy & Security for details.',
          ),
          _buildFaqTile(
            question: 'Can I cancel an appointment?',
            answer: 'Yes, go to your appointments and tap Cancel. Refund policies apply.',
          ),
          _buildFaqTile(
            question: 'What should I do in an emergency?',
            answer: 'Call your local emergency number immediately. This app is not for emergencies.',
          ),
          _buildFaqTile(
            question: 'How do I reset my password?',
            answer: 'On the login screen, tap "Forgot Password" and follow the instructions.',
          ),
          const SizedBox(height: 20),

          // Contact Section
          _buildSectionHeader('Contact Us', Icons.contact_support, accentColor),
          _buildContactCard(
            icon: Icons.email,
            title: 'Email Support',
            subtitle: 'support@minahealth.com',
            onTap: () => _sendEmail(context, 'support@minahealth.com', 'Mina Health Support'),
            accentColor: accentColor,
          ),
          _buildContactCard(
            icon: Icons.chat,
            title: 'Live Chat',
            subtitle: 'Mon-Fri, 9 AM - 6 PM',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Live chat coming soon!')),
              );
            },
            accentColor: accentColor,
          ),
          _buildContactCard(
            icon: Icons.web,
            title: 'Website',
            subtitle: 'www.minahealth.com',
            onTap: () => _launchUrl(context, 'https://www.minahealth.com'),
            accentColor: accentColor,
          ),
          const SizedBox(height: 20),

          // Report a Problem
          _buildSectionHeader('Report an Issue', Icons.report_problem, accentColor),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: ElevatedButton.icon(
              onPressed: () => _sendEmail(context, 'bugs@minahealth.com', 'Bug Report - Mina Health'),
              icon: const Icon(Icons.bug_report),
              label: const Text('Report a Bug'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color accentColor) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Row(
        children: [
          Icon(icon, color: accentColor, size: 24),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildFaqTile({required String question, required String answer}) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        title: Text(question, style: const TextStyle(fontWeight: FontWeight.w500)),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(answer, style: const TextStyle(height: 1.4)),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color accentColor,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: accentColor, size: 32),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  Future<void> _sendEmail(BuildContext context, String email, String subject) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
      query: 'subject=${Uri.encodeComponent(subject)}',
    );
    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      } else {
        _showErrorSnackBar(context, 'No email client found. Please send manually to $email');
      }
    } catch (e) {
      _showErrorSnackBar(context, 'Failed to open email client: $e');
    }
  }

  Future<void> _launchUrl(BuildContext context, String url) async {
    final Uri uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _showErrorSnackBar(context, 'Cannot open $url');
      }
    } catch (e) {
      _showErrorSnackBar(context, 'Failed to open link: $e');
    }
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }
}