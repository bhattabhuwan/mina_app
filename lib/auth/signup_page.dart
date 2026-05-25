import 'package:flutter/material.dart';
import 'package:mina_app/auth/ApiService.dart';
import 'signin_page.dart';

class SignUpUI extends StatefulWidget {
  final VoidCallback showSignInPage;

  const SignUpUI({
    super.key,
    required this.showSignInPage,
  });

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
  String? _errorText;

  // ---------------- ERROR HANDLER ----------------
  String _getFriendlyError(dynamic e) {

    final msg = e.toString().toLowerCase();

    if (msg.contains("400")) {
      return "Invalid information provided.";
    }

    if (msg.contains("401")) {
      return "Unauthorized request.";
    }

    if (msg.contains("409") ||
        msg.contains("already exists") ||
        msg.contains("duplicate")) {
      return "Account already exists.";
    }

    if (msg.contains("network") ||
        msg.contains("socket")) {
      return "No internet connection.";
    }

    if (msg.contains("timeout")) {
      return "Request timeout. Please try again.";
    }

    return "Registration failed. Please try again.";
  }

  // ---------------- REGISTER ----------------
  void register() async {

    final username = usernameController.text.trim();
    final email = emailController.text.trim();
    final phone = phoneController.text.trim();
    final password = passwordController.text.trim();
    final confirmPassword = confirmPassController.text.trim();
    final fullName = fullNameController.text.trim();
    final gender = genderController.text.trim();
    final dob = dobController.text.trim();
    final address = addressController.text.trim();
    final emergencyContact =
        emergencyContactController.text.trim();

    // REQUIRED VALIDATION
    if (username.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty ||
        fullName.isEmpty) {

      setState(() {
        _errorText =
            "Please fill all required fields.";
      });

      return;
    }

    // EMAIL VALIDATION
    final emailRegex = RegExp(
      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
    );

    if (!emailRegex.hasMatch(email)) {

      setState(() {
        _errorText =
            "Please enter a valid email.";
      });

      return;
    }

    // PASSWORD VALIDATION
    if (password.length < 6) {

      setState(() {
        _errorText =
            "Password must be at least 6 characters.";
      });

      return;
    }

    // PASSWORD MATCH
    if (password != confirmPassword) {

      setState(() {
        _errorText = "Passwords do not match.";
      });

      return;
    }

    // DATE VALIDATION
    DateTime? parsedDob;

    try {
      parsedDob = DateTime.parse(dob);
    } catch (_) {

      setState(() {
        _errorText =
            "Invalid date format. Use YYYY-MM-DD.";
      });

      return;
    }

    // START LOADING
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
        phone: phone,
        gender: gender,
        role: "patient",
        password: password,
        dateOfBirth: parsedDob,
        address: address,
        emergencyContact: emergencyContact,
        medicalConditions: [],
        allergies: [],
        currentMedications: [],
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Registered successfully!"),
          backgroundColor: Colors.green,
        ),
      );

      widget.showSignInPage();

    } catch (e) {

      if (!mounted) return;

      setState(() {
        _errorText = _getFriendlyError(e);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_errorText!),
          backgroundColor: Colors.red,
        ),
      );

    } finally {

      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
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
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 40,
            ),

            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                // LOGO
                Image.asset(
                  'lib/images/logo.png',
                  height: 150,
                  width: 150,
                ),

                const SizedBox(height: 20),

                // TITLE
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

                // FULL NAME
                MyTextfield(
                  controller: fullNameController,
                  hintText: "Full Name",
                  obscuretext: false,
                ),

                const SizedBox(height: 16),

                // USERNAME
                MyTextfield(
                  controller: usernameController,
                  hintText: "Username",
                  obscuretext: false,
                ),

                const SizedBox(height: 16),

                // EMAIL
                MyTextfield(
                  controller: emailController,
                  hintText: "Email",
                  obscuretext: false,
                ),

                const SizedBox(height: 16),

                // PHONE
                MyTextfield(
                  controller: phoneController,
                  hintText: "Phone Number",
                  obscuretext: false,
                ),

                const SizedBox(height: 16),

                // GENDER
                MyTextfield(
                  controller: genderController,
                  hintText: "Gender",
                  obscuretext: false,
                ),

                const SizedBox(height: 16),

                // DOB
                MyTextfield(
                  controller: dobController,
                  hintText:
                      "Date of Birth (YYYY-MM-DD)",
                  obscuretext: false,
                ),

                const SizedBox(height: 16),

                // ADDRESS
                MyTextfield(
                  controller: addressController,
                  hintText: "Address",
                  obscuretext: false,
                ),

                const SizedBox(height: 16),

                // EMERGENCY CONTACT
                MyTextfield(
                  controller: emergencyContactController,
                  hintText: "Emergency Contact",
                  obscuretext: false,
                ),

                const SizedBox(height: 16),

                // PASSWORD
                PasswordTextField(
                  controller: passwordController,
                  hintText: "Password",
                ),

                const SizedBox(height: 16),

                // CONFIRM PASSWORD
                ConfirmPasswordTextField(
                  controller: confirmPassController,
                  hintText: "Confirm Password",
                ),

                // ERROR TEXT
                if (_errorText != null)
                  Padding(
                    padding:
                        const EdgeInsets.only(top: 10),
                    child: Text(
                      _errorText!,
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                const SizedBox(height: 20),

                // SIGN UP BUTTON
                SizedBox(
                  height: 50,
                  width: width * 0.9,

                  child: ElevatedButton(
                    onPressed:
                        _loading ? null : register,

                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor:
                          const Color(0xFF5C5FFF),

                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(30),
                      ),
                    ),

                    child: _loading
                        ? const CircularProgressIndicator(
                            color:
                                Color(0xFF5C5FFF),
                          )
                        : const Text(
                            "Sign Up",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  "or",
                  style: TextStyle(
                    color: Colors.white70,
                  ),
                ),

                const SizedBox(height: 20),

                // SIGN IN BUTTON
                SizedBox(
                  height: 50,
                  width: width * 0.9,

                  child: OutlinedButton(
                    onPressed:
                        widget.showSignInPage,

                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                        color: Colors.white,
                      ),

                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(30),
                      ),
                    ),

                    child: const Text(
                      "Already have an account? Sign In",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight:
                            FontWeight.bold,
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

// ---------------- TEXT FIELD ----------------
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

      style: const TextStyle(
        color: Colors.black,
      ),

      decoration: InputDecoration(
        hintText: hintText,

        filled: true,
        fillColor: Colors.white,

        contentPadding:
            const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 16,
        ),

        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(30),

          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

// ---------------- PASSWORD FIELD ----------------
class PasswordTextField extends StatefulWidget {

  final TextEditingController controller;
  final String hintText;

  const PasswordTextField({
    super.key,
    required this.controller,
    required this.hintText,
  });

  @override
  State<PasswordTextField> createState() =>
      _PasswordTextFieldState();
}

class _PasswordTextFieldState
    extends State<PasswordTextField> {

  bool _isObscure = true;

  @override
  Widget build(BuildContext context) {

    return TextField(
      controller: widget.controller,
      obscureText: _isObscure,

      style: const TextStyle(
        color: Colors.black,
      ),

      decoration: InputDecoration(
        hintText: widget.hintText,

        filled: true,
        fillColor: Colors.white,

        contentPadding:
            const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 16,
        ),

        suffixIcon: IconButton(
          icon: Icon(
            _isObscure
                ? Icons.visibility_off
                : Icons.visibility,
            color: Colors.grey,
          ),

          onPressed: () {
            setState(() {
              _isObscure = !_isObscure;
            });
          },
        ),

        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(30),

          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

// ---------------- CONFIRM PASSWORD ----------------
class ConfirmPasswordTextField
    extends StatefulWidget {

  final TextEditingController controller;
  final String hintText;

  const ConfirmPasswordTextField({
    super.key,
    required this.controller,
    required this.hintText,
  });

  @override
  State<ConfirmPasswordTextField> createState() =>
      _ConfirmPasswordTextFieldState();
}

class _ConfirmPasswordTextFieldState
    extends State<ConfirmPasswordTextField> {

  bool _isObscure = true;

  @override
  Widget build(BuildContext context) {

    return TextField(
      controller: widget.controller,
      obscureText: _isObscure,

      style: const TextStyle(
        color: Colors.black,
      ),

      decoration: InputDecoration(
        hintText: widget.hintText,

        filled: true,
        fillColor: Colors.white,

        contentPadding:
            const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 16,
        ),

        suffixIcon: IconButton(
          icon: Icon(
            _isObscure
                ? Icons.visibility_off
                : Icons.visibility,
            color: Colors.grey,
          ),

          onPressed: () {
            setState(() {
              _isObscure = !_isObscure;
            });
          },
        ),

        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(30),

          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}