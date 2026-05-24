import 'package:flutter/material.dart';
import 'package:mina_app/auth/ApiService.dart';
import 'package:mina_app/auth/Forgot_pass.dart';
import 'package:mina_app/auth/signup_page.dart';
import 'package:mina_app/provider/user_provider.dart'; // add this
import 'package:mina_app/screen/home_page.dart';
import 'package:provider/provider.dart'; // add this

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

  void login() async {
    setState(() {
      _loading = true;
    });

    try {
      final api = ApiService();
      await api.loginUser(
        username: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Fetch user data from API after successful login
      final userData = await api.getCurrentUser();

      // Save user data to SharedPreferences and update provider
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await userProvider.updateUser(
        fullName: userData['full_name'] ?? 'User',
        email: userData['email'] ?? '',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Login successful!")),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Login failed: $e")),
      );
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

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
      backgroundColor: const Color(0xFF5C5FFF), // Blue background
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Robot illustration
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
                const SizedBox(height: 40),

                // Email/Phone field
                MyTextfield(
                  controller: _emailController,
                  hintText: "Email or Phone",
                  obscuretext: false,
                ),
                const SizedBox(height: 16),

                // Password field
                PasswordTextField(controller: _passwordController, hintText: "Password"),
                const SizedBox(height: 20),

                // Forgot Password
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

                // Login Button
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
                        ? const CircularProgressIndicator(color: Color(0xFF5C5FFF))
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

                // OR separator
                const Text(
                  "or",
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 20),

                // Create account button
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

// PasswordTextField, MyTextfield, ForgotPasswordDialog remain unchanged...