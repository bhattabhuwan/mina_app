import 'package:flutter/material.dart';
import 'package:mina_app/auth/ApiService.dart';
import 'signin_page.dart'; // adjust import if needed

class SignUpUI extends StatefulWidget {
  final VoidCallback showSignInPage;

  const SignUpUI({super.key, required this.showSignInPage});

  @override
  State<SignUpUI> createState() => _SignUpUIState();
}

class _SignUpUIState extends State<SignUpUI> {
  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPassController = TextEditingController();
  final fullNameController = TextEditingController();
  final genderController = TextEditingController();
  final dobController = TextEditingController();
  final addressController = TextEditingController();
  final emergencyContactController = TextEditingController();

  bool _loading = false;

  void register() async {
    if (passwordController.text != confirmPassController.text) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Passwords do not match")));
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      final api = ApiService();
      await api.registerUser(
        email: emailController.text.trim(),
        username: usernameController.text.trim(),
        fullName: fullNameController.text.trim(),
        phone: phoneController.text.trim(),
        gender: genderController.text.trim(),
        role: "patient",
        password: passwordController.text.trim(),
        dateOfBirth: DateTime.parse(dobController.text.trim()),
        address: addressController.text.trim(),
        emergencyContact: emergencyContactController.text.trim(),
        medicalConditions: [],
        allergies: [],
        currentMedications: [],
      );

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Registered successfully!")));
      widget.showSignInPage();
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Registration failed: $e")));
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFF5C5FFF), // Same as SignInUI
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo (same as SignInUI)
                Image.asset(
                  'lib/images/logo.png',
                  height: 150,
                  width: 150,
                ),
                const SizedBox(height: 20),

                // App name
                const Text(
                  'MINA',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Text(
                  'HEALTH APP',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
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

                // Phone
                MyTextfield(controller: phoneController, hintText: "Phone Number", obscuretext: false),
                const SizedBox(height: 16),

                // Gender
                MyTextfield(controller: genderController, hintText: "Gender", obscuretext: false),
                const SizedBox(height: 16),

                // Date of Birth
                MyTextfield(controller: dobController, hintText: "Date of Birth (YYYY-MM-DD)", obscuretext: false),
                const SizedBox(height: 16),

                // Address
                MyTextfield(controller: addressController, hintText: "Address", obscuretext: false),
                const SizedBox(height: 16),

                // Emergency Contact
                MyTextfield(controller: emergencyContactController, hintText: "Emergency Contact", obscuretext: false),
                const SizedBox(height: 16),

                // Password
                PasswordTextField(controller: passwordController, hintText: "Password"),
                const SizedBox(height: 16),

                // Confirm Password
                ConfirmPasswordTextField(controller: confirmPassController, hintText: "Confirm Password"),
                const SizedBox(height: 20),

                // Sign Up Button
                SizedBox(
                  height: 50,
                  width: width * 0.9,
                  child: ElevatedButton(
                    onPressed: _loading ? null : register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF5C5FFF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: _loading
                        ? const CircularProgressIndicator(color: Color(0xFF5C5FFF))
                        : const Text(
                            "Sign Up",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 20),

                // OR separator
                const Text(
                  "or",
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 20),

                // Already have an account? -> Sign In button
                SizedBox(
                  height: 50,
                  width: width * 0.9,
                  child: OutlinedButton(
                    onPressed: widget.showSignInPage,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text(
                      "Already have an account? Sign In",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
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

// ---------- Reusable TextField (same as SignInUI) ----------
class MyTextfield extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool obscuretext;

  const MyTextfield({
    super.key,
    required this.controller,
    required this.hintText,
    required this.obscuretext,
  });

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
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

// ---------- Password TextField (same as SignInUI) ----------
class PasswordTextField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;

  const PasswordTextField({
    super.key,
    required this.controller,
    required this.hintText,
  });

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
          icon: Icon(
            _isObscure ? Icons.visibility_off : Icons.visibility,
            color: Colors.grey,
          ),
          onPressed: () {
            setState(() {
              _isObscure = !_isObscure;
            });
          },
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

// ---------- Confirm Password TextField (style matched to SignInUI) ----------
class ConfirmPasswordTextField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;

  const ConfirmPasswordTextField({
    super.key,
    required this.controller,
    required this.hintText,
  });

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
          icon: Icon(
            _isObscure ? Icons.visibility_off : Icons.visibility,
            color: Colors.grey,
          ),
          onPressed: () {
            setState(() {
              _isObscure = !_isObscure;
            });
          },
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}