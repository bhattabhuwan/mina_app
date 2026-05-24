import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart'; // add to pubspec.yaml
import '../theme/theme_manager.dart';

class PrivacySecurityPage extends StatefulWidget {
  const PrivacySecurityPage({super.key});

  @override
  State<PrivacySecurityPage> createState() => _PrivacySecurityPageState();
}

class _PrivacySecurityPageState extends State<PrivacySecurityPage> {
  final LocalAuthentication _localAuth = LocalAuthentication();
  
  bool _biometricEnabled = false;
  bool _analyticsEnabled = true;
  bool _crashReportingEnabled = true;
  bool _researchSharing = false;
  bool _marketingEmails = false;
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _biometricEnabled = prefs.getBool('security_biometric') ?? false;
      _analyticsEnabled = prefs.getBool('privacy_analytics') ?? true;
      _crashReportingEnabled = prefs.getBool('privacy_crash_reporting') ?? true;
      _researchSharing = prefs.getBool('privacy_research_sharing') ?? false;
      _marketingEmails = prefs.getBool('privacy_marketing_emails') ?? false;
    });
  }

  Future<void> _saveSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> _toggleBiometric(bool value) async {
    if (value) {
      // Check if device supports biometrics
      final isAvailable = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      if (!isAvailable && !isDeviceSupported) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Biometric authentication not supported on this device')),
        );
        return;
      }
    }
    setState(() => _biometricEnabled = value);
    await _saveSetting('security_biometric', value);
  }

  Future<void> _requestDataDownload() async {
    setState(() => _isLoading = true);
    // In a real app, call API to generate export
    await Future.delayed(const Duration(seconds: 2)); // Simulate
    setState(() => _isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Data export request submitted. You will receive an email shortly.')),
    );
  }

  Future<void> _requestAccountDeletion() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text('Are you sure? This will permanently delete all your health data, medical records, and appointment history. This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      setState(() => _isLoading = true);
      // Call API to delete account
      await Future.delayed(const Duration(seconds: 2));
      setState(() => _isLoading = false);
      // Navigate to login
      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context);
    final isDarkMode = themeManager.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy & Security'),
        backgroundColor: isDarkMode ? Colors.grey.shade800 : Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Security Section
                  _buildSectionTitle('Security', Icons.lock_outline),
                  const SizedBox(height: 8),
                  _buildSwitchTile(
                    title: 'Biometric / PIN Lock',
                    subtitle: 'Require fingerprint, face ID, or PIN to open the app',
                    value: _biometricEnabled,
                    onChanged: _toggleBiometric,
                    icon: Icons.fingerprint,
                  ),
                  const SizedBox(height: 20),

                  // Privacy Controls Section
                  _buildSectionTitle('Privacy Controls', Icons.privacy_tip_outlined),
                  const SizedBox(height: 8),
                  _buildSwitchTile(
                    title: 'Anonymous Usage Data',
                    subtitle: 'Help improve the app by sending anonymized usage statistics',
                    value: _analyticsEnabled,
                    onChanged: (val) {
                      setState(() => _analyticsEnabled = val);
                      _saveSetting('privacy_analytics', val);
                    },
                    icon: Icons.analytics,
                  ),
                  _buildSwitchTile(
                    title: 'Crash Reporting',
                    subtitle: 'Automatically send crash reports to fix bugs',
                    value: _crashReportingEnabled,
                    onChanged: (val) {
                      setState(() => _crashReportingEnabled = val);
                      _saveSetting('privacy_crash_reporting', val);
                    },
                    icon: Icons.bug_report,
                  ),
                  _buildSwitchTile(
                    title: 'Share Data for Research',
                    subtitle: 'Contribute to medical research (anonymized, opt-in only)',
                    value: _researchSharing,
                    onChanged: (val) {
                      setState(() => _researchSharing = val);
                      _saveSetting('privacy_research_sharing', val);
                    },
                    icon: Icons.science,
                  ),
                  _buildSwitchTile(
                    title: 'Marketing Communications',
                    subtitle: 'Receive health tips and promotional emails',
                    value: _marketingEmails,
                    onChanged: (val) {
                      setState(() => _marketingEmails = val);
                      _saveSetting('privacy_marketing_emails', val);
                    },
                    icon: Icons.email,
                  ),
                  const SizedBox(height: 20),

                  // Data Access Section
                  _buildSectionTitle('Your Data', Icons.data_usage),
                  const SizedBox(height: 8),
                  _buildActionTile(
                    icon: Icons.download,
                    title: 'Download Your Data',
                    subtitle: 'Get a copy of all your personal data',
                    onTap: _requestDataDownload,
                  ),
                  _buildActionTile(
                    icon: Icons.delete_forever,
                    title: 'Delete Account',
                    subtitle: 'Permanently erase all your information',
                    onTap: _requestAccountDeletion,
                    iconColor: Colors.red,
                  ),
                  const SizedBox(height: 20),

                  // Legal Policies Section
                  _buildSectionTitle('Legal Policies', Icons.description),
                  const SizedBox(height: 8),
                  _buildLinkTile(
                    title: 'Privacy Policy',
                    onTap: () => _showPolicyDialog('Privacy Policy', _privacyPolicyText),
                  ),
                  _buildLinkTile(
                    title: 'Terms of Service',
                    onTap: () => _showPolicyDialog('Terms of Service', _termsText),
                  ),
                  _buildLinkTile(
                    title: 'Health Data Disclaimer',
                    onTap: () => _showPolicyDialog('Disclaimer', _disclaimerText),
                  ),
                  const SizedBox(height: 30),
                  
                  // Last updated
                  Center(
                    child: Text(
                      'Last updated: May 2026',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 22, color: Colors.blue.shade700),
        const SizedBox(width: 10),
        Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
    required IconData icon,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: SwitchListTile(
        secondary: Icon(icon, color: Colors.blue.shade700),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 13)),
        value: value,
        onChanged: onChanged,
        activeColor: Colors.blue.shade700,
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color iconColor = Colors.blue,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Icon(icon, color: iconColor),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 13)),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  Widget _buildLinkTile({required String title, required VoidCallback onTap}) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: const Icon(Icons.insert_drive_file, color: Colors.grey),
        title: Text(title),
        trailing: const Icon(Icons.open_in_new, size: 18),
        onTap: onTap,
      ),
    );
  }

  void _showPolicyDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(child: Text(content)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  // Placeholder texts – replace with your actual legal documents
  final String _privacyPolicyText = '''
We value your privacy. This app collects personal health information only with your explicit consent. Data is encrypted and never sold to third parties. For full details, visit our website.

Key points:
- Medical records are stored securely with AES-256 encryption
- You can request data deletion at any time
- No data is shared without your permission
''';

  final String _termsText = '''
By using this app, you agree to abide by our terms. The service is provided "as is" for informational purposes. Consult a real doctor for medical advice.

- You must be at least 13 years old
- You are responsible for your account security
- We may update terms with prior notice
''';

  final String _disclaimerText = '''
This app is not a medical device. All health information and recommendations are generated by AI and should not replace professional medical advice. Always seek the advice of a qualified physician.

In case of emergency, contact your local emergency services immediately.
''';
}