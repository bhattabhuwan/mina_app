import 'package:flutter/material.dart';
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

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.15),
                  blurRadius: 25,
                  offset: const Offset(0, 8),
                )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const BlinkingLogo(),
                const SizedBox(height: 20),

                Text(
                  'Create Account',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Colors.lightBlue.shade700,
                  ),
                ),
                const SizedBox(height: 25),

                // Username
                MyTextfield(
                  controller: usernameController,
                  hintText: "Username",
                  obscuretext: false,
                ),
                const SizedBox(height: 16),

                // Email
                MyTextfield(
                  controller: emailController,
                  hintText: "Email",
                  obscuretext: false,
                ),
                const SizedBox(height: 16),

                // Phone Number
                MyTextfield(
                  controller: phoneController,
                  hintText: "Phone Number",
                  obscuretext: false,
                ),
                const SizedBox(height: 16),

                // Password with show/hide
                PasswordTextField(
                  controller: passwordController,
                  hintText: "Password",
                ),
                const SizedBox(height: 16),

                // Confirm Password with show/hide
                ConfirmPasswordTextField(
                  controller: confirmPassController,
                  hintText: "Confirm Password",
                ),

                const SizedBox(height: 20),

                SizedBox(
                  height: 50,
                  width: width * 0.8,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.lightBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 3,
                    ),
                    child: const Text(
                      "Sign Up",
                      style: TextStyle(
                        fontSize: 17,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.grey.shade300)),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text("OR", style: TextStyle(color: Colors.grey)),
                    ),
                    Expanded(child: Divider(color: Colors.grey.shade300)),
                  ],
                ),
                const SizedBox(height: 25),

                GestureDetector(
                  onTap: () {},
                  child: Container(
                    height: 50,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.lightBlue.shade300,
                          Colors.lightBlue.shade600
                        ],
                      ),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.2),
                          blurRadius: 12,
                          offset: const Offset(0, 5),
                        )
                      ],
                    ),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset('lib/images/google.png',
                              height: 24, width: 24),
                          const SizedBox(width: 12),
                          const Text(
                            'Continue with Google',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account?',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    const SizedBox(width: 5),
                    GestureDetector(
                      onTap: widget.showSignInPage,
                      child: const Text(
                        'Sign In',
                        style: TextStyle(
                          color: Color.fromARGB(255, 2, 179, 8),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --------------------
// PASSWORD TEXTFIELD
// --------------------
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
      decoration: InputDecoration(
        hintText: widget.hintText,
        filled: true,
        fillColor: Colors.blue.shade50,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        suffixIcon: IconButton(
          icon: Icon(
            _isObscure ? Icons.visibility_off : Icons.visibility,
            color: Colors.lightBlue.shade600,
          ),
          onPressed: () {
            setState(() {
              _isObscure = !_isObscure;
            });
          },
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: Colors.lightBlue.shade200, width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: Colors.lightBlue.shade200, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: Colors.lightBlue.shade600, width: 1.8),
        ),
      ),
    );
  }
}

// -----------------------------
// CONFIRM PASSWORD TEXTFIELD
// -----------------------------
class ConfirmPasswordTextField extends StatefulWidget {
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

class _ConfirmPasswordTextFieldState extends State<ConfirmPasswordTextField> {
  bool _isObscure = true;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      obscureText: _isObscure,
      decoration: InputDecoration(
        hintText: widget.hintText,
        filled: true,
        fillColor: Colors.blue.shade50,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        suffixIcon: IconButton(
          icon: Icon(
            _isObscure ? Icons.visibility_off : Icons.visibility,
            color: Colors.lightBlue.shade600,
          ),
          onPressed: () {
            setState(() {
              _isObscure = !_isObscure;
            });
          },
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: Colors.lightBlue.shade200, width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: Colors.lightBlue.shade200, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: Colors.lightBlue.shade600, width: 1.8),
        ),
      ),
    );
  }
}
