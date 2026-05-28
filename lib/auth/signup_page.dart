import 'package:flutter/material.dart';
import 'package:mina_app/auth/ApiService.dart';
import 'package:mina_app/auth/role_based_home.dart';
import 'package:mina_app/provider/user_provider.dart';
import 'package:provider/provider.dart';

class SignUpUI extends StatefulWidget {
  final VoidCallback showSignInPage;
  const SignUpUI({super.key, required this.showSignInPage});

  @override
  State<SignUpUI> createState() => _SignUpUIState();
}

class _SignUpUIState extends State<SignUpUI> {
  // Common controllers
  final fullNameController = TextEditingController();
  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPassController = TextEditingController();

  // Required fields
  final dobController = TextEditingController();
  final addressController = TextEditingController();
  final emergencyContactController = TextEditingController();

  // Selected gender
  String _selectedGender = 'Other';

  bool _loading = false;
  String? _errorText;

  String _getFriendlyError(dynamic e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains("400")) return "Invalid information provided.";
    if (msg.contains("401")) return "Unauthorized request.";
    if (msg.contains("409") || msg.contains("already exists") || msg.contains("duplicate")) {
      return "Account already exists.";
    }
    if (msg.contains("network") || msg.contains("socket")) return "No internet connection.";
    if (msg.contains("timeout")) return "Request timeout. Please try again.";
    return "Registration failed. Please try again.";
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        dobController.text = "${picked.toLocal()}".split(' ')[0];
      });
    }
  }

  void register() async {
    final fullName = fullNameController.text.trim();
    final username = usernameController.text.trim();
    final email = emailController.text.trim();
    final phone = phoneController.text.trim();
    final password = passwordController.text.trim();
    final confirmPassword = confirmPassController.text.trim();
    final address = addressController.text.trim();
    final emergencyContact = emergencyContactController.text.trim();
    final dobText = dobController.text.trim();

    // Validation - ONLY REQUIRED FIELDS (backend schema)
    if (fullName.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      setState(() => _errorText = "Full Name, Email and Password are required.");
      return;
    }
    if (username.isEmpty) {
      setState(() => _errorText = "Username is required.");
      return;
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      setState(() => _errorText = "Enter a valid email address.");
      return;
    }

    if (password.length < 6) {
      setState(() => _errorText = "Password must be at least 6 characters.");
      return;
    }
    if (password != confirmPassword) {
      setState(() => _errorText = "Passwords do not match.");
      return;
    }

    DateTime? dob;
    if (dobText.isNotEmpty) {
      try {
        dob = DateTime.parse(dobText);
      } catch (_) {
        setState(() => _errorText = "Invalid Date of Birth. Use YYYY-MM-DD.");
        return;
      }
    }

    setState(() {
      _loading = true;
      _errorText = null;
    });

    try {
      final api = ApiService();
      await api.registerUser(
        email: email,
        username: username,
        fullName: fullName,
        phone: phone.isEmpty ? null : phone,
        gender: _selectedGender == 'Other' ? null : _selectedGender,
        password: password,
        dateOfBirth: dob,
        address: address.isEmpty ? null : address,
        emergencyContact: emergencyContact.isEmpty ? null : emergencyContact,
        medicalConditions: [],
        allergies: [],
        currentMedications: [],
      );

      // Auto-login
      await api.loginUser(username: username, password: password);
      final userData = await api.getCurrentUser();

      final userId = userData['id'] ?? userData['data']?['id'] as int?;
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await userProvider.updateUser(
        fullName: userData['full_name'] ?? fullName,
        email: userData['email'] ?? email,
        profileImagePath: userData['profile_image_url'],
        role: userData['role'] ?? 'patient',  // role from backend
        userId: userId,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Account created! Logging in..."), backgroundColor: Colors.green),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const RoleBasedHome()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      final friendlyError = _getFriendlyError(e);
      final fullError = e.toString();
      setState(() => _errorText = friendlyError);
      print("❌ SIGNUP ERROR: $e");
      print("📋 ERROR DETAILS: $fullError");
      print("🔍 ERROR TYPE: ${e.runtimeType}");

      // Show both friendly and detailed error
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("Registration Error"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("User Error:", style: TextStyle(fontWeight: FontWeight.bold)),
                Text(friendlyError, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 16),
                const Text("Backend Response:", style: TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  fullError,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                  maxLines: 10,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("OK"),
            ),
          ],
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFF5C5FFF),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset('lib/images/logo.png', height: 150, width: 150),
                const SizedBox(height: 20),
                const Text('MINA', style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white)),
                const Text('HEALTH APP', style: TextStyle(fontSize: 16, color: Colors.white70)),
                const SizedBox(height: 30),

                // Full Name
                MyTextfield(controller: fullNameController, hintText: "Full Name", obscuretext: false),
                const SizedBox(height: 16),

                // Username
                MyTextfield(controller: usernameController, hintText: "Username", obscuretext: false),
                const SizedBox(height: 16),

                // Email
                MyTextfield(controller: emailController, hintText: "Email", obscuretext: false),
                const SizedBox(height: 16),

                // Phone (Optional)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Phone Number", style: TextStyle(color: Colors.white70, fontSize: 12)),
                    const Text("(Optional)", style: TextStyle(color: Colors.white54, fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 8),
                MyTextfield(controller: phoneController, hintText: "Phone Number", obscuretext: false),
                const SizedBox(height: 16),

                // Gender (Optional)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Gender:", style: TextStyle(color: Colors.white, fontSize: 16)),
                    const Text("(Optional)", style: TextStyle(color: Colors.white54, fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'Male', label: Text("Male")),
                    ButtonSegment(value: 'Female', label: Text("Female")),
                    ButtonSegment(value: 'Other', label: Text("Other")),
                  ],
                  selected: {_selectedGender},
                  onSelectionChanged: (Set<String> newSelection) {
                    setState(() => _selectedGender = newSelection.first);
                  },
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) return Colors.white;
                      return Colors.white.withOpacity(0.3);
                    }),
                    foregroundColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) return const Color(0xFF5C5FFF);
                      return Colors.white;
                    }),
                  ),
                ),
                const SizedBox(height: 16),

                // Date of Birth (Optional)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Date of Birth", style: TextStyle(color: Colors.white70, fontSize: 12)),
                    const Text("(Optional)", style: TextStyle(color: Colors.white54, fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => _selectDate(context),
                  child: AbsorbPointer(
                    child: MyTextfield(
                      controller: dobController,
                      hintText: "Date of Birth (YYYY-MM-DD)",
                      obscuretext: false,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Address (Optional)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Address", style: TextStyle(color: Colors.white70, fontSize: 12)),
                    const Text("(Optional)", style: TextStyle(color: Colors.white54, fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 8),
                MyTextfield(controller: addressController, hintText: "Address", obscuretext: false),
                const SizedBox(height: 16),

                // Emergency Contact (Optional)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Emergency Contact", style: TextStyle(color: Colors.white70, fontSize: 12)),
                    const Text("(Optional)", style: TextStyle(color: Colors.white54, fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 8),
                MyTextfield(controller: emergencyContactController, hintText: "Emergency Contact", obscuretext: false),
                const SizedBox(height: 16),

                // Password
                PasswordTextField(controller: passwordController, hintText: "Password"),
                const SizedBox(height: 16),

                // Confirm Password
                ConfirmPasswordTextField(controller: confirmPassController, hintText: "Confirm Password"),

                if (_errorText != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(_errorText!, style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w500)),
                  ),
                const SizedBox(height: 20),

                // Sign Up button
                SizedBox(
                  height: 50,
                  width: width * 0.9,
                  child: ElevatedButton(
                    onPressed: _loading ? null : register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF5C5FFF),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    child: _loading
                        ? const CircularProgressIndicator(color: Color(0xFF5C5FFF))
                        : const Text("Sign Up", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 20),
                const Text("or", style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 20),

                // Sign In button
                SizedBox(
                  height: 50,
                  width: width * 0.9,
                  child: OutlinedButton(
                    onPressed: widget.showSignInPage,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    child: const Text(
                      "Already have an account? Sign In",
                      style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------
// Reusable text fields (unchanged)
// ---------------------------
class MyTextfield extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool obscuretext;
  const MyTextfield({super.key, required this.controller, required this.hintText, required this.obscuretext});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscuretext,
      style: const TextStyle(color: Colors.black),
      decoration: InputDecoration(
        hintText: hintText,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
      ),
    );
  }
}

class PasswordTextField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  const PasswordTextField({super.key, required this.controller, required this.hintText});

  @override
  State<PasswordTextField> createState() => _PasswordTextFieldState();
}

class _PasswordTextFieldState extends State<PasswordTextField> {
  bool _isObscure = true;
  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      obscureText: _isObscure,
      style: const TextStyle(color: Colors.black),
      decoration: InputDecoration(
        hintText: widget.hintText,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        suffixIcon: IconButton(
          icon: Icon(_isObscure ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
          onPressed: () => setState(() => _isObscure = !_isObscure),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
      ),
    );
  }
}

class ConfirmPasswordTextField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  const ConfirmPasswordTextField({super.key, required this.controller, required this.hintText});

  @override
  State<ConfirmPasswordTextField> createState() => _ConfirmPasswordTextFieldState();
}

class _ConfirmPasswordTextFieldState extends State<ConfirmPasswordTextField> {
  bool _isObscure = true;
  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      obscureText: _isObscure,
      style: const TextStyle(color: Colors.black),
      decoration: InputDecoration(
        hintText: widget.hintText,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        suffixIcon: IconButton(
          icon: Icon(_isObscure ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
          onPressed: () => setState(() => _isObscure = !_isObscure),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
      ),
    );
  }
}
