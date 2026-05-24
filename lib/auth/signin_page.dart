import 'package:flutter/material.dart';
import 'package:mina_app/auth/ApiService.dart';
import 'package:mina_app/screen/home_page.dart';

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
      builder: (context) => ForgotPasswordDialog(),
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

// --------------------
// Password TextField
// --------------------
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
          onPressed: () {
            setState(() {
              _isObscure = !_isObscure;
            });
          },
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
      ),
    );
  }
}

// --------------------
// Normal TextField
// --------------------
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

// Forgot Password Dialog
class ForgotPasswordDialog extends StatefulWidget {
  const ForgotPasswordDialog({super.key});

  @override
  State<ForgotPasswordDialog> createState() => _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends State<ForgotPasswordDialog> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _sendResetLink() async {
    if (_emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter your email")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final api = ApiService();
      await api.forgotPassword(
        email: _emailController.text.trim(),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Password reset link sent to your email"),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Forgot Password"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("Enter your email to reset your password"),
          const SizedBox(height: 16),
          TextField(
            controller: _emailController,
            decoration: InputDecoration(
              hintText: "Enter your email",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            keyboardType: TextInputType.emailAddress,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _sendResetLink,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text("Send"),
        ),
      ],
    );
  }
}

// import 'package:flutter/material.dart';
// import 'signup_page.dart';
// import 'package:mina_app/screen/home_page.dart';
// import 'package:mina_app/auth/ApiService.dart';

// class SignInUI extends StatefulWidget {
//   final VoidCallback showSignUpPage;

//   const SignInUI({super.key, required this.showSignUpPage});

//   @override
//   State<SignInUI> createState() => _SignInUIState();
// }

// class _SignInUIState extends State<SignInUI> {
//   final TextEditingController _usernameController = TextEditingController();
//   final TextEditingController _passwordController = TextEditingController();
//   bool _loading = false;

//   void login() async {
//     setState(() {
//       _loading = true;
//     });

//     try {
//       final api = ApiService();
//       final result = await api.loginUser(
//         username: _usernameController.text.trim(),
//         password: _passwordController.text.trim(),
//       );

//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Login successful!")),
//       );

//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(builder: (context) => HomePage()),
//       );
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("Login failed: $e")),
//       );
//     } finally {
//       setState(() {
//         _loading = false;
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final width = MediaQuery.of(context).size.width;

//     return Scaffold(
//       backgroundColor: const Color(0xFF5D5FEF), // Purple/blue background
//       body: Center(
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
//           child: Column(
//             children: [
//               // Robot logo inside bubble
//               const RobotBubble(),
//               const SizedBox(height: 20),
//               // App Name
//               const Text(
//                 "MINA",
//                 style: TextStyle(
//                   fontSize: 36,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.white,
//                 ),
//               ),
//               const SizedBox(height: 6),
//               const Text(
//                 "Health App",
//                 style: TextStyle(
//                   fontSize: 18,
//                   color: Colors.white70,
//                 ),
//               ),
//               const SizedBox(height: 40),
//               // Email/Phone
//               MyTextfield(
//                 controller: _usernameController,
//                 hintText: "Email or Phone",
//                 prefixIcon: Icons.person_outline,
//               ),
//               const SizedBox(height: 20),
//               // Password
//               PasswordTextField(
//                 controller: _passwordController,
//                 hintText: "Password",
//               ),
//               const SizedBox(height: 12),
//               Align(
//                 alignment: Alignment.centerRight,
//                 child: TextButton(
//                   onPressed: () {},
//                   child: const Text(
//                     "Forgot Password?",
//                     style: TextStyle(color: Colors.white70),
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 20),
//               // Login button
//               SizedBox(
//                 width: width * 0.8,
//                 height: 50,
//                 child: ElevatedButton(
//                   onPressed: _loading ? null : login,
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.white,
//                     shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(30)),
//                   ),
//                   child: _loading
//                       ? const CircularProgressIndicator()
//                       : const Text(
//                           "Login",
//                           style: TextStyle(
//                             fontSize: 18,
//                             fontWeight: FontWeight.bold,
//                             color: Color(0xFF5D5FEF),
//                           ),
//                         ),
//                 ),
//               ),
//               const SizedBox(height: 20),
//               // Create account
//               SizedBox(
//                 width: width * 0.8,
//                 height: 50,
//                 child: OutlinedButton(
//                   onPressed: widget.showSignUpPage,
//                   style: OutlinedButton.styleFrom(
//                     backgroundColor: Colors.white24,
//                     side: const BorderSide(color: Colors.white),
//                     shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(30)),
//                   ),
//                   child: const Text(
//                     "Create an account",
//                     style: TextStyle(
//                       fontSize: 18,
//                       color: Colors.white,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// // Robot logo inside a bubble
// class RobotBubble extends StatelessWidget {
//   const RobotBubble({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       width: 150,
//       height: 150,
//       decoration: BoxDecoration(
//         shape: BoxShape.circle,
//         color: Colors.white24, // Bubble background
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black26,
//             blurRadius: 10,
//             offset: Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Center(
//         child: Image.asset(
//           'lib/images/logo.png', // Your robot image
//           height: 100,
//         ),
//       ),
//     );
//   }
// }

// // Updated MyTextfield with prefix icon
// class MyTextfield extends StatelessWidget {
//   final TextEditingController controller;
//   final String hintText;
//   final IconData? prefixIcon;
//   final bool obscuretext;

//   const MyTextfield({
//     super.key,
//     required this.controller,
//     required this.hintText,
//     this.prefixIcon,
//     this.obscuretext = false,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return TextField(
//       controller: controller,
//       obscureText: obscuretext,
//       style: const TextStyle(color: Colors.white),
//       decoration: InputDecoration(
//         hintText: hintText,
//         hintStyle: const TextStyle(color: Colors.white70),
//         filled: true,
//         fillColor: Colors.white24,
//         prefixIcon:
//             prefixIcon != null ? Icon(prefixIcon, color: Colors.white70) : null,
//         contentPadding:
//             const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
//         border: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(30),
//           borderSide: BorderSide.none,
//         ),
//       ),
//     );
//   }
// }

// // Password field remains similar
// class PasswordTextField extends StatefulWidget {
//   final TextEditingController controller;
//   final String hintText;

//   const PasswordTextField({
//     super.key,
//     required this.controller,
//     required this.hintText,
//   });

//   @override
//   State<PasswordTextField> createState() => _PasswordTextFieldState();
// }

// class _PasswordTextFieldState extends State<PasswordTextField> {
//   bool _isObscure = true;

//   @override
//   Widget build(BuildContext context) {
//     return TextField(
//       controller: widget.controller,
//       obscureText: _isObscure,
//       style: const TextStyle(color: Colors.white),
//       decoration: InputDecoration(
//         hintText: widget.hintText,
//         hintStyle: const TextStyle(color: Colors.white70),
//         filled: true,
//         fillColor: Colors.white24,
//         prefixIcon: const Icon(Icons.lock_outline, color: Colors.white70),
//         suffixIcon: IconButton(
//           icon: Icon(
//             _isObscure ? Icons.visibility_off : Icons.visibility,
//             color: Colors.white70,
//           ),
//           onPressed: () {
//             setState(() {
//               _isObscure = !_isObscure;
//             });
//           },
//         ),
//         contentPadding:
//             const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
//         border: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(30),
//           borderSide: BorderSide.none,
//         ),
//       ),
//     );
//   }
// }
//