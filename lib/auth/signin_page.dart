import 'package:flutter/material.dart';
import 'package:mina_app/auth/ApiService.dart';
import 'package:mina_app/auth/Forgot_pass.dart';
import 'package:mina_app/provider/user_provider.dart';
import 'package:mina_app/screen/home_page.dart';
import 'package:provider/provider.dart';

class SignInUI extends StatefulWidget {
  final VoidCallback showSignUpPage;

  const SignInUI({super.key, required this.showSignUpPage});

  @override
  State<SignInUI> createState() => _SignInUIState();
}

class _SignInUIState extends State<SignInUI> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _loading = false;
  String? _errorText;

  // ---------------- FRIENDLY ERROR HANDLER ----------------
  String _getFriendlyError(dynamic e) {
    final msg = e.toString().toLowerCase();

    if (msg.contains("401") || msg.contains("unauthorized")) {
      return "Invalid email or password.";
    }

    if (msg.contains("404")) {
      return "Server not found. Try again later.";
    }

    if (msg.contains("network") || msg.contains("socket")) {
      return "No internet connection.";
    }

    if (msg.contains("timeout")) {
      return "Request timeout. Please try again.";
    }

    return "Something went wrong. Please try again.";
  }

  // ---------------- LOGIN ----------------
  void login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    // FIELD VALIDATION
    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _errorText = "Please fill all required fields";
      });
      return;
    }

    setState(() {
      _loading = true;
      _errorText = null;
    });

    try {
      final api = ApiService();

      await api.loginUser(
        username: email,
        password: password,
      );

      final userData = await api.getCurrentUser();

      final userProvider =
          Provider.of<UserProvider>(context, listen: false);

      await userProvider.updateUser(
        fullName: userData['full_name'] ?? 'User',
        email: userData['email'] ?? '',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Login successful!"),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
      );

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
        setState(() => _loading = false);
      }
    }
  }

  // ---------------- FORGOT PASSWORD ----------------
  void _showForgotPasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => ForgotPasswordScreen(),
    );
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

                Image.asset(
                  'lib/images/logo.png',
                  height: 150,
                  width: 150,
                ),

                const SizedBox(height: 20),

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

                const SizedBox(height: 40),

                // EMAIL
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    hintText: "Email or Phone",
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // PASSWORD
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: "Password",
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // ERROR TEXT (INLINE)
                if (_errorText != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: Text(
                      _errorText!,
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                const SizedBox(height: 10),

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _showForgotPasswordDialog,
                    child: const Text(
                      "Forgot Password?",
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // LOGIN BUTTON
                SizedBox(
                  height: 50,
                  width: width * 0.9,
                  child: ElevatedButton(
                    onPressed: _loading ? null : login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF5C5FFF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: _loading
                        ? const CircularProgressIndicator(
                            color: Color(0xFF5C5FFF),
                          )
                        : const Text(
                            "Login",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  "or",
                  style: TextStyle(color: Colors.white70),
                ),

                const SizedBox(height: 20),

                SizedBox(
                  height: 50,
                  width: width * 0.9,
                  child: OutlinedButton(
                    onPressed: widget.showSignUpPage,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text(
                      "Create an account",
                      style: TextStyle(
                        fontSize: 18,
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